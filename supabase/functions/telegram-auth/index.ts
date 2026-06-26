/**
 * Supabase Edge Function: telegram-auth
 *
 * Verifies Telegram Mini App initData and returns Supabase credentials.
 *
 * Flow:
 * 1. Receives initData from Telegram.WebApp (query string with hash)
 * 2. Verifies HMAC-SHA256 hash using the bot token
 * 3. Finds or creates a Supabase user (linked by telegram_id)
 * 4. Returns { email, password } for the Flutter app to sign in
 *
 * Environment variables (set via `supabase secrets set`):
 *   TELEGRAM_BOT_TOKEN  – your bot token from @BotFather
 *   PASSWORD_SALT       – (optional) salt for deriving user passwords
 *
 * Deploy: supabase functions deploy telegram-auth --no-verify-jwt
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ---------------------------------------------------------------------------
// CORS
// ---------------------------------------------------------------------------
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Derive a deterministic password from a Telegram user ID. */
async function derivePassword(telegramId: number): Promise<string> {
  const salt = Deno.env.get("PASSWORD_SALT") ?? "sumsprint-telegram-2024";
  const encoder = new TextEncoder();
  const data = encoder.encode(`${telegramId}:${salt}:sumsprint`);
  const hash = await crypto.subtle.digest("SHA-256", data);
  const bytes = new Uint8Array(hash);
  return btoa(String.fromCharCode(...bytes)).substring(0, 24);
}

/**
 * Verify Telegram initData HMAC-SHA256 signature.
 */
async function verifyTelegramHash(
  initData: string,
  botToken: string,
): Promise<URLSearchParams | null> {
  const params = new URLSearchParams(initData);
  const receivedHash = params.get("hash");
  if (!receivedHash) return null;
  params.delete("hash");

  // Build data-check-string: keys sorted alphabetically, joined by \n
  const entries = Array.from(params.entries());
  entries.sort(([a], [b]) => a.localeCompare(b));
  const dataCheckString = entries.map(([k, v]) => `${k}=${v}`).join("\n");

  // Secret key = SHA-256 of bot token
  const encoder = new TextEncoder();
  const secretKeyBuffer = await crypto.subtle.digest(
    "SHA-256",
    encoder.encode(botToken),
  );

  // Import as HMAC key
  const key = await crypto.subtle.importKey(
    "raw",
    secretKeyBuffer,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  // Compute HMAC
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(dataCheckString),
  );
  const computedHash = Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return computedHash === receivedHash ? params : null;
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------
serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { initData } = await req.json();

    if (!initData || typeof initData !== "string") {
      return new Response(
        JSON.stringify({ error: "Missing or invalid initData" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 1. Verify hash
    const botToken = Deno.env.get("TELEGRAM_BOT_TOKEN");
    if (!botToken) {
      return new Response(
        JSON.stringify({ error: "Server misconfigured: TELEGRAM_BOT_TOKEN not set" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const params = await verifyTelegramHash(initData, botToken);
    if (!params) {
      return new Response(
        JSON.stringify({ error: "Invalid Telegram signature" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 2. Extract user info
    const userStr = params.get("user");
    if (!userStr) {
      return new Response(
        JSON.stringify({ error: "No user data in initData" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const user = JSON.parse(userStr);
    const telegramId: number = user.id;
    const firstName: string = user.first_name ?? "";
    const lastName: string = user.last_name ?? "";
    const username: string = user.username ?? "";
    const displayName: string = firstName || username || `Player`;

    // 3. Derive credentials
    const password = await derivePassword(telegramId);
    const email = `tg_${telegramId}@sumsprint.internal`;

    // 4. Create or update Supabase user
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Try to sign in (existing user) — if it works we're done
    const { data: signInData } = await supabaseAdmin.auth.signInWithPassword({
      email,
      password,
    });

    let userId: string;

    if (signInData?.user) {
      userId = signInData.user.id;
    } else {
      // Create new user
      const { data: newUser, error: createError } = await supabaseAdmin.auth.admin
        .createUser({
          email,
          password,
          email_confirm: true,
          user_metadata: {
            telegram_id: telegramId,
            first_name: firstName,
            last_name: lastName,
            username: username,
            nickname: displayName,
          },
        });

      if (createError || !newUser?.user) {
        console.error("Failed to create user:", createError);
        return new Response(
          JSON.stringify({ error: "Failed to create account" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      userId = newUser.user.id;

      // Ensure profiles row has telegram_id and username (trigger might not set them)
      const { error: upsertError } = await supabaseAdmin
        .from("profiles")
        .upsert({
          id: userId,
          nickname: displayName,
          telegram_id: telegramId,
          telegram_username: username || null,
          points: 500,
        }, { onConflict: "id" });

      if (upsertError) {
        console.error("Failed to upsert profile:", upsertError);
      }
    }

    // 5. Update profile telegram_id and username on every login
    const { error: updateError } = await supabaseAdmin
      .from("profiles")
      .update({
        telegram_id: telegramId,
        telegram_username: username || null,
      })
      .eq("id", userId);

    if (updateError) {
      console.error("Failed to update profile telegram_id:", updateError);
    }

    // 6. Return credentials to Flutter app
    return new Response(
      JSON.stringify({
        email,
        password,
        nickname: displayName,
        user_id: userId,
        telegram_id: telegramId,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});

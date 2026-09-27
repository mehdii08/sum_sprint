/**
 * Supabase Edge Function: telegram-auth
 *
 * Verifies Telegram Mini App initData and returns Supabase credentials.
 *
 * Deploy: supabase functions deploy telegram-auth --no-verify-jwt
 */

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

async function derivePassword(telegramId: number): Promise<string> {
  const salt = Deno.env.get("PASSWORD_SALT") ?? "sumsprint-telegram-2024";
  const encoder = new TextEncoder();
  const data = encoder.encode(`${telegramId}:${salt}:sumsprint`);
  const hash = await crypto.subtle.digest("SHA-256", data);
  const bytes = new Uint8Array(hash);
  return btoa(String.fromCharCode(...bytes)).substring(0, 24);
}

async function verifyTelegramHash(
  initData: string,
  botToken: string,
): Promise<URLSearchParams | null> {
  const params = new URLSearchParams(initData);
  const receivedHash = params.get("hash");
  if (!receivedHash) return null;
  params.delete("hash");

  const dataCheckString = [...params.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([key, value]) => `${key}=${value}`)
    .join("\n");

  const encoder = new TextEncoder();

  const webAppDataKey = await crypto.subtle.importKey(
    "raw",
    encoder.encode("WebAppData"),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const secretKey = await crypto.subtle.sign(
    "HMAC",
    webAppDataKey,
    encoder.encode(botToken),
  );

  const secretKeyImport = await crypto.subtle.importKey(
    "raw",
    secretKey,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "HMAC",
    secretKeyImport,
    encoder.encode(dataCheckString),
  );

  const computedHash = Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return computedHash === receivedHash ? params : null;
}

serve(async (req: Request) => {
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

    const password = await derivePassword(telegramId);
    const email = `tg_${telegramId}@sumsprint.internal`;

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: signInData } = await supabaseAdmin.auth.signInWithPassword({
      email,
      password,
    });

    let userId: string;

    if (signInData?.user) {
      userId = signInData.user.id;
    } else {
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

      const { error: upsertError } = await supabaseAdmin
        .from("profiles")
        .upsert({
          id: userId,
          nickname: displayName,
          telegram_id: telegramId,
          telegram_username: username || null,
          coins: 500,
        }, { onConflict: "id" });

      if (upsertError) {
        console.error("Failed to upsert profile:", upsertError);
      }
    }

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

/**
 * Dev-only: confirm a signup when the user enters code 123456.
 *
 * Disable for production by setting ENABLE_DEV_OTP=false
 * (Supabase Dashboard → Edge Functions → Secrets).
 *
 * Deploy: supabase functions deploy dev-confirm-signup --no-verify-jwt
 */
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-dev-otp-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const DEV_CODE = "123456";
const DEV_SECRET = "sum-sprint-dev-otp";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (Deno.env.get("ENABLE_DEV_OTP") === "false") {
      return new Response(JSON.stringify({ error: "Dev OTP disabled" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const secret = req.headers.get("x-dev-otp-secret");
    if (secret !== DEV_SECRET) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { email, code } = await req.json();
    if (!email || typeof email !== "string") {
      return new Response(JSON.stringify({ error: "email required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (String(code).trim() !== DEV_CODE) {
      return new Response(JSON.stringify({ error: "Invalid code" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: list, error: listError } = await supabaseAdmin.auth.admin
      .listUsers({ page: 1, perPage: 1000 });
    if (listError) {
      console.error(listError);
      return new Response(JSON.stringify({ error: "Lookup failed" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const user = list.users.find(
      (u) => (u.email ?? "").toLowerCase() === email.trim().toLowerCase(),
    );
    if (!user) {
      return new Response(JSON.stringify({ error: "User not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
      user.id,
      { email_confirm: true },
    );
    if (updateError) {
      console.error(updateError);
      return new Response(JSON.stringify({ error: "Confirm failed" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true, user_id: user.id }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

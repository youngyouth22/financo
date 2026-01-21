// Supabase Edge Function: plaid-create-link-token
// Purpose: Generate a Link Token for the frontend and register the webhook URL

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// ============================================================================
// CONFIGURATION
// ============================================================================
const PLAID_CLIENT_ID = Deno.env.get("PLAID_CLIENT_ID");
const PLAID_SECRET = Deno.env.get("PLAID_SECRET");
const PLAID_ENV = Deno.env.get("PLAID_ENV") || "sandbox";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  // Handle CORS
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { userId } = await req.json();

    if (!userId) {
      throw new Error("userId is required to create a link token");
    }

    // 1. PREPARE PLAID REQUEST
    const plaidUrl = `https://${PLAID_ENV}.plaid.com/link/token/create`;
    
    // This is where you link the two functions together
    const webhookUrl = `${SUPABASE_URL}/functions/v1/plaid-manager`;

    const body = {
      client_id: PLAID_CLIENT_ID,
      secret: PLAID_SECRET,
      client_name: "Financo App",
      user: { client_user_id: userId },
      // Products needed for an accurate Net Worth
      products: ["auth", "transactions", "liabilities"], 
      country_codes: ["US", "FR", "CA"],
      language: "fr",
      webhook: webhookUrl, // <--- CRITICAL: Telling Plaid where to send signals
      android_package_name: "com.yourdomain.financo", // Required for Android
    };

    // 2. CALL PLAID API
    const response = await fetch(plaidUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(`Plaid Link Token Error: ${data.error_message}`);
    }

    // 3. RETURN LINK TOKEN TO FLUTTER
    return new Response(JSON.stringify({ link_token: data.link_token }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("Link Token Error:", err.message);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
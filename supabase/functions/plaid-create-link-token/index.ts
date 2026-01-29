// Supabase Edge Function: plaid-create-link-token
// Purpose: Generate a Link Token for the Flutter app and register the webhook
// Features: Dynamic environment routing, automatic user email retrieval,
//           and Net Worth product configuration (Liabilities/Investments).
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ============================================================================
// CONFIGURATION & SECRETS
// ============================================================================

const PLAID_CLIENT_ID = Deno.env.get("PLAID_CLIENT_ID");
const PLAID_SECRET = Deno.env.get("PLAID_SECRET");
const PLAID_ENV = Deno.env.get("PLAID_ENV") || "sandbox";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// Base URL configuration based on environment
const PLAID_BASE_URL = `https://${PLAID_ENV}.plaid.com`;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface RequestPayload {
  userId: string;
}

// ============================================================================
// HELPERS
// ============================================================================

/**
 * Fetch the user's email from Supabase Auth using the Service Role key
 */
async function getUserEmail(supabase: any, userId: string): Promise<string> {
  try {
    const { data, error } = await supabase.auth.admin.getUserById(userId);
    if (error || !data.user) {
      return `${userId}@financo.app`;
    }
    return data.user.email || `${userId}@financo.app`;
  } catch {
    return `${userId}@financo.app`;
  }
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req: Request) => {
  // Handle CORS Preflight
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  try {
    const { userId } = (await req.json()) as RequestPayload;

    if (!userId) {
      throw new Error("userId is required to create a link token");
    }

    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
    const userEmail = await getUserEmail(supabase, userId);

    // 1. PREPARE WEBHOOK URL
    // This points Plaid to our unified plaid-manager function
    const webhookUrl = `${SUPABASE_URL}/functions/v1/plaid-manager`;

    // 2. CONSTRUCT PLAID REQUEST BODY
    // NOTE: Removed ios_bundle_id from root as it is not a valid top-level field.
    // iOS redirection is handled via 'Redirect URIs' in the Plaid Dashboard.
    const body = {
      client_id: PLAID_CLIENT_ID,
      secret: PLAID_SECRET,
      client_name: "Financo - Portfolio Tracker",
      user: {
        client_user_id: userId,
        email_address: userEmail,
      },
      // Core products for a complete financial overview (Net Worth)
      products: ["auth", "transactions", "liabilities", "investments"],
      country_codes: ["US", "FR", "CA", "GB"],
      language: "en",
      webhook: webhookUrl,
      // Required for Android intent-based redirection
      android_package_name: "com.example.financo",

      // Filter accounts to show only relevant ones for wealth tracking
      account_filters: {
        depository: { account_subtypes: ["checking", "savings"] },
        credit: { account_subtypes: ["credit card"] },
        loan: { account_subtypes: ["student", "mortgage"] },
        investment: { account_subtypes: ["brokerage", "ira", "401k"] },
      },
    };

    // 3. CALL PLAID API
    const response = await fetch(`${PLAID_BASE_URL}/link/token/create`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("Plaid API Error Response:", data);
      throw new Error(data.error_message || "Failed to create Link Token");
    }

    // 4. RETURN LINK TOKEN TO FRONTEND
    return new Response(
      JSON.stringify({
        link_token: data.link_token,
        expiration: data.expiration,
        request_id: data.request_id,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    console.error("Link Token Edge Function Error:", err.message);

    return new Response(
      JSON.stringify({
        error: "Internal Error",
        message: err.message,
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

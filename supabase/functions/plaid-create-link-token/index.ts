// Supabase Edge Function: plaid-create-link-token
// Purpose: Generate a Link Token for the frontend and register the webhook URL

// plaid-create-link-token.ts - UPDATED FOR UNIFIED ARCHITECTURE
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ============================================================================
// CONFIGURATION
// ============================================================================
const PLAID_CLIENT_ID = Deno.env.get("PLAID_CLIENT_ID");
const PLAID_SECRET = Deno.env.get("PLAID_SECRET");
const PLAID_ENV = Deno.env.get("PLAID_ENV") || "sandbox";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

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

    // Initialize Supabase client
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    // Check if user already has Plaid items
    const { data: existingItems, error: fetchError } = await supabase
      .from("plaid_items")
      .select("item_id, institution_name")
      .eq("user_id", userId);

    if (fetchError) {
      console.warn("Failed to fetch existing Plaid items:", fetchError);
    }

    const existingItemIds = existingItems?.map(item => item.item_id) || [];

    // 1. PREPARE PLAID REQUEST
    const plaidUrl = `https://${PLAID_ENV}.plaid.com/link/token/create`;
    
    // Webhook URL for the plaid-manager function
    const webhookUrl = `${SUPABASE_URL}/functions/v1/plaid-manager`;

    const body = {
      client_id: PLAID_CLIENT_ID,
      secret: PLAID_SECRET,
      client_name: "Financo - Portfolio Tracker",
      user: { 
        client_user_id: userId,
        email_address: await getUserEmail(supabase, userId),
      },
      // Products for comprehensive net worth tracking
      products: ["auth", "transactions", "liabilities", "investments"],
      country_codes: ["US", "FR", "CA", "GB", "DE", "ES", "IT"],
      language: "en",
      webhook: webhookUrl,
      android_package_name: "com.yourdomain.financo",
      ios_bundle_id: "com.yourdomain.financo",
      
      // Additional options for better UX
      account_filters: {
        depository: {
          account_subtypes: ["checking", "savings", "cd", "money market"]
        },
        credit: {
          account_subtypes: ["credit card"]
        },
        loan: {
          account_subtypes: ["student", "mortgage", "auto"]
        },
        investment: {
          account_subtypes: ["ira", "401k", "brokerage"]
        }
      },
      
      // Link customization
      link_customization_name: "account_selection",
      
      // Pass existing item IDs for update mode
      access_token: existingItemIds.length > 0 ? undefined : undefined,
      update: existingItemIds.length > 0 ? {
        account_selection_enabled: true
      } : undefined,
    };

    // 2. CALL PLAID API
    const response = await fetch(plaidUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("Plaid Link Token Error:", data);
      throw new Error(`Plaid Link Token Error: ${data.error_message || data.error_code}`);
    }

    // 3. RETURN LINK TOKEN TO FLUTTER
    return new Response(
      JSON.stringify({ 
        link_token: data.link_token,
        expiration: data.expiration,
        existing_items: existingItems || [],
        request_id: data.request_id
      }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (err) {
    console.error("Link Token Error:", err);
    
    return new Response(
      JSON.stringify({ 
        error: "Failed to create link token", 
        message: err.message,
        details: err.stack 
      }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

/**
 * Get user email for Plaid user object
 */
async function getUserEmail(supabase: any, userId: string): Promise<string> {
  try {
    const { data, error } = await supabase
      .auth.admin.getUserById(userId);
    
    if (error || !data.user) {
      console.warn("Failed to fetch user email:", error);
      return `${userId}@financo.app`;
    }
    
    return data.user.email || `${userId}@financo.app`;
  } catch (error) {
    console.warn("Error getting user email:", error);
    return `${userId}@financo.app`;
  }
}
// Supabase Edge Function: plaid-manager
// Purpose: Token Exchange, Encryption, Manual Sync, and Automated Webhooks
// Environment: Sandbox & Production compatible

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ============================================================================
// CONFIGURATION
// ============================================================================
const PLAID_CLIENT_ID = Deno.env.get("PLAID_CLIENT_ID");
const PLAID_SECRET = Deno.env.get("PLAID_SECRET");
const PLAID_ENV = Deno.env.get("PLAID_ENV") || "sandbox"; // Set to 'production' in secrets for live
const ENCRYPTION_KEY = Deno.env.get("ENCRYPTION_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const encoder = new TextEncoder();
const decoder = new TextDecoder();

// ============================================================================
// CRYPTO HELPERS
// ============================================================================
async function encryptToken(plainText: string) {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(ENCRYPTION_KEY),
    "AES-GCM",
    false,
    ["encrypt"],
  );
  const encrypted = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv },
    key,
    encoder.encode(plainText),
  );
  return {
    encryptedToken: btoa(String.fromCharCode(...new Uint8Array(encrypted))),
    iv: btoa(String.fromCharCode(...iv)),
  };
}

async function decryptToken(encryptedToken: string, iv: string) {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(ENCRYPTION_KEY),
    "AES-GCM",
    false,
    ["decrypt"],
  );
  const decrypted = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: Uint8Array.from(atob(iv), (c) => c.charCodeAt(0)) },
    key,
    Uint8Array.from(atob(encryptedToken), (c) => c.charCodeAt(0)),
  );
  return decoder.decode(decrypted);
}

// ============================================================================
// MAPPING & SYNC LOGIC
// ============================================================================
function mapPlaidTypeToSupabase(type: string, subtype: string | null): string {
  switch (type) {
    case "depository":
      return "cash";
    case "investment":
      return subtype === "ira" || subtype === "401k" ? "retirement" : "stock";
    case "credit":
      return "credit";
    case "loan":
      return subtype === "mortgage" ? "mortgage" : "loan";
    default:
      return "custom";
  }
}

async function syncPlaidData(
  supabase: any,
  userId: string,
  accessToken: string,
) {
  const response = await fetch(
    `https://${PLAID_ENV}.plaid.com/accounts/balance/get`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client_id: PLAID_CLIENT_ID,
        secret: PLAID_SECRET,
        access_token: accessToken,
      }),
    },
  );

  const data = await response.json();
  if (!response.ok) throw new Error(`Plaid Error: ${data.error_message}`);

  const updates = data.accounts.map(async (acc: any) => {
    const assetType = mapPlaidTypeToSupabase(acc.type, acc.subtype);
    let balance = acc.balances.current || 0;

    // DEBT HANDLING: Store as negative values
    if (
      assetType === "credit" ||
      assetType === "loan" ||
      assetType === "mortgage"
    ) {
      balance = -Math.abs(balance);
    }

    return supabase.from("assets").upsert(
      {
        user_id: userId,
        asset_address_or_id: acc.account_id,
        provider: "plaid",
        type: assetType,
        name: acc.name,
        balance_usd: balance,
        last_sync: new Date().toISOString(),
      },
      { onConflict: "asset_address_or_id" },
    );
  });

  await Promise.all(updates);
  await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
}

// ============================================================================
// MAIN HANDLER
// ============================================================================
serve(async (req) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  try {
    const body = await req.json();
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    // 1. WEBHOOK DETECTION (From Plaid)
    if (body.webhook_code) {
      const itemId = body.item_id;
      console.log(`Webhook Received: ${body.webhook_code} for item: ${itemId}`);

      // We only sync for balance or transaction updates
      if (
        ["DEFAULT_UPDATE", "SYNC_UPDATES_AVAILABLE", "INITIAL_UPDATE"].includes(
          body.webhook_code,
        )
      ) {
        const { data: conn } = await supabase
          .from("bank_connections")
          .select("access_token, iv, user_id")
          .eq("item_id", itemId)
          .single();
        if (conn) {
          const token = await decryptToken(conn.access_token, conn.iv);
          await syncPlaidData(supabase, conn.user_id, token);
        }
      }
      return new Response(JSON.stringify({ webhook_received: true }), {
        status: 200,
      });
    }

    // 2. MANUAL ACTIONS (From App)
    const { action, public_token, metadata, userId, item_id } = body;

    if (action === "exchange") {
      const exRes = await fetch(
        `https://${PLAID_ENV}.plaid.com/item/public_token/exchange`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            client_id: PLAID_CLIENT_ID,
            secret: PLAID_SECRET,
            public_token,
          }),
        },
      );
      const exData = await exRes.json();
      if (!exRes.ok) throw new Error("Exchange Failed");

      const { access_token, item_id: plaidItemId } = exData;
      const { encryptedToken, iv } = await encryptToken(access_token);

      await supabase.from("bank_connections").upsert(
        {
          user_id: userId,
          item_id: plaidItemId,
          access_token: encryptedToken,
          iv: iv,
          institution_name: metadata?.institution?.name || "Bank",
        },
        { onConflict: "item_id" },
      );

      await syncPlaidData(supabase, userId, access_token);
      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action === "sync" && item_id) {
      const { data: conn } = await supabase
        .from("bank_connections")
        .select("access_token, iv, user_id")
        .eq("item_id", item_id)
        .single();
      if (!conn) throw new Error("Connection not found");
      const token = await decryptToken(conn.access_token, conn.iv);
      await syncPlaidData(supabase, conn.user_id, token);
      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    throw new Error("Invalid request");
  } catch (err) {
    console.error("Error:", err.message);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

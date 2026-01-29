// plaid-manager.ts - COMPLETE PLAID INTEGRATION FOR BANKING ASSETS
// Purpose: Token Exchange, Encryption, and Account Synchronization
// Features: AES-GCM Encryption, Debt/Liability sign handling, and Robust Error Handling
// Author: Finance Realtime Engine

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
const ENCRYPTION_KEY = Deno.env.get("ENCRYPTION_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const PLAID_BASE_URL = `https://${PLAID_ENV}.plaid.com`;

// ============================================================================
// TYPES
// ============================================================================

interface PlaidAccount {
  account_id: string;
  name: string;
  official_name?: string;
  type: string;
  subtype?: string;
  balances: {
    available: number | null;
    current: number;
    limit: number | null;
    iso_currency_code: string;
    unofficial_currency_code: string | null;
  };
  mask?: string;
  verification_status?: string;
}

interface RequestPayload {
  action:
    | "exchange_token"
    | "sync_accounts"
    | "get_accounts"
    | "remove_item"
    | "webhook";
  public_token?: string;
  userId?: string;
  itemId?: string;
  accountIds?: string[];
  webhook_type?: string; // For Plaid signals
  webhook_code?: string; // For Plaid signals
  item_id?: string; // For Plaid signals
}

// ============================================================================
// ENCRYPTION HELPERS
// ============================================================================

const encoder = new TextEncoder();
const decoder = new TextDecoder();

async function encryptToken(plainText: string) {
  if (!ENCRYPTION_KEY || ENCRYPTION_KEY.length !== 32) {
    throw new Error("ENCRYPTION_KEY must be exactly 32 characters long.");
  }
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encodedKey = encoder.encode(ENCRYPTION_KEY);
  const key = await crypto.subtle.importKey(
    "raw",
    encodedKey,
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
    encrypted_token: btoa(String.fromCharCode(...new Uint8Array(encrypted))),
    iv: btoa(String.fromCharCode(...iv)),
  };
}

async function decryptToken(encryptedToken: string, iv: string) {
  const encodedKey = encoder.encode(ENCRYPTION_KEY);
  const key = await crypto.subtle.importKey(
    "raw",
    encodedKey,
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
// PLAID API HELPERS
// ============================================================================

async function plaidRequest(endpoint: string, body: any) {
  const url = `${PLAID_BASE_URL}${endpoint}`;
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      client_id: PLAID_CLIENT_ID,
      secret: PLAID_SECRET,
      ...body,
    }),
  });

  const data = await response.json();
  if (!response.ok)
    throw new Error(
      `Plaid API Error: ${data.error_message || data.error_code}`,
    );
  return data;
}

/**
 * Process Plaid account for database insertion
 * Logic: Flips debt balances to negative for accurate Net Worth
 */
function processPlaidAccount(
  account: PlaidAccount,
  userId: string,
  itemId: string,
  institutionName: string,
): any {
  let balance = account.balances.current || 0;
  const currency = account.balances.iso_currency_code || "USD";

  // NET WORTH LOGIC: If it's a loan or credit card, the balance must be NEGATIVE
  if (account.type === "credit" || account.type === "loan") {
    balance = -Math.abs(balance);
  }

  // Mapping to your assets_type enum
  let assetType = "cash";
  if (
    account.type === "investment" ||
    account.subtype?.includes("ira") ||
    account.subtype?.includes("401k")
  ) {
    assetType = "investment";
  } else if (account.type === "loan" || account.type === "credit") {
    assetType = "liability";
  }

  const accountName = account.official_name || account.name;
  const displayName = `${institutionName} - ${accountName}${account.mask ? ` (${account.mask})` : ""}`;

  return {
    user_id: userId,
    asset_address_or_id: `plaid:${itemId}:${account.account_id}`,
    provider: "plaid",
    type: assetType,
    symbol: currency,
    name: displayName,
    quantity: 1,
    current_price: balance,
    price_usd: balance,
    balance_usd: balance,
    currency: currency,
    last_sync: new Date().toISOString(),
    status: "active",
  };
}

/**
 * Sync Plaid accounts to assets table
 */
async function syncPlaidAccounts(
  supabase: any,
  userId: string,
  itemId: string,
  accessToken: string,
) {
  try {
    const itemInfo = await plaidRequest("/item/get", {
      access_token: accessToken,
    });
    const institutionName = itemInfo.item.institution_id || "Bank";

    const balanceData = await plaidRequest("/accounts/balance/get", {
      access_token: accessToken,
    });
    const accounts = balanceData.accounts as PlaidAccount[];

    const upsertData = accounts.map((acc) =>
      processPlaidAccount(acc, userId, itemId, institutionName),
    );

    if (upsertData.length > 0) {
      const { error } = await supabase
        .from("assets")
        .upsert(upsertData, { onConflict: "asset_address_or_id, user_id" });
      if (error) throw error;
    }

    await supabase
      .from("plaid_items")
      .update({ last_synced: new Date().toISOString() })
      .eq("item_id", itemId);
    return { synced: upsertData.length };
  } catch (error) {
    console.error("Sync Error:", error);
    throw error;
  }
}

// ============================================================================
// MAIN HANDLER - FIXES "Body already consumed" & 500 error
// ============================================================================

serve(async (req) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  // IMPORTANT: Read body exactly once and store it
  let payload: RequestPayload;
  let action: string = "unknown";

  try {
    const bodyText = await req.text();
    payload = JSON.parse(bodyText);
    action = payload.action || (payload.webhook_code ? "webhook" : "unknown");

    const { public_token, userId, itemId } = payload;
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    switch (action) {
      case "exchange_token": {
        if (!public_token || !userId)
          throw new Error("Missing public_token or userId");

        const exchangeData = await plaidRequest("/item/public_token/exchange", {
          public_token,
        });
        const { access_token, item_id } = exchangeData;

        const { encrypted_token, iv } = await encryptToken(access_token);
        const { error } = await supabase.from("plaid_items").upsert(
          {
            user_id: userId,
            item_id: item_id,
            access_token_encrypted: encrypted_token,
            iv: iv,
            last_synced: new Date().toISOString(),
          },
          { onConflict: "user_id, item_id" },
        );

        if (error) throw error;

        await syncPlaidAccounts(supabase, userId, item_id, access_token);
        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });

        return new Response(JSON.stringify({ success: true, item_id }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "sync_accounts": {
        if (!userId) throw new Error("userId is required");
        const { data: items } = await supabase
          .from("plaid_items")
          .select("*")
          .eq("user_id", userId);

        for (const item of items || []) {
          const token = await decryptToken(
            item.access_token_encrypted,
            item.iv,
          );
          await syncPlaidAccounts(supabase, userId, item.item_id, token);
        }
        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
        return new Response(JSON.stringify({ success: true }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "remove_item": {
        if (!userId || !itemId) throw new Error("Missing itemId or userId");
        await supabase
          .from("assets")
          .delete()
          .like("asset_address_or_id", `plaid:${itemId}:%`)
          .eq("user_id", userId);
        await supabase
          .from("plaid_items")
          .delete()
          .eq("item_id", itemId)
          .eq("user_id", userId);
        return new Response(JSON.stringify({ success: true }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "webhook": {
        const itemId = payload.item_id || payload.itemId;
        if (!itemId) return new Response("OK", { status: 200 });

        const { data: item } = await supabase
          .from("plaid_items")
          .select("*")
          .eq("item_id", itemId)
          .single();
        if (item) {
          const token = await decryptToken(
            item.access_token_encrypted,
            item.iv,
          );
          await syncPlaidAccounts(supabase, item.user_id, item.item_id, token);
          await supabase.rpc("record_wealth_snapshot", {
            p_user_id: item.user_id,
          });
        }
        return new Response(JSON.stringify({ received: true }), {
          status: 200,
        });
      }

      default:
        throw new Error(`Action ${action} not recognized`);
    }
  } catch (error) {
    console.error("Plaid Manager Error:", error.message);
    return new Response(
      JSON.stringify({
        error: "Internal Error",
        message: error.message,
        action: action,
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

// plaid-manager.ts - AGGREGATED BANKING ASSETS (V2)
// Features: AES-GCM Encryption, Investment Type for Flutter Sync, Base64 Logo handling
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const PLAID_CLIENT_ID = Deno.env.get("PLAID_CLIENT_ID");
const PLAID_SECRET = Deno.env.get("PLAID_SECRET");
const PLAID_ENV = Deno.env.get("PLAID_ENV") || "sandbox";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const ENCRYPTION_KEY = Deno.env.get("ENCRYPTION_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const PLAID_BASE_URL = `https://${PLAID_ENV}.plaid.com`;

// --- CRYPTO HELPERS ---
const encoder = new TextEncoder();
async function encryptToken(plainText: string) {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const key = await crypto.subtle.importKey("raw", encoder.encode(ENCRYPTION_KEY), "AES-GCM", false, ["encrypt"]);
  const encrypted = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, key, encoder.encode(plainText));
  return {
    encrypted_token: btoa(String.fromCharCode(...new Uint8Array(encrypted))),
    iv: btoa(String.fromCharCode(...iv)),
  };
}

async function decryptToken(encryptedToken: string, iv: string) {
  const key = await crypto.subtle.importKey("raw", encoder.encode(ENCRYPTION_KEY), "AES-GCM", false, ["decrypt"]);
  const decrypted = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: Uint8Array.from(atob(iv), (c) => c.charCodeAt(0)) },
    key,
    Uint8Array.from(atob(encryptedToken), (c) => c.charCodeAt(0)),
  );
  return new TextDecoder().decode(decrypted);
}

// --- PLAID HELPERS ---
async function plaidRequest(endpoint: string, body: any) {
  const response = await fetch(`${PLAID_BASE_URL}${endpoint}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ client_id: PLAID_CLIENT_ID, secret: PLAID_SECRET, ...body }),
  });
  const data = await response.json();
  if (!response.ok) throw new Error(data.error_message || data.error_code);
  return data;
}

// --- SYNC LOGIC ---
async function syncPlaidBank(supabase: any, userId: string, itemId: string, accessToken: string) {
  // 1. Get Item and Institution details
  const itemData = await plaidRequest("/item/get", { access_token: accessToken });
  const instId = itemData.item.institution_id;
  
  // We request the logo and primary_color specifically
  const instData = await plaidRequest("/institutions/get_by_id", { 
    institution_id: instId, 
    country_codes: ["US", "FR", "CA", "GB"],
    options: { include_optional_metadata: true }
  });
  const institution = instData.institution;

  // 2. Get All Balances
  const balanceData = await plaidRequest("/accounts/balance/get", { access_token: accessToken });
  const accounts = balanceData.accounts;

  // 3. Aggregate Data (Calculate Net Worth)
  let totalNetWorth = 0;
  const subAccounts = accounts.map((acc: any) => {
    const isDebt = acc.type === "credit" || acc.type === "loan";
    const balance = acc.balances.current || 0;
    
    if (isDebt) totalNetWorth -= Math.abs(balance);
    else totalNetWorth += balance;

    return {
      accountId: acc.account_id,
      name: acc.name,
      mask: acc.mask,
      type: acc.type,
      balance: balance,
      isDebt: isDebt
    };
  });

  // 4. Handle Icon (Fixing the Access Denied issue)
  // If Plaid provides a base64 logo, we use it. 
  // Otherwise, we use an identicon as a reliable fallback.
  let iconUrl = `https://api.dicebear.com/7.x/identicon/svg?seed=${instId}&backgroundColor=0f1116`;
  if (institution.logo) {
    // Some Plaid institutions return the logo as a base64 string
    iconUrl = `data:image/png;base64,${institution.logo}`;
  } else if (institution.url) {
    // If no logo, use a favicon service as fallback
    iconUrl = `https://www.google.com/s2/favicons?domain=${institution.url}&sz=128`;
  }

  // 5. Upsert ONE SINGLE ASSET for the whole bank
  const bankAsset = {
    user_id: userId,
    asset_address_or_id: `plaid:${itemId}`,
    provider: "plaid",
    type: "investment", // Matches your 'Fixed' tab in Flutter
    name: institution.name,
    symbol: accounts[0]?.balances.iso_currency_code || "USD",
    icon_url: iconUrl,
    quantity: 1,
    current_price: totalNetWorth,
    price_usd: totalNetWorth,
    balance_usd: totalNetWorth,
    last_sync: new Date().toISOString(),
    status: "active",
    metadata: {
      institution_id: instId,
      primary_color: institution.primary_color,
      account_count: accounts.length,
      accounts: subAccounts 
    }
  };

  const { error } = await supabase.from("assets").upsert(bankAsset, { onConflict: "asset_address_or_id, user_id" });
  if (error) throw error;

  await supabase.from("plaid_items").update({ last_synced: new Date().toISOString() }).eq("item_id", itemId);
  return bankAsset;
}

// --- MAIN HANDLER ---
serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const payload = await req.json();
    const action = payload.action || "unknown";
    const { public_token, userId, itemId } = payload;
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    switch (action) {
      case "exchange_token": {
        const exchange = await plaidRequest("/item/public_token/exchange", { public_token });
        const { access_token, item_id } = exchange;

        const { encrypted_token, iv } = await encryptToken(access_token);
        await supabase.from("plaid_items").upsert({
          user_id: userId,
          item_id: item_id,
          access_token_encrypted: encrypted_token,
          iv: iv,
        }, { onConflict: "user_id, item_id" });

        await syncPlaidBank(supabase, userId, item_id, access_token);
        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });

        return new Response(JSON.stringify({ success: true, item_id }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "sync_accounts": {
        const { data: items } = await supabase.from("plaid_items").select("*").eq("user_id", userId);
        for (const item of items || []) {
          const token = await decryptToken(item.access_token_encrypted, item.iv);
          await syncPlaidBank(supabase, userId, item.item_id, token);
        }
        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
        return new Response(JSON.stringify({ success: true }), { headers: corsHeaders });
      }

      case "remove_item": {
        await supabase.from("assets").delete().eq("asset_address_or_id", `plaid:${itemId}`).eq("user_id", userId);
        await supabase.from("plaid_items").delete().eq("item_id", itemId).eq("user_id", userId);
        return new Response(JSON.stringify({ success: true }), { headers: corsHeaders });
      }

      default:
        throw new Error(`Action ${action} not recognized`);
    }
  } catch (error) {
    return new Response(JSON.stringify({ error: "Internal Error", message: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
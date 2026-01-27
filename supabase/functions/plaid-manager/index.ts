// plaid-manager.ts - COMPLETE PLAID INTEGRATION FOR BANKING ASSETS
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
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
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

interface PlaidItem {
  item_id: string;
  access_token: string;
  institution_id: string;
  institution_name: string;
}

interface RequestPayload {
  action: "exchange_token" | "sync_accounts" | "get_accounts" | "remove_item" | "webhook";
  public_token?: string;
  userId?: string;
  itemId?: string;
  accountIds?: string[];
}

// ============================================================================
// ENCRYPTION HELPERS (From crypto-helper)
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
    "raw", encodedKey, "AES-GCM", false, ["encrypt"]
  );

  const encrypted = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv },
    key,
    encoder.encode(plainText)
  );

  return {
    encrypted_token: btoa(String.fromCharCode(...new Uint8Array(encrypted))),
    iv: btoa(String.fromCharCode(...iv))
  };
}

async function decryptToken(encryptedToken: string, iv: string) {
  if (!ENCRYPTION_KEY || ENCRYPTION_KEY.length !== 32) {
    throw new Error("ENCRYPTION_KEY must be exactly 32 characters long.");
  }

  const encodedKey = encoder.encode(ENCRYPTION_KEY);
  const key = await crypto.subtle.importKey(
    "raw", encodedKey, "AES-GCM", false, ["decrypt"]
  );

  const decrypted = await crypto.subtle.decrypt(
    { 
      name: "AES-GCM", 
      iv: Uint8Array.from(atob(iv), c => c.charCodeAt(0)) 
    },
    key,
    Uint8Array.from(atob(encryptedToken), c => c.charCodeAt(0))
  );

  return decoder.decode(decrypted);
}

// ============================================================================
// PLAID API HELPERS
// ============================================================================

/**
 * Make authenticated requests to Plaid API
 */
async function plaidRequest(endpoint: string, body: any, accessToken?: string) {
  const url = `${PLAID_BASE_URL}${endpoint}`;
  
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  const requestBody: any = {
    client_id: PLAID_CLIENT_ID,
    secret: PLAID_SECRET,
    ...body,
  };

  if (accessToken) {
    requestBody.access_token = accessToken;
  }

  const response = await fetch(url, {
    method: "POST",
    headers,
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorData = await response.json();
    console.error("Plaid API Error:", errorData);
    throw new Error(`Plaid API error: ${errorData.error_message || errorData.error_code}`);
  }

  return response.json();
}

/**
 * Exchange public token for access token
 */
async function exchangePublicToken(publicToken: string): Promise<{
  access_token: string;
  item_id: string;
  request_id: string;
}> {
  return await plaidRequest("/item/public_token/exchange", {
    public_token: publicToken,
  });
}

/**
 * Get item information
 */
async function getItemInfo(accessToken: string) {
  return await plaidRequest("/item/get", {}, accessToken);
}

/**
 * Get accounts for an item
 */
async function getAccounts(accessToken: string, accountIds?: string[]) {
  return await plaidRequest("/accounts/get", {
    options: {
      account_ids: accountIds,
    },
  }, accessToken);
}

/**
 * Get account balances
 */
async function getBalances(accessToken: string, accountIds?: string[]) {
  return await plaidRequest("/accounts/balance/get", {
    options: {
      account_ids: accountIds,
      min_last_updated_datetime: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
    },
  }, accessToken);
}

/**
 * Process Plaid account for database insertion
 */
function processPlaidAccount(
  account: PlaidAccount,
  userId: string,
  itemId: string,
  institutionName: string
): any {
  const balance = account.balances.current || 0;
  const currency = account.balances.iso_currency_code || "USD";
  
  // Map Plaid account types to our types
  let assetType = "cash";
  if (account.type === "investment" || account.subtype?.includes("ira") || account.subtype?.includes("401k")) {
    assetType = "investment";
  } else if (account.type === "loan" || account.type === "credit") {
    assetType = "liability";
  }

  const accountName = account.official_name || account.name;
  const displayName = `${institutionName} - ${accountName}${account.mask ? ` (${account.mask})` : ''}`;

  return {
    user_id: userId,
    asset_address_or_id: `plaid:${itemId}:${account.account_id}`,
    provider: "plaid",
    type: assetType,
    symbol: currency,
    name: displayName,
    quantity: 1, // For bank accounts, quantity represents number of accounts
    current_price: balance,
    price_usd: balance,
    balance_usd: balance,
    currency: currency,
    last_sync: new Date().toISOString(),
    metadata: {
      institution: institutionName,
      account_type: account.type,
      account_subtype: account.subtype,
      mask: account.mask,
      verification_status: account.verification_status,
    },
  };
}

// ============================================================================
// DATABASE HELPERS
// ============================================================================

/**
 * Store encrypted access token in database
 */
async function storeAccessToken(
  supabase: any,
  userId: string,
  itemId: string,
  accessToken: string,
  institutionName: string
) {
  const { encrypted_token, iv } = await encryptToken(accessToken);

  const { error } = await supabase
    .from("plaid_items")
    .upsert({
      user_id: userId,
      item_id: itemId,
      access_token_encrypted: encrypted_token,
      iv: iv,
      institution_name: institutionName,
      last_synced: new Date().toISOString(),
    }, { onConflict: "user_id, item_id" });

  if (error) {
    throw new Error(`Failed to store access token: ${error.message}`);
  }
}

/**
 * Retrieve and decrypt access token
 */
async function retrieveAccessToken(supabase: any, userId: string, itemId: string) {
  const { data, error } = await supabase
    .from("plaid_items")
    .select("access_token_encrypted, iv")
    .eq("user_id", userId)
    .eq("item_id", itemId)
    .single();

  if (error || !data) {
    throw new Error("Access token not found");
  }

  return await decryptToken(data.access_token_encrypted, data.iv);
}

/**
 * Sync Plaid accounts to assets table
 */
async function syncPlaidAccounts(
  supabase: any,
  userId: string,
  itemId: string,
  accessToken: string
): Promise<{ synced: number; totalBalance: number }> {
  try {
    // Get item info for institution name
    const itemInfo = await getItemInfo(accessToken);
    const institutionName = itemInfo.item.institution_id || "Unknown Institution";

    // Get account balances
    const balanceData = await getBalances(accessToken);
    const accounts = balanceData.accounts as PlaidAccount[];

    if (!accounts || accounts.length === 0) {
      return { synced: 0, totalBalance: 0 };
    }

    const upsertData = [];
    let totalBalance = 0;

    for (const account of accounts) {
      // Only include accounts with valid balances
      if (account.balances.current !== null && account.balances.current > 0) {
        const processedAccount = processPlaidAccount(
          account,
          userId,
          itemId,
          institutionName
        );

        upsertData.push(processedAccount);
        totalBalance += account.balances.current;
      }
    }

    // Upsert all accounts
    if (upsertData.length > 0) {
      const { error } = await supabase
        .from("assets")
        .upsert(upsertData, {
          onConflict: "asset_address_or_id, user_id",
          ignoreDuplicates: false,
        });

      if (error) {
        throw new Error(`Failed to upsert accounts: ${error.message}`);
      }

      console.log(`Synced ${upsertData.length} accounts for item ${itemId}`);
    }

    // Update last synced timestamp
    await supabase
      .from("plaid_items")
      .update({ last_synced: new Date().toISOString() })
      .eq("user_id", userId)
      .eq("item_id", itemId);

    return { synced: upsertData.length, totalBalance };
  } catch (error) {
    console.error("Failed to sync Plaid accounts:", error);
    throw error;
  }
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload: RequestPayload = await req.json();
    const { action, public_token, userId, itemId, accountIds } = payload;

    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    switch (action) {
      case "exchange_token": {
        if (!public_token || !userId) {
          throw new Error("public_token and userId are required");
        }

        console.log(`Exchanging public token for user ${userId}`);

        // Exchange public token for access token
        const exchangeData = await exchangePublicToken(public_token);
        const { access_token, item_id } = exchangeData;

        // Get item info for institution name
        const itemInfo = await getItemInfo(access_token);
        const institutionName = itemInfo.item.institution_id || "Connected Bank";

        // Store encrypted access token
        await storeAccessToken(supabase, userId, item_id, access_token, institutionName);

        // Initial sync of accounts
        const { synced, totalBalance } = await syncPlaidAccounts(
          supabase,
          userId,
          item_id,
          access_token
        );

        // Record wealth snapshot
        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });

        return new Response(
          JSON.stringify({
            success: true,
            item_id: item_id,
            institution: institutionName,
            accounts_synced: synced,
            total_balance: totalBalance,
            message: "Successfully connected bank account",
          }),
          {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      case "sync_accounts": {
        if (!userId) {
          throw new Error("userId is required");
        }

        console.log(`Syncing Plaid accounts for user ${userId}`);

        // Get all Plaid items for the user
        const { data: plaidItems, error: fetchError } = await supabase
          .from("plaid_items")
          .select("*")
          .eq("user_id", userId);

        if (fetchError) {
          throw new Error(`Failed to fetch Plaid items: ${fetchError.message}`);
        }

        if (!plaidItems || plaidItems.length === 0) {
          return new Response(
            JSON.stringify({
              success: true,
              synced: 0,
              message: "No Plaid items found for user",
            }),
            {
              status: 200,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        }

        let totalSynced = 0;
        let totalBalance = 0;
        const results = [];

        // Sync each item
        for (const item of plaidItems) {
          try {
            // Decrypt access token
            const accessToken = await decryptToken(
              item.access_token_encrypted,
              item.iv
            );

            // Sync accounts
            const { synced, totalBalance: itemBalance } = await syncPlaidAccounts(
              supabase,
              userId,
              item.item_id,
              accessToken
            );

            totalSynced += synced;
            totalBalance += itemBalance;
            results.push({
              item_id: item.item_id,
              institution: item.institution_name,
              synced: synced,
              balance: itemBalance,
            });
          } catch (error) {
            console.error(`Failed to sync item ${item.item_id}:`, error);
            results.push({
              item_id: item.item_id,
              institution: item.institution_name,
              error: error.message,
            });
          }
        }

        // Record wealth snapshot
        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });

        return new Response(
          JSON.stringify({
            success: true,
            total_synced: totalSynced,
            total_balance: totalBalance,
            results: results,
            message: `Synced ${totalSynced} accounts across ${plaidItems.length} institutions`,
          }),
          {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      case "get_accounts": {
        if (!userId || !itemId) {
          throw new Error("userId and itemId are required");
        }

        // Retrieve and decrypt access token
        const accessToken = await retrieveAccessToken(supabase, userId, itemId);

        // Get accounts
        const accountsData = await getAccounts(accessToken, accountIds);

        return new Response(
          JSON.stringify({
            success: true,
            accounts: accountsData.accounts,
            item: accountsData.item,
            request_id: accountsData.request_id,
          }),
          {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      case "remove_item": {
        if (!userId || !itemId) {
          throw new Error("userId and itemId are required");
        }

        console.log(`Removing Plaid item ${itemId} for user ${userId}`);

        // Retrieve access token for Plaid API call
        let accessToken;
        try {
          accessToken = await retrieveAccessToken(supabase, userId, itemId);
          
          // Revoke access token with Plaid
          await plaidRequest("/item/remove", {}, accessToken);
        } catch (error) {
          console.warn("Failed to revoke with Plaid API, continuing with cleanup:", error);
        }

        // Delete associated assets
        const { error: deleteAssetsError } = await supabase
          .from("assets")
          .delete()
          .like("asset_address_or_id", `plaid:${itemId}:%`)
          .eq("user_id", userId);

        if (deleteAssetsError) {
          console.error("Failed to delete associated assets:", deleteAssetsError);
        }

        // Delete Plaid item record
        const { error: deleteItemError } = await supabase
          .from("plaid_items")
          .delete()
          .eq("user_id", userId)
          .eq("item_id", itemId);

        if (deleteItemError) {
          throw new Error(`Failed to delete Plaid item: ${deleteItemError.message}`);
        }

        // Record wealth snapshot
        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });

        return new Response(
          JSON.stringify({
            success: true,
            message: "Successfully removed bank connection",
          }),
          {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      case "webhook": {
        // Handle Plaid webhook events
        const webhookType = payload.webhook_type;
        const webhookCode = payload.webhook_code;
        const itemId = payload.item_id;

        console.log(`Received Plaid webhook: ${webhookType}.${webhookCode} for item ${itemId}`);

        // Find user associated with this item
        const { data: plaidItem } = await supabase
          .from("plaid_items")
          .select("user_id")
          .eq("item_id", itemId)
          .single();

        if (!plaidItem) {
          console.error(`No user found for Plaid item ${itemId}`);
          return new Response(JSON.stringify({ received: true }), { status: 200 });
        }

        const userId = plaidItem.user_id;

        // Handle different webhook types
        switch (webhookType) {
          case "TRANSACTIONS":
            if (webhookCode === "DEFAULT_UPDATE" || webhookCode === "INITIAL_UPDATE") {
              // Sync accounts when transactions are updated
              try {
                const accessToken = await retrieveAccessToken(supabase, userId, itemId);
                await syncPlaidAccounts(supabase, userId, itemId, accessToken);
                await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
              } catch (error) {
                console.error("Failed to sync accounts from webhook:", error);
              }
            }
            break;

          case "ITEM":
            if (webhookCode === "ERROR") {
              console.error(`Plaid error for item ${itemId}:`, payload.error);
              // Could notify user or update item status
            } else if (webhookCode === "NEW_ACCOUNTS_AVAILABLE") {
              // New accounts added, trigger sync
              try {
                const accessToken = await retrieveAccessToken(supabase, userId, itemId);
                await syncPlaidAccounts(supabase, userId, itemId, accessToken);
                await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
              } catch (error) {
                console.error("Failed to sync new accounts:", error);
              }
            }
            break;

          default:
            console.log(`Unhandled webhook type: ${webhookType}`);
        }

        return new Response(JSON.stringify({ received: true }), { status: 200 });
      }

      default:
        throw new Error(`Unknown action: ${action}`);
    }
  } catch (error) {
    console.error("Plaid Manager Error:", error);
    
    return new Response(
      JSON.stringify({
        error: "Internal Error",
        message: error.message,
        action: (await req.json()).action,
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
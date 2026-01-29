// Supabase Edge Function: finance-webhook (Production Ready)
// Purpose: Receive and process real-time Moralis Stream data
// Author: Finance Realtime Engine

// Supabase Edge Function: finance-webhook (CORRIGÉ - Pas de "Body already consumed")
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import jsSha3 from "https://esm.sh/js-sha3";

const MORALIS_API_KEY = Deno.env.get("MORALIS_API_KEY");
const MORALIS_WEBHOOK_SECRET = Deno.env.get("MORALIS_WEBHOOK_SECRET");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-signature",
};

// ============================================================================
// TYPES
// ============================================================================

interface MoralisToken {
  token_address: string;
  symbol: string;
  name: string;
  thumbnail?: string;
  logo?: string;
  balance: string;
  balance_formatted: string;
  usd_price?: number;
  usd_value?: number;
  usd_price_24h_percent_change?: number;
  possible_spam?: boolean;
  verified_contract?: boolean;
}

interface MoralisChainData {
  chain: string;
  native_balance: string;
  native_balance_formatted: string;
  native_balance_usd?: string;
}

interface MoralisPnLData {
  total_realized_profit_usd?: string;
  total_realized_profit_percentage?: string;
  total_trade_volume?: string;
}

// ============================================================================
// MORALIS API HELPERS (REUSABLE)
// ============================================================================

const NATIVE_ICONS: Record<string, string> = {
  eth: "https://assets.coingecko.com/coins/images/279/small/ethereum.png",
  bsc: "https://assets.coingecko.com/coins/images/825/small/binance-coin-logo.png",
  polygon:
    "https://assets.coingecko.com/coins/images/4713/small/matic-token-icon.png",
  avalanche:
    "https://assets.coingecko.com/coins/images/12559/small/Avalanche_Circle_RedWhite_Trans.png",
  arbitrum:
    "https://assets.coingecko.com/coins/images/16547/small/photo_2023-03-29_21.47.00.jpeg",
  optimism:
    "https://assets.coingecko.com/coins/images/25244/small/Optimism.png",
  base: "https://assets.coingecko.com/coins/images/31069/small/base.png",
};

/**
 * Fetch wallet balances directly from Moralis API (most accurate)
 */
async function fetchWalletBalances(address: string): Promise<{
  nativeAssets: any[];
  tokens: MoralisToken[];
}> {
  const options = {
    headers: {
      "X-API-Key": MORALIS_API_KEY!,
      accept: "application/json",
    },
  };

  try {
    // Fetch both networth and tokens in parallel
    const [networthRes, tokensRes] = await Promise.all([
      fetch(
        `https://deep-index.moralis.io/api/v2.2/wallets/${address}/net-worth?exclude_spam=true`,
        options,
      ),
      fetch(
        `https://deep-index.moralis.io/api/v2.2/wallets/${address}/tokens?exclude_spam=true`,
        options,
      ),
    ]);

    if (!networthRes.ok || !tokensRes.ok) {
      throw new Error(
        `Moralis API error: ${networthRes.status}/${tokensRes.status}`,
      );
    }

    const networthData = await networthRes.json();
    const tokensData = await tokensRes.json();

    // Process native assets
    const nativeAssets: any[] = [];
    if (networthData.chains) {
      for (const chain of networthData.chains) {
        const nativeUsd = parseFloat(chain.native_balance_usd || "0");
        if (nativeUsd > 0.1) {
          // Only include significant balances
          const chainName = chain.chain.toLowerCase();
          nativeAssets.push({
            chain: chain.chain,
            symbol: chainName === "eth" ? "ETH" : chainName.toUpperCase(),
            name: `${chainName.toUpperCase()} Native`,
            quantity: parseFloat(chain.native_balance_formatted),
            price_usd:
              nativeUsd / parseFloat(chain.native_balance_formatted) || 0,
            balance_usd: nativeUsd,
            icon_url: NATIVE_ICONS[chainName] || null,
          });
        }
      }
    }

    return {
      nativeAssets,
      tokens: tokensData.result || [],
    };
  } catch (error) {
    console.error(`Failed to fetch balances for ${address}:`, error);
    return { nativeAssets: [], tokens: [] };
  }
}

/**
 * Fetch wallet PnL data
 */
async function fetchWalletPnL(address: string): Promise<MoralisPnLData> {
  try {
    const response = await fetch(
      `https://deep-index.moralis.io/api/v2.2/wallets/${address}/profitability/summary`,
      {
        headers: {
          "X-API-Key": MORALIS_API_KEY!,
          accept: "application/json",
        },
      },
    );

    if (!response.ok) {
      console.warn(`Failed to fetch PnL for ${address}: ${response.status}`);
      return {};
    }

    return await response.json();
  } catch (error) {
    console.error(`Error fetching PnL for ${address}:`, error);
    return {};
  }
}

/**
 * Process token data for database insertion
 */
function processTokenForUpsert(
  token: MoralisToken,
  address: string,
  userId: string,
): any | null {
  const usdValue = parseFloat(token.usd_value?.toString() || "0");

  // Anti-spam filters
  if (token.possible_spam === true) return null;
  if (usdValue < 1) return null; // Minimum $1 threshold

  // Block high-value unverified tokens
  if (usdValue > 10000 && token.verified_contract !== true) return null;

  const price = parseFloat(token.usd_price?.toString() || "0");
  const change24h = parseFloat(
    token.usd_price_24h_percent_change?.toString() || "0",
  );
  const quantity = parseFloat(token.balance_formatted);

  return {
    user_id: userId,
    asset_address_or_id: `${address}:${token.token_address}`,
    provider: "moralis",
    type: "crypto",
    symbol: token.symbol || "UNKNOWN",
    name: token.name || "Unknown Token",
    icon_url: token.thumbnail || token.logo || null,
    quantity: quantity,
    current_price: price,
    price_usd: price,
    balance_usd: usdValue,
    change_24h: change24h,
    last_sync: new Date().toISOString(),
  };
}

/**
 * Process native asset for database insertion
 */
function processNativeAssetForUpsert(
  nativeAsset: any,
  address: string,
  userId: string,
): any {
  return {
    user_id: userId,
    asset_address_or_id: `${address}:native:${nativeAsset.chain}`,
    provider: "moralis",
    type: "crypto",
    symbol: nativeAsset.symbol,
    name: nativeAsset.name,
    icon_url: nativeAsset.icon_url,
    quantity: nativeAsset.quantity,
    current_price: nativeAsset.price_usd,
    price_usd: nativeAsset.price_usd,
     balance_usd: nativeAsset.balance_usd,
    change_24h: 0, // Will be updated by price refresh functions
    last_sync: new Date().toISOString(),
  };
}

// ============================================================================
// SECURITY
// ============================================================================

async function verifySignature(
  payload: string,
  sig: string | null,
): Promise<boolean> {
  if (!sig || !MORALIS_WEBHOOK_SECRET) return false;

  // Moralis formula: keccak256(JSON.stringify(req.body) + secret)
  // We use the jsSha3 export to access keccak256
  const generatedSignature = jsSha3.keccak256(payload + MORALIS_WEBHOOK_SECRET);

  return (
    generatedSignature.toLowerCase() === sig.toLowerCase() ||
    `0x${generatedSignature}`.toLowerCase() === sig.toLowerCase()
  );
}

// ============================================================================
// MAIN HANDLER (CORRIGÉ)
// ============================================================================

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // LIRE LE BODY UNE SEULE FOIS ET LE STOCKER
  let rawBody: string;
  let payload: any;

  try {
    // Lire le body textuel
    rawBody = await req.text();

    // Parser le JSON
    try {
      payload = JSON.parse(rawBody);
    } catch (parseError) {
      console.error("Failed to parse JSON:", parseError);
      return new Response(JSON.stringify({ error: "Invalid JSON payload" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const signature = req.headers.get("x-signature");

    // Skip validation check for Moralis Setup pings
    const isValidationPing =
      !payload.txs || (payload.txs.length === 0 && payload.logs.length === 0);

    if (isValidationPing) {
      console.log("Received validation ping from Moralis");
      return new Response(JSON.stringify({ status: "ok" }), { status: 200 });
    }

    // Verify Signature for production security
    if (
      MORALIS_WEBHOOK_SECRET &&
      !(await verifySignature(rawBody, signature))
    ) {
      console.error("Invalid webhook signature");
      return new Response("Invalid Signature", { status: 401 });
    }

    // Only process confirmed transactions
    if (payload.confirmed) {
      const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
      const addresses = new Set<string>();

      // Collect all addresses involved in transactions
      payload.txs?.forEach((t: any) => {
        addresses.add(t.fromAddress.toLowerCase());
        addresses.add(t.toAddress.toLowerCase());
      });

      payload.erc20Transfers?.forEach((t: any) => {
        addresses.add(t.from.toLowerCase());
        addresses.add(t.to.toLowerCase());
      });

      console.log(
        `Processing webhook for addresses: ${Array.from(addresses).join(", ")}`,
      );

      // Process each address in parallel for speed
      const updatePromises = Array.from(addresses).map(async (addr) => {
        try {
          // 1. Find which user owns this address
         const { data: existingAssets, error: fetchError } = await supabase
            .from("assets")
            .select("user_id")
            .or(`asset_address_or_id.eq.${addr},asset_address_or_id.ilike.${addr}:%`)
            .limit(1);

          if (fetchError) {
            console.error(`Error fetching assets for ${addr}:`, fetchError);
            return { address: addr, error: fetchError.message };
          }

          if (!existingAssets || existingAssets.length === 0) {
            console.log(`No user found for address ${addr}, skipping`);
            return { address: addr, skipped: true };
          }

          const userId = existingAssets[0].user_id;
          console.log(`Updating assets for user ${userId}, address ${addr}`);

          // 2. Fetch current wallet data DIRECTLY from Moralis (most accurate)
          const { nativeAssets, tokens } = await fetchWalletBalances(addr);
          const pnlData = await fetchWalletPnL(addr);

          // Calculate total value for PnL distribution
          const totalValue = [
            ...nativeAssets.map((a) => a.balance_usd),
            ...tokens.map((t) => parseFloat(t.usd_value?.toString() || "0")),
          ].reduce((sum, val) => sum + val, 0);

          // Extract PnL values
          const realizedPnlUsd = parseFloat(
            pnlData.total_realized_profit_usd || "0",
          );
          const realizedPnlPercent = parseFloat(
            pnlData.total_realized_profit_percentage || "0",
          );

          // 3. Prepare data for upsert
          const upsertData = [];

          // Add native assets
          for (const nativeAsset of nativeAssets) {
            const nativeUpsert = processNativeAssetForUpsert(
              nativeAsset,
              addr,
              userId,
            );
            if (nativeUpsert) {
              // Distribute PnL proportionally
              const assetValueRatio =
                totalValue > 0 ? nativeAsset.balance_usd / totalValue : 0;
              upsertData.push({
                ...nativeUpsert,
                realized_pnl_usd: realizedPnlUsd * assetValueRatio,
                realized_pnl_percent: realizedPnlPercent,
              });
            }
          }

          // Add tokens
          for (const token of tokens) {
            const tokenUpsert = processTokenForUpsert(token, addr, userId);
            if (tokenUpsert) {
              // Distribute PnL proportionally
              const tokenValue = parseFloat(token.usd_value?.toString() || "0");
              const assetValueRatio =
                totalValue > 0 ? tokenValue / totalValue : 0;
              upsertData.push({
                ...tokenUpsert,
                realized_pnl_usd: realizedPnlUsd * assetValueRatio,
                realized_pnl_percent: realizedPnlPercent,
              });
            }
          }

          // 4. Upsert all assets in a single transaction
          if (upsertData.length > 0) {
            const { error: upsertError } = await supabase
              .from("assets")
              .upsert(upsertData, {
                onConflict: "asset_address_or_id, user_id",
                ignoreDuplicates: false,
              });

            if (upsertError) {
              console.error(`Upsert failed for ${addr}:`, upsertError);
              return { address: addr, error: upsertError.message };
            }

            console.log(`Updated ${upsertData.length} assets for ${addr}`);
          } else {
            console.log(`No assets to update for ${addr}`);
          }

          // 5. Record wealth snapshot for daily change tracking
          try {
            await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
            console.log(`Recorded snapshot for user ${userId}`);

            // Also update the last sync timestamp for the get-networth function
            await supabase.from("user_sync_status").upsert(
              {
                user_id: userId,
                last_sync: new Date().toISOString(),
                sync_source: "moralis_webhook",
              },
              { onConflict: "user_id" },
            );
          } catch (snapshotError) {
            console.warn(
              `Failed to record snapshot for ${userId}:`,
              snapshotError,
            );
          }

          return {
            address: addr,
            userId,
            count: upsertData.length,
            success: true,
          };
        } catch (error) {
          console.error(`Failed to process address ${addr}:`, error);
          return {
            address: addr,
            error: error.message,
            success: false,
          };
        }
      });

      // Wait for all address updates to complete
      const results = await Promise.all(updatePromises);
      const successful = results.filter((r) => r && r.success);
      const failed = results.filter((r) => r && !r.success);

      console.log(
        `Webhook processed: ${successful.length} successful, ${failed.length} failed`,
      );

      return new Response(
        JSON.stringify({
          success: true,
          processed: successful.length,
          failed: failed.length,
          results: successful,
          errors: failed,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    } else {
      // Transaction not confirmed yet
      console.log("Transaction not confirmed, skipping update");
      return new Response(
        JSON.stringify({
          status: "pending",
          message: "Transaction not confirmed",
          webhook_type: payload.webhook_type,
          webhook_code: payload.webhook_code,
        }),
        { status: 200 },
      );
    }
  } catch (err) {
    console.error("Finance Webhook Error:", err);

    // ICI - PAS DE req.json() - utiliser les variables stockées
    return new Response(
      JSON.stringify({
        error: "Internal Server Error",
        message: err.message,
        timestamp: new Date().toISOString(),
        // Note: pas de 'action' car ce n'est pas un appel d'API standard
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

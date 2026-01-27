// Supabase Edge Function: moralis-stream-manager
// Purpose: Manage Moralis Streams (create, add/remove addresses, cleanup)
// Author: Finance Realtime Engine
// Date: 2026-01-20

// moralis-stream-manager.ts - REFACTORED FOR UNIFIED ARCHITECTURE
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ============================================================================
// TYPES & INTERFACES
// ============================================================================

interface MoralisStream {
  id?: string;
  streamId?: string;
  tag: string;
  description: string;
  webhookUrl: string;
  chainIds: string[];
  status: string;
}

interface RequestPayload {
  action: "setup" | "add_address" | "remove_address" | "cleanup_user";
  address?: string;
  userId?: string;
}

// ============================================================================
// CONFIGURATION
// ============================================================================

const MORALIS_API_KEY = Deno.env.get("MORALIS_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const WEBHOOK_URL =
  Deno.env.get("FINANCE_WEBHOOK_URL") ||
  `${SUPABASE_URL}/functions/v1/finance-webhook`;

const STREAM_TAG = "financo-global-stream";
const SUPPORTED_CHAINS = [
  "0x1",    // Ethereum
  "0x89",   // Polygon
  "0x38",   // BSC
  "0xa86a", // Avalanche
  "0xa4b1", // Arbitrum
  "0xa",    // Optimism
  "0x2105", // Base
];

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const NATIVE_ICONS: Record<string, string> = {
  eth: "https://assets.coingecko.com/coins/images/279/small/ethereum.png",
  bsc: "https://assets.coingecko.com/coins/images/825/small/binance-coin-logo.png",
  polygon: "https://assets.coingecko.com/coins/images/4713/small/matic-token-icon.png",
  avalanche: "https://assets.coingecko.com/coins/images/12559/small/Avalanche_Circle_RedWhite_Trans.png",
  arbitrum: "https://assets.coingecko.com/coins/images/16547/small/photo_2023-03-29_21.47.00.jpeg",
  optimism: "https://assets.coingecko.com/coins/images/25244/small/Optimism.png",
  base: "https://assets.coingecko.com/coins/images/31069/small/base.png",
};

// ============================================================================
// MORALIS API HELPERS (UPDATED)
// ============================================================================

function extractStreamId(stream: MoralisStream): string {
  const id = stream.id || stream.streamId;
  if (!id) throw new Error("Could not find Stream ID in Moralis response");
  return id;
}

async function moralisRequest(
  endpoint: string,
  method: string = "GET",
  body?: any,
): Promise<any> {
  if (!MORALIS_API_KEY) throw new Error("MORALIS_API_KEY not configured");

  const options: RequestInit = {
    method,
    headers: {
      "X-API-Key": MORALIS_API_KEY,
      "Content-Type": "application/json",
      accept: "application/json",
    },
  };
  if (body) options.body = JSON.stringify(body);

  const response = await fetch(
    `https://api.moralis-streams.com/streams/evm${endpoint}`,
    options,
  );
  
  if (response.status === 429) {
    throw new Error("Moralis API rate limit exceeded. Please try again later.");
  }
  
  const responseData = await response.json();

  if (!response.ok) {
    throw new Error(
      `Moralis API error: ${response.status} - ${JSON.stringify(responseData)}`,
    );
  }
  return responseData;
}

/**
 * Find existing stream by tag.
 */
async function findStreamByTag(tag: string): Promise<MoralisStream | null> {
  try {
    const response = await moralisRequest("?limit=10");
    const streams = response.result || [];
    return streams.find((s: MoralisStream) => s.tag === tag) || null;
  } catch (error) {
    console.error("Error fetching streams:", error);
    return null;
  }
}

async function setupMoralisStream(): Promise<MoralisStream> {
  let stream = await findStreamByTag(STREAM_TAG);
  if (stream) return stream;

  console.log("Creating new global Moralis stream...");
  return await moralisRequest("", "PUT", {
    chainIds: SUPPORTED_CHAINS,
    description: "Financo global wallet monitoring",
    tag: STREAM_TAG,
    webhookUrl: WEBHOOK_URL,
    includeNativeTxs: true,
    includeContractLogs: true,
    includeInternalTxs: true,
  });
}

// ============================================================================
// WALLET DATA PROCESSING (NEW FUNCTIONS)
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

/**
 * Fetch wallet performance data including PnL
 */
async function fetchWalletPerformance(address: string): Promise<MoralisPnLData> {
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
 * Process and validate tokens before insertion
 */
function processTokenData(
  token: MoralisToken,
  address: string,
  userId: string
): any | null {
  const usdValue = parseFloat(token.usd_value?.toString() || "0");
  
  // Anti-spam and validation filters
  if (token.possible_spam === true) return null;
  if (usdValue < 1) return null; // Increased from 0.5 to reduce noise
  
  // Block high-value unverified tokens (potential scams)
  if (usdValue > 10000 && token.verified_contract !== true) return null;
  
  const price = parseFloat(token.usd_price?.toString() || "0");
  const change24h = parseFloat(token.usd_price_24h_percent_change?.toString() || "0");
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
 * Process native chain assets
 */
function processNativeAsset(
  chain: MoralisChainData,
  address: string,
  userId: string
): any | null {
  const nativeUsd = parseFloat(chain.native_balance_usd || "0");
  if (nativeUsd < 0.1) return null; // Minimum threshold
  
  const quantity = parseFloat(chain.native_balance_formatted);
  const price = quantity > 0 ? nativeUsd / quantity : 0;
  
  const chainName = chain.chain.toLowerCase();
  const symbol = chainName === "eth" ? "ETH" : chainName.toUpperCase();
  
  return {
    user_id: userId,
    asset_address_or_id: `${address}:native:${chain.chain}`,
    provider: "moralis",
    type: "crypto",
    symbol: symbol,
    name: `${symbol} Native`,
    icon_url: NATIVE_ICONS[chainName] || null,
    quantity: quantity,
    current_price: price,
    price_usd: price,
    balance_usd: nativeUsd,
    change_24h: 0, // Will be updated by finance-webhook
    last_sync: new Date().toISOString(),
  };
}

// ============================================================================
// MAIN HANDLER (REFACTORED)
// ============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  try {
    const payload: RequestPayload = await req.json();
    const { action, address, userId } = payload;
    
    if (!action) throw new Error("Action is required");
    
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    switch (action) {
      case "setup": {
        console.log("Setting up Moralis stream...");
        const stream = await setupMoralisStream();
        return new Response(
          JSON.stringify({ 
            success: true, 
            streamId: extractStreamId(stream),
            tag: STREAM_TAG,
            webhookUrl: WEBHOOK_URL
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      case "add_address": {
        if (!address || !userId)
          throw new Error("Address and userId are required");
        
        const cleanAddress = address.toLowerCase();
        console.log(`Adding address ${cleanAddress} for user ${userId}`);

        // 1. Setup stream and add address
        const stream = await setupMoralisStream();
        const streamId = extractStreamId(stream);
        
        await moralisRequest(`/${streamId}/address`, "POST", {
          address: cleanAddress,
        });

        // 2. Fetch all data in parallel
        const [networthRes, tokensRes, pnlRes] = await Promise.allSettled([
          fetch(
            `https://deep-index.moralis.io/api/v2.2/wallets/${cleanAddress}/net-worth?exclude_spam=true`,
            {
              headers: {
                "X-API-Key": MORALIS_API_KEY!,
                accept: "application/json",
              },
            },
          ),
          fetch(
            `https://deep-index.moralis.io/api/v2.2/wallets/${cleanAddress}/tokens?exclude_spam=true&exclude_unverified_contracts=true`,
            {
              headers: {
                "X-API-Key": MORALIS_API_KEY!,
                accept: "application/json",
              },
            },
          ),
          fetchWalletPerformance(cleanAddress),
        ]);

        // 3. Process networth data
        const upsertData = [];
        
        if (networthRes.status === "fulfilled" && networthRes.value.ok) {
          const nwData = await networthRes.value.json();
          
          if (nwData.chains) {
            for (const chain of nwData.chains) {
              const nativeAsset = processNativeAsset(chain, cleanAddress, userId);
              if (nativeAsset) {
                upsertData.push(nativeAsset);
              }
            }
          }
        }

        // 4. Process token data
        if (tokensRes.status === "fulfilled" && tokensRes.value.ok) {
          const tokenData = await tokensRes.value.json();
          const tokens: MoralisToken[] = tokenData.result || [];
          
          for (const token of tokens) {
            const processedToken = processTokenData(token, cleanAddress, userId);
            if (processedToken) {
              upsertData.push(processedToken);
            }
          }
        }

        // 5. Process PnL data if available
        let realizedPnlUsd = 0;
        let realizedPnlPercent = 0;
        
        if (pnlRes.status === "fulfilled") {
          const pnlData = pnlRes.value;
          realizedPnlUsd = parseFloat(pnlData.total_realized_profit_usd || "0");
          realizedPnlPercent = parseFloat(pnlData.total_realized_profit_percentage || "0");
        }

        // 6. Upsert all assets in a single transaction
        if (upsertData.length > 0) {
          // Add PnL data to each asset (distributed proportionally)
          const totalValue = upsertData.reduce((sum, asset) => sum + asset.balance_usd, 0);
          
          const assetsWithPnl = upsertData.map(asset => {
            const assetValueRatio = totalValue > 0 ? asset.balance_usd / totalValue : 0;
            return {
              ...asset,
              realized_pnl_usd: realizedPnlUsd * assetValueRatio,
              realized_pnl_percent: realizedPnlPercent,
            };
          });

          const { error: upsertError } = await supabase
            .from("assets")
            .upsert(assetsWithPnl, { 
              onConflict: "asset_address_or_id, user_id",
              ignoreDuplicates: false
            });
            
          if (upsertError) {
            console.error("Upsert error:", upsertError);
            throw new Error(`Failed to upsert assets: ${upsertError.message}`);
          }
          
          console.log(`Upserted ${assetsWithPnl.length} assets for ${cleanAddress}`);
        }

        // 7. Record snapshot for daily change tracking
        try {
          await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
          console.log(`Recorded snapshot for user ${userId}`);
        } catch (snapshotError) {
          console.warn("Failed to record snapshot:", snapshotError);
          // Continue execution even if snapshot fails
        }

        return new Response(
          JSON.stringify({ 
            success: true, 
            count: upsertData.length,
            address: cleanAddress,
            message: `Successfully added ${upsertData.length} assets`
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      case "remove_address": {
        if (!address) throw new Error("Address is required");
        
        const cleanAddress = address.toLowerCase();
        console.log(`Removing address ${cleanAddress}`);

        // 1. Remove address from Moralis stream
        const stream = await findStreamByTag(STREAM_TAG);
        if (stream) {
          await moralisRequest(
            `/${extractStreamId(stream)}/address`,
            "DELETE",
            { address: cleanAddress },
          ).catch(err => {
            console.warn(`Failed to remove ${cleanAddress} from Moralis stream:`, err);
          });
        }

        // 2. Delete associated assets from database
        const { error: deleteError } = await supabase
          .from("assets")
          .delete()
          .like("asset_address_or_id", `${cleanAddress}%`);

        if (deleteError) {
          throw new Error(`Failed to delete assets: ${deleteError.message}`);
        }

        // 3. Update snapshot if userId provided
        if (userId) {
          try {
            await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
          } catch (snapshotError) {
            console.warn("Failed to update snapshot after removal:", snapshotError);
          }
        }

        return new Response(JSON.stringify({ 
          success: true,
          message: `Removed address ${cleanAddress} and associated assets`
        }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "cleanup_user": {
        if (!userId) throw new Error("userId is required for cleanup");
        
        console.log(`Cleaning up all assets for user ${userId}`);
        
        // 1. Get all addresses for this user
        const { data: userAssets, error: fetchError } = await supabase
          .from("assets")
          .select("asset_address_or_id")
          .eq("user_id", userId)
          .eq("provider", "moralis");

        if (fetchError) throw new Error(`Failed to fetch user assets: ${fetchError.message}`);
        
        // 2. Extract unique addresses
        const addresses = new Set<string>();
        userAssets?.forEach(asset => {
          if (asset.asset_address_or_id) {
            const parts = asset.asset_address_or_id.split(':');
            if (parts.length > 0) {
              addresses.add(parts[0].toLowerCase());
            }
          }
        });

        // 3. Remove each address from Moralis stream
        const stream = await findStreamByTag(STREAM_TAG);
        if (stream) {
          const streamId = extractStreamId(stream);
          const removalPromises = Array.from(addresses).map(addr =>
            moralisRequest(`/${streamId}/address`, "DELETE", { address: addr })
              .catch(err => console.warn(`Failed to remove ${addr}:`, err))
          );
          await Promise.all(removalPromises);
        }

        // 4. Delete all user's moralis assets
        const { error: deleteError } = await supabase
          .from("assets")
          .delete()
          .eq("user_id", userId)
          .eq("provider", "moralis");

        if (deleteError) {
          throw new Error(`Failed to delete user assets: ${deleteError.message}`);
        }

        return new Response(JSON.stringify({ 
          success: true,
          removed_addresses: Array.from(addresses),
          message: `Cleaned up ${addresses.size} addresses for user ${userId}`
        }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      default:
        throw new Error(`Unknown action: ${action}`);
    }
  } catch (error) {
    console.error("Moralis Stream Manager Error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Internal Error", 
        message: error.message,
        action: (await req.json()).action 
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
// supabase secrets set MORALIS_API_KEY=your_moralis_api_key_here
// supabase functions deploy finance-webhook --no-verify-jwt
// supabase functions deploy moralis-stream-manager --no-verify-jwt
// // curl -X POST https://nbdfdlvbouoaoprbkbme.supabase.co/functions/v1/moralis-stream-manager -H "Content-Type: application/json" -d '{"action": "setup"}'

// Supabase Edge Function: moralis-stream-manager
// Purpose: Manage Moralis Streams (create, add/remove addresses, cleanup)
// Author: Finance Realtime Engine
// Date: 2026-01-20

// moralis-stream-manager.ts - CORRIGÉ POUR "Body already consumed"
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
  "0x1",
  "0x89",
  "0x38",
  "0xa86a",
  "0xa4b1",
  "0xa",
  "0x2105",
];

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

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

// ============================================================================
// MORALIS API HELPERS
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
 * Note: ?limit=10 is now required by Moralis API
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
// MAIN HANDLER - CORRIGÉ POUR L'ERREUR "Body already consumed"
// ============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  // STOCKER LE BODY AVANT TOUTE CHOSE
  let payload: RequestPayload;
  let action: string;

  try {
    // Lire le body une seule fois et le stocker
    const requestData = await req.json();
    payload = requestData as RequestPayload;
    action = payload.action;

    if (!action) {
      throw new Error("Action is required");
    }

    const { address, userId } = payload;
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    switch (action) {
      case "setup": {
        console.log("Setting up Moralis stream...");
        const stream = await setupMoralisStream();
        return new Response(
          JSON.stringify({
            success: true,
            streamId: extractStreamId(stream),
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

        // 2. Fetch wallet data
        const [nwRes, tokenRes] = await Promise.all([
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
            `https://deep-index.moralis.io/api/v2.2/wallets/${cleanAddress}/tokens?exclude_spam=true`,
            {
              headers: {
                "X-API-Key": MORALIS_API_KEY!,
                accept: "application/json",
              },
            },
          ),
        ]);

        const nwData = await nwRes.json();
        const tokenData = await tokenRes.json();
        const tokens = tokenData.result || [];

        const upsertData = [];

        // Process Native Assets
        if (nwData.chains) {
          for (const chain of nwData.chains) {
            const nativeUsd = parseFloat(chain.native_balance_usd || "0");
            if (nativeUsd > 1) {
              upsertData.push({
                user_id: userId,
                asset_address_or_id: `${cleanAddress}:native:${chain.chain}`,
                provider: "moralis",
                type: "crypto",
                symbol:
                  chain.chain === "eth" ? "ETH" : chain.chain.toUpperCase(),
                name: `${chain.chain.toUpperCase()} Native`,
                icon_url: NATIVE_ICONS[chain.chain] || null,
                quantity: parseFloat(chain.native_balance_formatted),
                price_usd:
                  nativeUsd / parseFloat(chain.native_balance_formatted),
                balance_usd: nativeUsd,
                last_sync: new Date().toISOString(),
              });
            }
          }
        }

        // Process Tokens with Anti-Spam filters
        for (const token of tokens) {
          const usdValue = parseFloat(token.usd_value || "0");

          if (token.possible_spam === true) continue;
          if (usdValue < 5) continue;

          // Block high-value tokens that are NOT verified
          if (usdValue > 50000 && token.verified_contract !== true) continue;

          upsertData.push({
            user_id: userId,
            asset_address_or_id: `${cleanAddress}:${token.token_address}`,
            provider: "moralis",
            type: "crypto",
            symbol: token.symbol,
            name: token.name,
            icon_url: token.thumbnail || token.logo || null,
            quantity: parseFloat(token.balance_formatted),
            price_usd: parseFloat(token.usd_price || "0"),
            balance_usd: usdValue,
            change_24h: parseFloat(token.usd_price_24h_percent_change || "0"),
            last_sync: new Date().toISOString(),
          });
        }

        if (upsertData.length > 0) {
          const { error } = await supabase
            .from("assets")
            .upsert(upsertData, { onConflict: "asset_address_or_id, user_id" });
          if (error) throw error;
        }

        // Record snapshot
        try {
          await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
        } catch (snapshotError) {
          console.warn("Failed to record snapshot:", snapshotError);
        }

        return new Response(
          JSON.stringify({ success: true, count: upsertData.length }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      case "remove_address": {
        if (!address || !userId)
          throw new Error("Address and userId are required");

        const cleanAddress = address.toLowerCase();
        console.log(`Removing address ${cleanAddress} for user ${userId}`);

        // 1. Remove address from Moralis stream
        const stream = await findStreamByTag(STREAM_TAG);
        if (stream) {
          await moralisRequest(
            `/${extractStreamId(stream)}/address`,
            "DELETE",
            { address: cleanAddress },
          );
        }

        // 2. Delete only THIS USER'S associated assets
        await supabase
          .from("assets")
          .delete()
          .like("asset_address_or_id", `${cleanAddress}%`)
          .eq("user_id", userId); // <-- CRITIQUE : sans ça, tu supprimes pour tous les users

        return new Response(JSON.stringify({ success: true }), {
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

        if (fetchError)
          throw new Error(`Failed to fetch user assets: ${fetchError.message}`);

        // 2. Extract unique addresses
        const addresses = new Set<string>();
        userAssets?.forEach((asset) => {
          if (asset.asset_address_or_id) {
            const parts = asset.asset_address_or_id.split(":");
            if (parts.length > 0) {
              addresses.add(parts[0].toLowerCase());
            }
          }
        });

        // 3. Remove each address from Moralis stream
        const stream = await findStreamByTag(STREAM_TAG);
        if (stream) {
          const streamId = extractStreamId(stream);
          for (const addr of addresses) {
            try {
              await moralisRequest(`/${streamId}/address`, "DELETE", {
                address: addr,
              });
            } catch (err) {
              console.warn(`Failed to remove ${addr}:`, err);
            }
          }
        }

        // 4. Delete all user's moralis assets
        await supabase
          .from("assets")
          .delete()
          .eq("user_id", userId)
          .eq("provider", "moralis");

        return new Response(
          JSON.stringify({
            success: true,
            removed_addresses: Array.from(addresses),
            message: `Cleaned up ${addresses.size} addresses for user ${userId}`,
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      default:
        throw new Error(`Unknown action: ${action}`);
    }
  } catch (error) {
    console.error("Moralis Stream Manager Error:", error.message);

    return new Response(
      JSON.stringify({
        error: "Internal Error",
        message: error.message,
        action: action || "unknown", // Utilise la variable stockée
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

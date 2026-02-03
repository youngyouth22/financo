// Supabase Edge Function: moralis-stream-manager
// Purpose: Manage Moralis Streams and Sync Assets with Real-time Prices & OHLCV History
// Features: Native & ERC20 Sparklines, Correct 24h Change Mapping, Parallel Processing
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

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

// Map for Native history (Moralis needs a contract address for price-history)
const WRAPPED_ADDR: Record<string, string> = {
  eth: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", // WETH
  bsc: "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c", // WBNB
  polygon: "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270", // WMATIC
};

const NATIVE_ICONS: Record<string, string> = {
  eth: "https://assets.coingecko.com/coins/images/279/small/ethereum.png",
  bsc: "https://assets.coingecko.com/coins/images/825/small/binance-coin-logo.png",
  polygon:
    "https://assets.coingecko.com/coins/images/4713/small/matic-token-icon.png",
};

// ============================================================================
// HELPERS
// ============================================================================

async function moralisRequest(
  endpoint: string,
  method: string = "GET",
  body?: any,
) {
  const response = await fetch(
    `https://deep-index.moralis.io/api/v2.2${endpoint}`,
    {
      method,
      headers: {
        "X-API-Key": MORALIS_API_KEY!,
        "Content-Type": "application/json",
        accept: "application/json",
      },
      body: body ? JSON.stringify(body) : undefined,
    },
  );
  return response.json();
}

/**
 * Fetches 24h history for sparklines.
 */
async function getHistory(address: string, chain: string): Promise<number[]> {
  try {
    const url = `/erc20/${address}/price-history?chain=${chain}&days=1&interval=1h`;
    const response = await fetch(
      `https://deep-index.moralis.io/api/v2.2${url}`,
      {
        headers: { "X-API-Key": MORALIS_API_KEY!, accept: "application/json" },
      },
    );
    const text = await response.text();
    if (text.startsWith("<!DOCTYPE")) return []; // Safety check for 404 HTML

    const data = JSON.parse(text);
    if (!data.result || !Array.isArray(data.result)) return [];
    return data.result.map((p: any) => parseFloat(p.usdPrice || 0));
  } catch {
    return [];
  }
}

async function setupMoralisStream() {
  const response = await fetch(
    `https://api.moralis-streams.com/streams/evm?limit=10`,
    {
      headers: { "X-API-Key": MORALIS_API_KEY!, accept: "application/json" },
    },
  );
  const streams = await response.json();
  const existing = (streams.result || []).find(
    (s: any) => s.tag === STREAM_TAG,
  );
  if (existing) return existing.id;

  const created = await fetch(`https://api.moralis-streams.com/streams/evm`, {
    method: "PUT",
    headers: {
      "X-API-Key": MORALIS_API_KEY!,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      chainIds: SUPPORTED_CHAINS,
      description: "Financo global wallet monitoring",
      tag: STREAM_TAG,
      webhookUrl: WEBHOOK_URL,
      includeNativeTxs: true,
      includeContractLogs: true,
    }),
  });
  const data = await created.json();
  return data.id;
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  let action = "unknown";
  try {
    const payload = await req.json();
    action = (payload.action || "unknown").trim();
    const { address, userId } = payload;
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    switch (action) {
      case "setup": {
        const id = await setupMoralisStream();
        return new Response(JSON.stringify({ success: true, streamId: id }), {
          status: 200,
          headers: corsHeaders,
        });
      }

      case "add_address":
      case "refresh_assets": {
        if (!address || !userId) throw new Error("Missing parameters");
        const cleanAddress = address.toLowerCase();

        // 1. Ensure Stream Registration
        if (action === "add_address") {
          const sId = await setupMoralisStream();
          await fetch(
            `https://api.moralis-streams.com/streams/evm/${sId}/address`,
            {
              method: "POST",
              headers: {
                "X-API-Key": MORALIS_API_KEY!,
                "Content-Type": "application/json",
              },
              body: JSON.stringify({ address: cleanAddress }),
            },
          );
        }

        // 2. Fetch Wallet State
        const [nwData, tokenRes] = await Promise.all([
          moralisRequest(
            `/wallets/${cleanAddress}/net-worth?exclude_spam=true`,
          ),
          moralisRequest(
            `/wallets/${cleanAddress}/tokens?exclude_spam=true&exclude_unverified_contracts=true`,
          ),
        ]);

        const tokens = tokenRes.result || [];
        const upsertData = [];

        // 3. Process Native Assets (Millions in ETH, etc.)
        if (nwData.chains) {
          for (const c of nwData.chains) {
            const usd = parseFloat(c.native_balance_usd || "0");
            if (usd > 0.1) {
              const wrappedAddr = WRAPPED_ADDR[c.chain.toLowerCase()];
              const history = wrappedAddr
                ? await getHistory(wrappedAddr, c.chain)
                : [];

              upsertData.push({
                user_id: userId,
                asset_address_or_id: `${cleanAddress}:native:${c.chain}`,
                provider: "moralis",
                type: "crypto",
                symbol: c.chain === "eth" ? "ETH" : c.chain.toUpperCase(),
                name: `${c.chain.toUpperCase()} Native`,
                icon_url: NATIVE_ICONS[c.chain.toLowerCase()] || null,
                quantity: parseFloat(c.native_balance_formatted),
                price_usd: usd / parseFloat(c.native_balance_formatted),
                balance_usd: usd,
                change_24h: 0,
                sparkline: history,
                last_sync: new Date().toISOString(),
              });
            }
          }
        }

        // 4. Process ERC20 Tokens (Top 10 with Parallel History)
        const topTokens = tokens
          .filter(
            (t: any) =>
              t.possible_spam !== true && parseFloat(t.usd_value || "0") > 5,
          )
          .sort(
            (a: any, b: any) =>
              parseFloat(b.usd_value) - parseFloat(a.usd_value),
          )
          .slice(0, 10);

        const histories = await Promise.all(
          topTokens.map((t: any) =>
            getHistory(t.token_address, t.chain || "eth"),
          ),
        );

        topTokens.forEach((t: any, index: number) => {
          upsertData.push({
            user_id: userId,
            asset_address_or_id: `${cleanAddress}:${t.token_address}`,
            provider: "moralis",
            type: "crypto",
            symbol: t.symbol,
            name: t.name,
            icon_url: t.thumbnail || t.logo || null,
            quantity: parseFloat(t.balance_formatted),
            price_usd: parseFloat(t.usd_price || "0"),
            balance_usd: parseFloat(t.usd_value || "0"),
            change_24h: parseFloat(t.usd_price_24hr_percent_change || "0"), // CORRECTED MAPPING
            sparkline: histories[index],
            last_sync: new Date().toISOString(),
          });
        });

        // 5. Database Sync
        if (upsertData.length > 0) {
          const { error } = await supabase
            .from("assets")
            .upsert(upsertData, { onConflict: "asset_address_or_id, user_id" });
          if (error) throw error;
        }

        // 6. Maintenance
        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
        await supabase.rpc("generate_portfolio_insights", {
          p_user_id: userId,
        });

        return new Response(
          JSON.stringify({
            success: true,
            networth: nwData.total_networth_usd,
            count: upsertData.length,
          }),
          {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      case "remove_address": {
        const clean = address!.toLowerCase();
        await supabase
          .from("assets")
          .delete()
          .like("asset_address_or_id", `${clean}%`)
          .eq("user_id", userId);
        return new Response(JSON.stringify({ success: true }), {
          headers: corsHeaders,
        });
      }

      default:
        throw new Error(`Action ${action} not recognized`);
    }
  } catch (error) {
    console.error(`[Error] Action: ${action} ->`, error.message);
    return new Response(JSON.stringify({ error: error.message, action }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
// supabase secrets set MORALIS_API_KEY=your_moralis_api_key_here
// supabase functions deploy finance-webhook --no-verify-jwt
// supabase functions deploy moralis-stream-manager --no-verify-jwt
// // curl -X POST https://nbdfdlvbouoaoprbkbme.supabase.co/functions/v1/moralis-stream-manager -H "Content-Type: application/json" -d '{"action": "setup"}'

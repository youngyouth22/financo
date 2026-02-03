// supabase/functions/refresh-market-prices/index.ts
// Purpose: High-performance price & sparkline synchronization
// Features: Moralis Batch Token Pricing (New), FMP Stable Batch Quotes,
//           and Intelligent Hourly Sparkline Refresh logic.
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const MORALIS_API_KEY = Deno.env.get("MORALIS_API_KEY");
const FMP_API_KEY = Deno.env.get("FMP_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const BASE_URL_STABLE = "https://financialmodelingprep.com/stable";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ============================================================================
// HELPERS
// ============================================================================

async function fetchMoralisHistory(
  tokenAddr: string,
  chain: string,
): Promise<number[]> {
  try {
    const url = `https://deep-index.moralis.io/api/v2.2/erc20/${tokenAddr}/price-history?chain=${chain}&days=1`;
    const res = await fetch(url, {
      headers: { "X-API-Key": MORALIS_API_KEY!, accept: "application/json" },
    });
    const data = await res.json();
    return (data.result || []).map((p: any) => parseFloat(p.usdPrice || 0));
  } catch {
    return [];
  }
}

async function fetchFMPHistory(symbol: string): Promise<number[]> {
  try {
    const url = `${BASE_URL_STABLE}/historical-chart/1hour/${symbol.toUpperCase()}?apikey=${FMP_API_KEY}`;
    const res = await fetch(url);
    const data = await res.json();
    return Array.isArray(data)
      ? data
          .slice(0, 24)
          .map((p: any) => p.close)
          .reverse()
      : [];
  } catch {
    return [];
  }
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  try {
    const { userId } = await req.json();
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
    const now = new Date();

    // 1. Get all active assets
    const { data: assets } = await supabase
      .from("assets")
      .select("*")
      .eq("user_id", userId)
      .eq("status", "active");
    if (!assets || assets.length === 0)
      return new Response(JSON.stringify({ success: true }));

    const updates = [];

    // --- GROUP 1: FMP ASSETS (Stocks, Gold, Major Crypto like BTCUSD) ---
    const fmpAssets = assets.filter(
      (a) =>
        a.provider === "fmp" ||
        (a.provider === "moralis" && a.symbol === "BTC"),
    );
    if (fmpAssets.length > 0) {
      const symbols = fmpAssets
        .map((a) => (a.provider === "moralis" ? `${a.symbol}USD` : a.symbol))
        .join(",");
      const fmpRes = await fetch(
        `${BASE_URL_STABLE}/batch-quote?symbols=${symbols}&apikey=${FMP_API_KEY}`,
      );
      const quotes = await fmpRes.json();

      if (Array.isArray(quotes)) {
        for (const q of quotes) {
          const asset = assets.find((a) => q.symbol.startsWith(a.symbol));
          if (!asset) continue;

          let up: any = {
            current_price: q.price,
            price_usd: q.price,
            balance_usd: q.price * asset.quantity,
            change_24h: q.changesPercentage, // Correct mapping for +10% / -5%
            last_sync: now.toISOString(),
          };

          // Update Sparkline every hour
          const lastSync = new Date(asset.last_sync || 0);
          if (
            now.getTime() - lastSync.getTime() > 3600000 ||
            !asset.sparkline?.length
          ) {
            up.sparkline = await fetchFMPHistory(asset.symbol);
          }
          updates.push(supabase.from("assets").update(up).eq("id", asset.id));
        }
      }
    }

    // --- GROUP 2: MORALIS ASSETS (ERC20 Tokens / Whitecoins) ---
    const tokens = assets.filter(
      (a) =>
        a.provider === "moralis" &&
        !a.asset_address_or_id.includes(":native:") &&
        a.symbol !== "BTC",
    );
    if (tokens.length > 0) {
      // Refresh Prices via Moralis Batch API
      const tokenPayload = {
        tokens: tokens.map((a) => ({
          token_address: a.asset_address_or_id.split(":").pop(),
        })),
      };
      const res = await fetch(
        `https://deep-index.moralis.io/api/v2.2/erc20/prices?chain=eth`,
        {
          method: "POST",
          headers: {
            "X-API-Key": MORALIS_API_KEY!,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(tokenPayload),
        },
      );
      const batchData = await res.json();

      if (Array.isArray(batchData)) {
        for (const data of batchData) {
          const asset = tokens.find((a) =>
            a.asset_address_or_id
              .toLowerCase()
              .endsWith(data.tokenAddress.toLowerCase()),
          );
          if (!asset) continue;

          let up: any = {
            current_price: data.usdPrice,
            price_usd: data.usdPrice,
            balance_usd: data.usdPrice * asset.quantity,
            change_24h: parseFloat(data["24hrPercentChange"] || "0"),
            last_sync: now.toISOString(),
          };

          const lastSync = new Date(asset.last_sync || 0);
          if (
            now.getTime() - lastSync.getTime() > 3600000 ||
            !asset.sparkline?.length
          ) {
            up.sparkline = await fetchMoralisHistory(data.tokenAddress, "eth");
          }
          updates.push(supabase.from("assets").update(up).eq("id", asset.id));
        }
      }
    }

    // 2. Execute all updates
    await Promise.allSettled(updates);

    // 3. Maintenance (Josh's Analysis)
    await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
    await supabase.rpc("generate_portfolio_insights", { p_user_id: userId });

    return new Response(
      JSON.stringify({ success: true, count: updates.length }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: corsHeaders,
    });
  }
});

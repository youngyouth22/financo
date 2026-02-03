// Supabase Edge Function: fmp-manager
// Purpose: Unified handler for Financial Modeling Prep (FMP) API
// Features: Stable API (2025+) support, Real-time Quotes, 24h Sparklines,
//           Support for Stocks, ETFs, and Commodities with robust fallback.
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ============================================================================
// CONFIGURATION & SECRETS
// ============================================================================

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
// FMP API HELPERS (STABLE & ROBUST)
// ============================================================================

function checkApiKey() {
  if (!FMP_API_KEY)
    throw new Error("FMP_API_KEY is not configured in Supabase secrets");
}

async function fmpStableFetch(
  endpoint: string,
  params: string,
): Promise<any[]> {
  checkApiKey();
  const url = `${BASE_URL_STABLE}/${endpoint}?${params}&apikey=${FMP_API_KEY}`;
  const response = await fetch(url);
  const text = await response.text();

  let data;
  try {
    data = JSON.parse(text);
  } catch (e) {
    if (text.toLowerCase().includes("premium")) {
      throw new Error("This action requires a Premium FMP Plan.");
    }
    throw new Error(`FMP API Error: ${text.substring(0, 50)}...`);
  }

  if (!Array.isArray(data)) {
    throw new Error(
      data["Error Message"] || "FMP API returned an error object",
    );
  }
  return data;
}

/**
 * Fetches 24h historical data for sparkline rendering with fallback logic.
 */
async function fetchPriceHistory(symbol: string): Promise<number[]> {
  try {
    // 1. Try 1-hour interval chart (Best for 24h view)
    let data = await fmpStableFetch(
      `historical-chart/1hour/${symbol.toUpperCase()}`,
      "",
    );

    // 2. Fallback to End-Of-Day light chart if 1hour is not available for this asset
    if (data.length === 0) {
      console.log(`[Sparkline] Falling back to EOD light for ${symbol}`);
      data = await fmpStableFetch(
        `historical-price-eod/light`,
        `symbol=${symbol.toUpperCase()}`,
      );
    }

    if (data.length === 0) return [];

    // Detect key name (stable API can use 'close' or 'price')
    const first = data[0];
    const key =
      first.close !== undefined
        ? "close"
        : first.price !== undefined
          ? "price"
          : null;
    if (!key) return [];

    return data
      .slice(0, 24)
      .map((p: any) => parseFloat(p[key]))
      .reverse();
  } catch (e) {
    console.warn(
      `[Sparkline] History fetch failed for ${symbol}: ${e.message}`,
    );
    return [];
  }
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  let actionName = "unknown";

  try {
    const payload = await req.json();
    actionName = payload.action || "unknown";
    const { query, symbol, userId, quantity, assetId } = payload;
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    switch (actionName) {
      case "search": {
        if (!query) throw new Error("Search query is required");
        const results = await fmpStableFetch(
          "search-symbol",
          `query=${encodeURIComponent(query)}`,
        );
        return new Response(JSON.stringify(results), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "add_asset": {
        if (!userId || !symbol || !quantity)
          throw new Error("Missing required fields");
        const ticker = symbol.toUpperCase();

        // 1. Fetch Market Data in Parallel
        const [profileRes, quoteRes, sparkline] = await Promise.allSettled([
          fmpStableFetch("profile", `symbol=${ticker}`),
          fmpStableFetch("quote", `symbol=${ticker}`),
          fetchPriceHistory(ticker),
        ]);

        if (quoteRes.status === "rejected" || quoteRes.value.length === 0) {
          throw new Error(`Quote data not found for ${ticker}`);
        }

        const quote = quoteRes.value[0];
        const profile =
          profileRes.status === "fulfilled" && profileRes.value.length > 0
            ? profileRes.value[0]
            : null;
        const historyPoints =
          sparkline.status === "fulfilled" ? sparkline.value : [];

        // 2. Extract price and change using the correct keys from your log (changePercentage)
        const currentPrice = parseFloat(quote.price || "0");
        const changePct = parseFloat(
          quote.changePercentage || quote.changesPercentage || "0",
        );

        // 3. Upsert to Assets Table
        const { error: dbError } = await supabase.from("assets").upsert(
          {
            user_id: userId,
            asset_address_or_id: `fmp:${ticker}`,
            provider: "fmp",
            type: profile ? (profile.isEtf ? "etf" : "stock") : "stock",
            name: profile?.companyName || quote.name || ticker,
            symbol: ticker,
            icon_url: profile?.image || null,
            quantity: quantity,
            current_price: currentPrice,
            price_usd: currentPrice,
            balance_usd: currentPrice * quantity,
            change_24h: changePct,
            sparkline: historyPoints,
            last_sync: new Date().toISOString(),
            status: "active",
          },
          { onConflict: "asset_address_or_id, user_id" },
        );

        if (dbError) throw dbError;

        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });

        return new Response(JSON.stringify({ success: true, name: ticker }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "update_prices": {
        if (!userId) throw new Error("userId is required");

        const { data: assets } = await supabase
          .from("assets")
          .select("id, symbol, quantity")
          .eq("user_id", userId)
          .eq("provider", "fmp");

        if (!assets || assets.length === 0)
          return new Response(JSON.stringify({ success: true }));

        const symbolsList = assets.map((a) => a.symbol).join(",");
        const quotes = await fmpStableFetch(
          "batch-quote",
          `symbols=${symbolsList}`,
        );

        // Update each asset one by one to ensure history is fetched for each
        const updatePromises = quotes.map(async (q) => {
          const asset = assets.find((a) => a.symbol === q.symbol);
          if (!asset) return;

          const history = await fetchPriceHistory(q.symbol);
          const currentPrice = parseFloat(q.price || "0");
          const changePct = parseFloat(
            q.changePercentage || q.changesPercentage || "0",
          );

          return supabase
            .from("assets")
            .update({
              current_price: currentPrice,
              price_usd: currentPrice,
              balance_usd: currentPrice * (asset.quantity || 0),
              change_24h: changePct,
              sparkline: history,
              last_sync: new Date().toISOString(),
            })
            .eq("id", asset.id);
        });

        await Promise.all(updatePromises);
        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });

        return new Response(
          JSON.stringify({ success: true, count: quotes.length }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      case "remove_asset": {
        if (!assetId) throw new Error("assetId is required");
        await supabase
          .from("assets")
          .delete()
          .eq("id", assetId)
          .eq("user_id", userId);
        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
        return new Response(JSON.stringify({ success: true }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      default:
        throw new Error(`Action ${actionName} not implemented`);
    }
  } catch (error) {
    console.error(`FMP Manager Error [${actionName}]:`, error.message);
    return new Response(
      JSON.stringify({ error: error.message, action: actionName }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

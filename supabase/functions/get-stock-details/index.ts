// Supabase Edge Function: get-stock-details
// Purpose: Provide a complete financial overview for a stock/ETF asset
// Features: Stable API (2025+) support, Dual-chart Fallback, and Detailed Debug Logging.
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

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

/**
 * Robust fetcher for FMP Stable API.
 * Uses query parameters (?symbol=) as required by the 2025 Stable version.
 */
async function fmpStableFetch(
  endpoint: string,
  ticker: string,
): Promise<any[]> {
  if (!FMP_API_KEY) throw new Error("FMP_API_KEY missing");

  const url = `${BASE_URL_STABLE}/${endpoint}?symbol=${ticker}&apikey=${FMP_API_KEY}`;
  const response = await fetch(url);
  const text = await response.text();

  console.log(`[FMP DEBUG] URL: ${endpoint}?symbol=${ticker}`);

  let data;
  try {
    data = JSON.parse(text);
  } catch (e) {
    if (text.includes("Premium")) throw new Error("FMP_PREMIUM_REQUIRED");
    return [];
  }

  if (!Array.isArray(data)) {
    console.error(
      `[FMP ERROR] Response for ${endpoint} is not an array:`,
      data,
    );
    return [];
  }
  return data;
}

/**
 * Intelligent Chart Fetcher
 * 1. Tries 1-hour intraday data (better for 24h view).
 * 2. If empty/blocked, falls back to EOD Light data (as per your documentation).
 */
async function fetchBestAvailableHistory(ticker: string): Promise<number[]> {
  try {
    // Attempt 1: Intraday 1hour
    console.log(`[DEBUG] Attempting Intraday Chart for ${ticker}...`);
    let history = await fmpStableFetch("historical-chart/1hour", ticker);

    // Attempt 2: Fallback to EOD Light (The one from your documentation)
    if (history.length === 0) {
      console.log(`[DEBUG] Falling back to EOD Light Chart for ${ticker}...`);
      history = await fmpStableFetch("historical-price-eod/light", ticker);
    }

    if (history.length === 0) return [];

    console.log(`[DEBUG] Raw History Point Keys:`, Object.keys(history[0]));

    // Map data points: Stable API uses 'price' for light charts or 'close' for intraday
    return history
      .slice(0, 24)
      .map((p: any) => {
        const val = p.price || p.close || 0;
        return parseFloat(val);
      })
      .reverse();
  } catch (e) {
    console.error(`[DEBUG] History Fetch Failed: ${e.message}`);
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
    const { symbol, userId } = payload;

    if (!symbol || !userId) throw new Error("Missing symbol or userId");
    const ticker = symbol.toUpperCase();
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    // 1. FETCH ALL DATA IN PARALLEL
    const [dbAsset, profileRes, quoteRes, priceHistory] = await Promise.all([
      supabase
        .from("assets")
        .select("quantity")
        .eq("user_id", userId)
        .eq("symbol", ticker)
        .maybeSingle(),
      fmpStableFetch("profile", ticker),
      fmpStableFetch("quote", ticker),
      fetchBestAvailableHistory(ticker),
    ]);

    // 2. VALIDATE CORE DATA
    if (quoteRes.length === 0) {
      throw new Error(`Quote data not found for ${ticker}`);
    }

    const quote = quoteRes[0];
    const profile = profileRes.length > 0 ? profileRes[0] : {};
    const quantity = dbAsset.data?.quantity || 0;

    // 3. MAPPING TO YOUR StockDetail MODEL
    const responseData = {
      symbol: ticker,
      name: profile.companyName || quote.name || ticker,
      currentPrice: parseFloat(quote.price || 0),
      // Use 'changePercentage' as confirmed in your previous log
      change24h: parseFloat(
        quote.changePercentage || quote.changesPercentage || 0,
      ),
      quantity: parseFloat(quantity),
      totalValueUsd: parseFloat(quote.price || 0) * parseFloat(quantity),

      marketStats: {
        peRatio: quote.pe ? parseFloat(quote.pe) : null,
        marketCap: quote.marketCap ? parseFloat(quote.marketCap) : null,
        week52High: quote.yearHigh ? parseFloat(quote.yearHigh) : null,
        week52Low: quote.yearLow ? parseFloat(quote.yearLow) : null,
        volume: quote.volume ? parseFloat(quote.volume) : null,
        eps: quote.eps ? parseFloat(quote.eps) : null,
      },

      diversification: {
        sector: profile.sector || "Other",
        industry: profile.industry || "Other",
        country: profile.country || "US",
        countryCode: profile.country || "US",
      },

      description:
        profile.description || "No description available for this asset.",

      // Matches the 'priceHistory' key in your AssetModel factory
      priceHistory: priceHistory,
    };

    console.log(
      `[DEBUG] Sending ${responseData.priceHistory.length} points to Flutter.`,
    );

    return new Response(JSON.stringify(responseData), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error(`[FATAL ERROR]:`, error.message);
    return new Response(
      JSON.stringify({ error: error.message, action: actionName }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

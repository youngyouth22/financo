// Supabase Edge Function: get-stock-details
// Purpose: Provide a complete financial overview for a stock/ETF asset
// Features: Stable API (2025+) support, Database quantity sync, and Detailed Market Stats.
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const FMP_API_KEY = Deno.env.get("FMP_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const BASE_URL_STABLE = "https://financialmodelingprep.com/stable";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ============================================================================
// HELPERS
// ============================================================================

async function fmpFetch(endpoint: string, params: string) {
  const url = `${BASE_URL_STABLE}/${endpoint}?${params}&apikey=${FMP_API_KEY}`;
  const response = await fetch(url);
  const data = await response.json();
  if (!Array.isArray(data)) return [];
  return data;
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { symbol, userId, timeframe = "1hour" } = await req.json();
    if (!symbol || !userId) throw new Error("Missing symbol or userId");
    
    const ticker = symbol.toUpperCase();
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    // 1. FETCH ALL DATA IN PARALLEL
    const [dbAsset, profileRes, quoteRes, historyRes] = await Promise.all([
      // A. Get User's specific quantity from Database
      supabase.from('assets').select('quantity').eq('user_id', userId).eq('symbol', ticker).maybeSingle(),
      // B. Fetch Corporate Profile
      fmpFetch("profile", `symbol=${ticker}`),
      // C. Fetch Live Market Quote (for PE, EPS, 52w high/low)
      fmpFetch("quote", `symbol=${ticker}`),
      // D. Fetch Historical Chart for Sparkline
      fmpFetch(`historical-chart/${timeframe}/${ticker}`, "")
    ]);

    if (quoteRes.length === 0) throw new Error(`Market data not found for ${ticker}`);

    const profile = profileRes[0] || {};
    const quote = quoteRes[0];
    const userQuantity = dbAsset.data?.quantity || 0;

    // 2. MAPPING TO YOUR FLUTTER StockDetail MODEL
    const responseData = {
      symbol: ticker,
      name: profile.companyName || quote.name || ticker,
      currentPrice: quote.price,
      change24h: quote.changePercentage || 0,
      quantity: userQuantity,
      totalValueUsd: quote.price * userQuantity,
      
      // Map Market Stats
      marketStats: {
        peRatio: quote.pe || null,
        marketCap: quote.marketCap || null,
        week52High: quote.yearHigh || null,
        week52Low: quote.yearLow || null,
        volume: quote.volume || null,
        avgVolume: quote.avgVolume || null,
        dividendYield: profile.lastDividend || null,
        eps: quote.eps || null,
      },

      // Map Diversification Data (Josh's Priority)
      diversification: {
        sector: profile.sector || "Other",
        industry: profile.industry || "Other",
        country: profile.country || "US",
        countryCode: profile.country || "US", // ISO Code for the flag
      },

      description: profile.description || "No description available for this asset.",
      
      // Map Price History (Sparkline) - Last 24 points
      priceHistory: historyRes.slice(0, 24).map((p: any) => parseFloat(p.close)).reverse(),
    };

    return new Response(JSON.stringify(responseData), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error(`[Stock Details Error]:`, error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
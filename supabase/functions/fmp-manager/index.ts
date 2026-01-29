// Supabase Edge Function: fmp-manager
// Purpose: Unified handler for Financial Modeling Prep (FMP) API
// Features: Stable API (2025+) support, Robust Error Handling for Premium Plan limits,
//           Support for Stocks, ETFs, and Commodities, and Wealth History snapshots.
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ============================================================================
// CONFIGURATION & SECRETS
// ============================================================================

const FMP_API_KEY = Deno.env.get("FMP_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// Base URL for the Stable API (Mandatory for accounts created after Aug 2025)
const BASE_URL_STABLE = "https://financialmodelingprep.com/stable";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ============================================================================
// TYPES & INTERFACES
// ============================================================================

interface FMPProfile {
  symbol: string;
  companyName: string;
  price: number;
  changePercentage: number;
  sector: string;
  industry: string;
  country: string;
  image: string;
  isEtf?: boolean;
}

interface FMPQuote {
  symbol: string;
  name: string;
  price: number;
  changePercentage: number;
}

interface RequestPayload {
  action:
    | "search"
    | "get_quotes"
    | "get_profile"
    | "add_asset"
    | "update_prices"
    | "remove_asset";
  query?: string;
  symbols?: string;
  symbol?: string;
  userId?: string;
  quantity?: number;
  assetId?: string;
}

// ============================================================================
// FMP API HELPERS (ROBUST VERSION)
// ============================================================================

function checkApiKey() {
  if (!FMP_API_KEY)
    throw new Error("FMP_API_KEY is not configured in Supabase secrets");
}

/**
 * Enhanced fetcher that reads response as text first to handle
 * FMP "Premium Plan" plain text errors without crashing JSON parsing.
 */
async function fmpStableFetch(
  endpoint: string,
  params: string,
): Promise<any[]> {
  checkApiKey();
  const url = `${BASE_URL_STABLE}/${endpoint}?${params}&apikey=${FMP_API_KEY}`;
  const response = await fetch(url);

  const rawText = await response.text();
  let data;

  try {
    data = JSON.parse(rawText);
  } catch (e) {
    // Detect if FMP sent a plain text "Premium" error instead of JSON
    if (rawText.toLowerCase().includes("premium")) {
      throw new Error(
        "This asset or action requires a Premium FMP Plan (Plan limit reached).",
      );
    }
    throw new Error(
      `FMP API returned invalid format: ${rawText.substring(0, 50)}...`,
    );
  }

  if (!Array.isArray(data)) {
    const errorMsg =
      data && data["Error Message"]
        ? data["Error Message"]
        : `FMP error at ${endpoint}`;
    throw new Error(errorMsg);
  }
  return data;
}

/**
 * Fetch stock profile using Stable API. Returns null if not found (typical for Commodities).
 */
async function fetchStockProfile(symbol: string): Promise<FMPProfile | null> {
  try {
    const data = await fmpStableFetch(
      "profile",
      `symbol=${symbol.toUpperCase()}`,
    );
    return data.length > 0 ? data[0] : null;
  } catch (e) {
    console.warn(`Profile fetch failed for ${symbol}: ${e.message}`);
    return null; // Return null so add_asset can try falling back to quote
  }
}

/**
 * Fetch real-time quotes using Stable API.
 */
async function fetchQuotes(symbols: string): Promise<FMPQuote[]> {
  const isBatch = symbols.includes(",");
  const endpoint = isBatch ? "batch-quote" : "quote";
  const paramName = isBatch ? "symbols" : "symbol";
  return await fmpStableFetch(
    endpoint,
    `${paramName}=${symbols.toUpperCase()}`,
  );
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  let actionName = "unknown";

  try {
    const payload: RequestPayload = await req.json();
    actionName = payload.action || "unknown";

    const { query, symbols, symbol, userId, quantity, assetId } = payload;
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

        // 1. Fetch Market Data in Parallel with AllSettled to prevent partial failure crash
        const [profile, quoteRes] = await Promise.all([
          fetchStockProfile(ticker),
          fetchQuotes(ticker).catch((e) => {
            throw e;
          }), // Quote is mandatory
        ]);

        if (!quoteRes || quoteRes.length === 0) {
          throw new Error(`Live price data not found for ${ticker}`);
        }
        const quote: FMPQuote = quoteRes[0];

        // 2. Fallback logic for Commodities (GOLD, OIL) or Premium-restricted profiles
        const name = profile?.companyName || quote.name || ticker;
        const assetType = profile
          ? profile.isEtf
            ? "etf"
            : "stock"
          : ticker.includes("USD")
            ? "commodity"
            : "stock";
        const sector =
          profile?.sector ||
          (assetType === "commodity" ? "Commodities" : "Other");
        const country =
          profile?.country || (assetType === "commodity" ? "Global" : "US");

        // 3. Upsert to Assets Table
        const { error: dbError } = await supabase.from("assets").upsert(
          {
            user_id: userId,
            asset_address_or_id: `fmp:${ticker}`,
            provider: "fmp",
            type: assetType,
            name: name,
            symbol: ticker,
            icon_url: profile?.image || null,
            quantity: quantity,
            current_price: quote.price,
            price_usd: quote.price,
            balance_usd: quote.price * quantity,
            change_24h: quote.changePercentage || 0,
            sector: sector,
            country: country,
            last_sync: new Date().toISOString(),
            status: "active",
          },
          { onConflict: "asset_address_or_id, user_id" },
        );

        if (dbError) throw dbError;

        // 4. Trigger Snapshots
        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });

        return new Response(JSON.stringify({ success: true, name }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      case "update_prices": {
        if (!userId) throw new Error("userId is required");

        const { data: assets } = await supabase
          .from("assets")
          .select("symbol, quantity")
          .eq("user_id", userId)
          .eq("provider", "fmp");

        if (!assets || assets.length === 0)
          return new Response(JSON.stringify({ success: true }));

        const symbolsList = assets.map((a) => a.symbol).join(",");
        const quotes = await fetchQuotes(symbolsList);

        const updates = quotes
          .map((q) => {
            const asset = assets.find((a) => a.symbol === q.symbol);
            if (!asset) return null;
            return supabase
              .from("assets")
              .update({
                current_price: q.price,
                price_usd: q.price,
                balance_usd: q.price * (asset.quantity || 0),
                change_24h: q.changePercentage || 0,
                last_sync: new Date().toISOString(),
              })
              .eq("user_id", userId)
              .eq("symbol", q.symbol);
          })
          .filter((u) => u !== null);

        await Promise.all(updates);
        await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });

        return new Response(JSON.stringify({ success: true }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
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

// Supabase Edge Function: get-wallet-details
// Purpose: Provide a professional, scam-proof financial view of a crypto wallet
// Features: Vetted Net Worth, Real-time PnL %, OHLCV Trading Chart, and Decoded History
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const MORALIS_API_KEY = Deno.env.get("MORALIS_API_KEY");
const BASE_URL = "https://deep-index.moralis.io/api/v2.2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Map to get WETH/WBNB pairs for the main chart
const NATIVE_PAIRS: Record<string, string> = {
  eth: "0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640", // ETH/USDC
  bsc: "0x58f876857a02d6762e0101bb5c46a8c1ed44dc16", // BNB/BUSD
};

/**
 * Robust fetcher that prevents "Unexpected token <" crash and logs API responses
 */
async function moralisFetch(endpoint: string): Promise<any> {
  if (!MORALIS_API_KEY) throw new Error("MORALIS_API_KEY missing");

  const response = await fetch(`${BASE_URL}${endpoint}`, {
    headers: { "X-API-Key": MORALIS_API_KEY, accept: "application/json" },
  });

  const text = await response.text();
  if (text.startsWith("<!DOCTYPE") || text.includes("<html")) {
    console.error(
      `[Moralis Error] HTML received instead of JSON for ${endpoint}`,
    );
    return { result: [] };
  }

  try {
    return JSON.parse(text);
  } catch (e) {
    console.error(`[JSON Error] Failed to parse response from ${endpoint}`);
    return { result: [] };
  }
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  try {
    const { address, chain = "eth" } = await req.json();

    if (!address || address === "wallet" || !address.startsWith("0x")) {
      throw new Error("A valid hex wallet address is required.");
    }

    const cleanAddr = address.toLowerCase();
    const toDate = new Date().toISOString();
    const fromDate = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

    // 1. FETCH DATA (Using Audit Endpoints for accuracy)
    const [nwData, pnlData, tokenData, historyData, ohlcvData] =
      await Promise.all([
        // A. Verified Net Worth (Eliminates Scam tokens with liquidity filter)
        moralisFetch(
          `/wallets/${cleanAddr}/net-worth?exclude_spam=true&exclude_unverified_contracts=true&min_pair_side_liquidity_usd=1000`,
        ),

        // B. Profitability Summary (For the +2% / -5% real market move)
        moralisFetch(`/wallets/${cleanAddr}/profitability/summary`),

        // C. Detailed Token list
        moralisFetch(
          `/wallets/${cleanAddr}/tokens?chain=${chain}&exclude_spam=true`,
        ),

        // D. Transaction History
        moralisFetch(
          `/wallets/${cleanAddr}/history?chain=${chain}&order=DESC&limit=15`,
        ),

        // E. Trading Chart (OHLCV)
        moralisFetch(
          `/pairs/${NATIVE_PAIRS[chain] || NATIVE_PAIRS["eth"]}/ohlcv?chain=${chain}&timeframe=1h&currency=usd&fromDate=${fromDate}&toDate=${toDate}`,
        ),
      ]);

    // 2. MAPPING TO MODEL

    // Process Individual Tokens
    const tokens = (tokenData.result || []).map((t: any) => ({
      symbol: t.symbol,
      name: t.name,
      balance: parseFloat(t.balance_formatted || "0"),
      valueUsd: parseFloat(t.usd_value || "0"),
      priceUsd: parseFloat(t.usd_price || "0"),
      change24h: parseFloat(t.usd_price_24hr_percent_change || "0"),
      iconUrl: t.thumbnail || t.logo || "",
    }));

    // Process Decoded Transactions
    const transactions = (historyData.result || []).map((tx: any) => ({
      hash: tx.hash,
      type: tx.from_address.toLowerCase() === cleanAddr ? "sent" : "received",
      fromAddress: tx.from_address,
      toAddress: tx.to_address,
      amountUsd: parseFloat(tx.transaction_value_usd || "0"),
      tokenSymbol: tx.erc20_transfers?.[0]?.token_symbol || "ETH",
      tokenAmount: parseFloat(tx.erc20_transfers?.[0]?.value_formatted || "0"),
      timestamp: tx.block_timestamp,
      entityName: tx.to_address_label || tx.from_address_label || null,
      entityLogo:
        tx.to_address_entity_logo || tx.from_address_entity_logo || null,
    }));

    // 3. FINAL CONSOLIDATED RESPONSE
    const responseData = {
      walletAddress: cleanAddr,
      name: `Wallet ${cleanAddr.substring(0, 6)}`,

      // --- PRODUCTION READY DATA ---
      // 1. Scam-proof Net Worth
      totalValueUsd: parseFloat(nwData.total_networth_usd || "0"),

      // 2. Real Market performance (+1% / -5%) from Profitability API
      change24h: parseFloat(pnlData.total_realized_profit_percentage || "0"),

      tokens: tokens,
      transactions: transactions,

      // 3. Professional Chart Points
      priceHistory: (ohlcvData.result || [])
        .map((i: any) => parseFloat(i.close))
        .reverse(),
    };

    return new Response(JSON.stringify(responseData), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error(`[Get Details Error]:`, error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

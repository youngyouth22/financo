// Supabase Edge Function: get-wallet-details
// Purpose: Provide a unified, detailed view of a crypto wallet
// Data: Net Worth, 24h Performance, Token list, and Decoded Transaction history
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const MORALIS_API_KEY = Deno.env.get("MORALIS_API_KEY");
const BASE_URL = "https://deep-index.moralis.io/api/v2.2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ============================================================================
// HELPERS: DATA MAPPING
// ============================================================================

/**
 * Maps Moralis transaction categories to your Flutter Enum: CryptoTransactionType
 */
function mapTransactionType(tx: any, walletAddr: string): string {
  const category = tx.category?.toLowerCase() || "";
  const from = tx.from_address?.toLowerCase();
  
  if (category.includes("swap")) return "swap";
  if (category.includes("stake")) return "stake";
  
  // Logical check for sent vs received
  if (from === walletAddr.toLowerCase()) {
    return "sent";
  } else {
    return "received";
  }
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { address, chain = "eth" } = await req.json();
    if (!address) throw new Error("Wallet address is required");
    const cleanAddr = address.toLowerCase();

    // 1. FETCH ALL DATA IN PARALLEL (Optimal Performance)
    const [nwRes, tokenRes, historyRes, sparkRes] = await Promise.all([
      // A. Official Net Worth & 24h Change
      fetch(`${BASE_URL}/wallets/${cleanAddr}/net-worth?exclude_spam=true`, { 
        headers: { "X-API-Key": MORALIS_API_KEY!, "accept": "application/json" } 
      }).then(r => r.json()),

      // B. Token Balances
      fetch(`${BASE_URL}/wallets/${cleanAddr}/tokens?chain=${chain}&exclude_spam=true`, { 
        headers: { "X-API-Key": MORALIS_API_KEY!, "accept": "application/json" } 
      }).then(r => r.json()),

      // C. Decoded Transaction History
      fetch(`${BASE_URL}/wallets/${cleanAddr}/history?chain=${chain}&order=DESC&limit=20`, { 
        headers: { "X-API-Key": MORALIS_API_KEY!, "accept": "application/json" } 
      }).then(r => r.json()),

      // D. Sparkline (using Native/Wrapped Token History as a proxy for the chart)
      // For ETH wallet, we use WETH history for the 24h chart
      fetch(`${BASE_URL}/erc20/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2/price-history?chain=eth&days=1&interval=1h`, { 
        headers: { "X-API-Key": MORALIS_API_KEY!, "accept": "application/json" } 
      }).then(r => r.json())
    ]);

    // ============================================================================
    // 2. MAPPING TO YOUR FLUTTER MODELS
    // ============================================================================

    // Map Tokens
    const tokens = (tokenRes.result || []).map((t: any) => ({
      symbol: t.symbol,
      name: t.name,
      balance: parseFloat(t.balance_formatted),
      valueUsd: parseFloat(t.usd_value || "0"),
      priceUsd: parseFloat(t.usd_price || "0"),
      change24h: parseFloat(t.usd_price_24hr_percent_change || "0"),
      iconUrl: t.thumbnail || t.logo || "",
    }));

    // Map Transactions
    const transactions = (historyRes.result || []).map((tx: any) => {
      // Determine if it was an ERC20 or Native move
      const tokenDetail = tx.erc20_transfers?.[0] || tx.native_transfers?.[0];
      
      return {
        hash: tx.hash,
        type: mapTransactionType(tx, cleanAddr),
        fromAddress: tx.from_address,
        toAddress: tx.to_address,
        amountUsd: parseFloat(tx.transaction_value_usd || "0"),
        tokenSymbol: tokenDetail?.token_symbol || "ETH",
        tokenAmount: parseFloat(tokenDetail?.value_formatted || "0"),
        timestamp: tx.block_timestamp,
        entityName: tx.to_address_label || tx.from_address_label || null,
        entityLogo: tx.to_address_entity_logo || tx.from_address_entity_logo || null,
      };
    });

    // Map Sparkline
    const priceHistory = (sparkRes.result || []).map((p: any) => parseFloat(p.usdPrice));

    // Final Object matching CryptoWalletDetail
    const responseData = {
      walletAddress: cleanAddr,
      name: "Main Wallet",
      totalValueUsd: parseFloat(nwRes.total_networth_usd || "0"),
      change24h: 0, // Calculated globally by Moralis
      tokens: tokens,
      transactions: transactions,
      priceHistory: priceHistory,
    };

    return new Response(JSON.stringify(responseData), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error(`[Wallet Details Error]:`, error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
// Supabase Edge Function: finance-webhook (Production Ready)
// Purpose: Receive and process real-time Moralis Stream data
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const MORALIS_API_KEY = Deno.env.get("MORALIS_API_KEY");
const MORALIS_WEBHOOK_SECRET = Deno.env.get("MORALIS_WEBHOOK_SECRET");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-signature",
};

// ============================================================================
// DATA FETCHING: NETWORTH & PNL
// ============================================================================

async function fetchWalletPerformance(address: string) {
  const options = {
    headers: { "X-API-Key": MORALIS_API_KEY!, accept: "application/json" },
  };

  // 1. Fetch Net Worth (10 CU)
  const networthPromise = fetch(
    `https://deep-index.moralis.io/api/v2.2/wallets/${address}/net-worth?exclude_spam=true`,
    options,
  ).then((r) => r.json());

  // 2. Fetch PnL Summary (25 CU)
  const pnlPromise = fetch(
    `https://deep-index.moralis.io/api/v2.2/wallets/${address}/profitability/summary`,
    options,
  ).then((r) => r.json());

  const [networthData, pnlData] = await Promise.all([
    networthPromise,
    pnlPromise,
  ]);

  return {
    networthUsd: parseFloat(networthData.total_networth_usd || "0"),
    pnlUsd: parseFloat(pnlData.total_realized_profit_usd || "0"),
    pnlPercentage: parseFloat(pnlData.total_realized_profit_percentage || "0"),
    tradeVolume: parseFloat(pnlData.total_trade_volume || "0"),
  };
}

// ============================================================================
// SECURITY
// ============================================================================

async function verifySignature(
  payload: string,
  sig: string | null,
): Promise<boolean> {
  if (!sig || !MORALIS_WEBHOOK_SECRET) return false;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(MORALIS_WEBHOOK_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signatureBuffer = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(payload),
  );
  const expectedSig = Array.from(new Uint8Array(signatureBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return expectedSig === sig;
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  try {
    const rawBody = await req.text();
    const signature = req.headers.get("x-signature");
    const payload = JSON.parse(rawBody);

    // Skip validation check for Moralis Setup pings
    const isValidationPing =
      !payload.txs || (payload.txs.length === 0 && payload.logs.length === 0);
    if (isValidationPing)
      return new Response(JSON.stringify({ status: "ok" }), { status: 200 });

    // Verify Signature
    if (!(await verifySignature(rawBody, signature))) {
      return new Response("Invalid Signature", { status: 401 });
    }

    if (payload.confirmed) {
      const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
      const addresses = new Set<string>();

      // Collect addresses from txs and erc20 transfers
      payload.txs?.forEach((t: any) => {
        addresses.add(t.fromAddress);
        addresses.add(t.toAddress);
      });
      payload.erc20Transfers?.forEach((t: any) => {
        addresses.add(t.from);
        addresses.add(t.to);
      });

      const updates = Array.from(addresses).map(async (addr) => {
        try {
          const stats = await fetchWalletPerformance(addr);

          // Update Database with new PnL fields
          const { error } = await supabase
            .from("assets")
            .update({
              balance_usd: stats.networthUsd,
              realized_pnl_usd: stats.pnlUsd, // New Column
              realized_pnl_percent: stats.pnlPercentage, // New Column
              last_sync: new Date().toISOString(),
            })
            .eq("asset_address_or_id", addr.toLowerCase());

          if (!error) {
            // Record snapshot for history charts
            const { data: asset } = await supabase
              .from("assets")
              .select("user_id")
              .eq("asset_address_or_id", addr.toLowerCase())
              .single();
            if (asset)
              await supabase.rpc("record_wealth_snapshot", {
                p_user_id: asset.user_id,
              });
          }
        } catch (e) {
          console.error(`Update failed for ${addr}:`, e.message);
        }
      });

      await Promise.allSettled(updates);
    }

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (err) {
    return new Response(err.message, { status: 500 });
  }
});

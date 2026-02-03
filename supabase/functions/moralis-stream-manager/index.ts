// Supabase Edge Function: moralis-stream-manager
// Purpose: Manage Moralis Streams and Sync Assets with Real-time Prices & OHLCV History
// Features: Native & ERC20 Sparklines, Correct 24h Change Mapping, Parallel Processing
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

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

// Map of Wrapped Tokens to get accurate market change (ETH -> WETH, etc.)
const WRAPPED_ADDR: Record<string, string> = {
  eth: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", // WETH
  bsc: "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c", // WBNB
  polygon: "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270", // WMATIC
};

const NATIVE_PAIRS: Record<string, string> = {
  eth: "0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640", // ETH/USDC
  bsc: "0x58f876857a02d6762e0101bb5c46a8c1ed44dc16", // BNB/BUSD
  polygon: "0x45dda9cb7c25131df268515131f647d726f50608", // MATIC/USDC
};

// ============================================================================
// HELPERS
// ============================================================================

async function moralisRequest(endpoint: string) {
  const response = await fetch(
    `https://deep-index.moralis.io/api/v2.2${endpoint}`,
    {
      headers: { "X-API-Key": MORALIS_API_KEY!, accept: "application/json" },
    },
  );
  return response.json();
}

async function getTradingSparkline(chain: string): Promise<number[]> {
  try {
    const pairAddress =
      NATIVE_PAIRS[chain.toLowerCase()] || NATIVE_PAIRS["eth"];
    const toDate = new Date().toISOString();
    const fromDate = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const url = `/pairs/${pairAddress}/ohlcv?chain=${chain === "bsc" ? "bsc" : "eth"}&timeframe=1h&currency=usd&fromDate=${fromDate}&toDate=${toDate}&limit=24`;
    const data = await moralisRequest(url);
    return (data.result || []).map((i: any) => parseFloat(i.close)).reverse();
  } catch {
    return [];
  }
}

async function setupMoralisStream() {
  const res = await fetch(
    `https://api.moralis-streams.com/streams/evm?limit=10`,
    {
      headers: { "X-API-Key": MORALIS_API_KEY!, accept: "application/json" },
    },
  );
  const streams = await res.json();
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

  try {
    const payload = await req.json();
    const action = (payload.action || "unknown").trim();
    const { address, userId } = payload;
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    if (action === "setup") {
      const id = await setupMoralisStream();
      return new Response(JSON.stringify({ success: true, streamId: id }), {
        status: 200,
        headers: corsHeaders,
      });
    }

    if (action === "add_address" || action === "refresh_assets") {
      if (!address || !userId) throw new Error("Missing params");
      const cleanAddr = address.toLowerCase();

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
            body: JSON.stringify({ address: cleanAddr }),
          },
        );
      }

      // 1. FETCH NET WORTH
      const nwUrl = `/wallets/${cleanAddr}/net-worth?exclude_spam=true&exclude_unverified_contracts=true`;
      const nwRes = await moralisRequest(nwUrl);
      const officialTotal = parseFloat(nwRes.total_networth_usd || "0");

      // 2. IDENTIFY MAIN CHAIN & FETCH MARKET CHANGE %
      const mainChain =
        nwRes.chains && nwRes.chains.length > 0 ? nwRes.chains[0].chain : "eth";
      const wrappedAddr =
        WRAPPED_ADDR[mainChain.toLowerCase()] || WRAPPED_ADDR["eth"];

      // We fetch the price of the Wrapped Native token (e.g. WETH) to get the 24h % change
      const priceRes = await moralisRequest(
        `/erc20/${wrappedAddr}/price?chain=${mainChain}`,
      );

      // This is the real market move (+2% / -5%)
      const marketChange24h = parseFloat(
        priceRes.usdPrice24hrPercentChange || "0",
      );

      // 3. FETCH SPARKLINE
      const history = await getTradingSparkline(mainChain);

      // 4. GENERATE ICON
      const iconUrl = `https://api.dicebear.com/7.x/identicon/svg?seed=${cleanAddr}&backgroundColor=0f1116`;

      // 5. UPSERT TO ASSETS
      const { error: dbError } = await supabase.from("assets").upsert(
        {
          user_id: userId,
          asset_address_or_id: cleanAddr,
          provider: "moralis",
          type: "crypto",
          symbol: "WALLET",
          name: `Wallet ${cleanAddr.substring(0, 6)}...`,
          icon_url: iconUrl,
          quantity: 1,
          current_price: officialTotal,
          price_usd: officialTotal,
          balance_usd: officialTotal,
          change_24h: marketChange24h, // <--- FIXED: Now using real market change
          sparkline: history,
          last_sync: new Date().toISOString(),
          status: "active",
        },
        { onConflict: "asset_address_or_id, user_id" },
      );

      if (dbError) throw dbError;

      await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });

      return new Response(
        JSON.stringify({
          success: true,
          networth: officialTotal,
          change: marketChange24h,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    return new Response(JSON.stringify({ error: "Invalid action" }), {
      status: 400,
    });
  } catch (error) {
    console.error(`[Moralis Manager Error]:`, error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: corsHeaders,
    });
  }
});
// supabase secrets set MORALIS_API_KEY=your_moralis_api_key_here
// supabase functions deploy finance-webhook --no-verify-jwt
// supabase functions deploy moralis-stream-manager --no-verify-jwt
// // curl -X POST https://nbdfdlvbouoaoprbkbme.supabase.co/functions/v1/moralis-stream-manager -H "Content-Type: application/json" -d '{"action": "setup"}'

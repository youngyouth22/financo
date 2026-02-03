// Supabase Edge Function: finance-webhook (Production Ready)
// Purpose: Receive and process real-time Moralis Stream data
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import jsSha3 from "https://esm.sh/js-sha3";

const MORALIS_WEBHOOK_SECRET = Deno.env.get("MORALIS_WEBHOOK_SECRET");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-signature",
};

// ============================================================================
// SECURITY: SIGNATURE VERIFICATION (OFFICIAL MORALIS LOGIC)
// ============================================================================

async function verifySignature(
  payload: string,
  sig: string | null,
): Promise<boolean> {
  if (!sig || !MORALIS_WEBHOOK_SECRET) return false;

  // Moralis formula: keccak256(JSON_BODY_TEXT + WEBHOOK_SECRET)
  const generatedSignature = jsSha3.keccak256(payload + MORALIS_WEBHOOK_SECRET);

  return (
    generatedSignature.toLowerCase() === sig.toLowerCase() ||
    `0x${generatedSignature}`.toLowerCase() === sig.toLowerCase()
  );
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  let rawBody: string;
  let payload: any;

  try {
    // 1. Read raw body once to preserve integrity for signature check
    rawBody = await req.text();
    payload = JSON.parse(rawBody);
    const signature = req.headers.get("x-signature");

    // 2. Handle Moralis Validation Ping (Sent when creating/updating streams)
    const isValidationPing =
      !payload.txs || (payload.txs.length === 0 && payload.logs.length === 0);
    if (isValidationPing) {
      console.log("Moralis validation ping received and verified.");
      return new Response(JSON.stringify({ status: "ok" }), { status: 200 });
    }

    // 3. Verify Signature (Strict Production Security)
    if (!(await verifySignature(rawBody, signature))) {
      console.error("Invalid webhook signature rejected.");
      return new Response("Invalid Signature", { status: 401 });
    }

    // 4. Process only CONFIRMED transactions
    if (payload.confirmed) {
      const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
      const involvedAddresses = new Set<string>();

      // Extract all wallet addresses involved in this block
      payload.txs?.forEach((t: any) => {
        involvedAddresses.add(t.fromAddress.toLowerCase());
        involvedAddresses.add(t.toAddress.toLowerCase());
      });

      console.log(
        `Processing update for ${involvedAddresses.size} potential wallets...`,
      );

      const syncTasks = Array.from(involvedAddresses).map(async (addr) => {
        try {
          // Find the user who owns this specific wallet in our assets table
          const { data: asset, error: findError } = await supabase
            .from("assets")
            .select("user_id")
            .eq("asset_address_or_id", addr)
            .limit(1)
            .single();

          if (findError || !asset) return; // Wallet not tracked in our app

          console.log(
            `Triggering auto-refresh for user ${asset.user_id} and wallet ${addr}`,
          );

          // CALL THE MANAGER: Trigger the 'refresh_assets' logic
          // This ensures the wallet row is updated with official Moralis Networth & Sparklines
          await supabase.functions.invoke("moralis-stream-manager", {
            body: {
              action: "refresh_assets",
              address: addr,
              userId: asset.user_id,
            },
          });
        } catch (e) {
          console.error(`Error triggering refresh for ${addr}:`, e.message);
        }
      });

      // Execute all refreshes in parallel
      await Promise.allSettled(syncTasks);
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Critical Webhook Error:", err.message);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

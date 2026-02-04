// Supabase Edge Function: get-manual-asset-details
// Purpose: Aggregates manual asset data using the new asset_payouts table and summary functions
// Features: Real-time payment history, summary stats, and RRULE support
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function mapCategory(type: string): string {
  const mapping: Record<string, string> = {
    real_estate: "realEstate",
    investment: "privateEquity",
    commodity: "commodity",
    collectible: "collectible",
    liability: "loan",
    cash: "cash",
  };
  return mapping[type] || "other";
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  try {
    const { assetId, userId } = await req.json();
    if (!assetId || !userId) throw new Error("Missing assetId or userId");

    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    // 1. FETCH ASSET & SUMMARY DATA
    // We use the helper function created in the migration
    const { data: summary, error: summaryError } = await supabase.rpc(
      "get_asset_payout_summary",
      { p_asset_id: assetId },
    );

    const { data: asset, error: assetError } = await supabase
      .from("assets")
      .select("*")
      .eq("id", assetId)
      .single();

    if (assetError || !asset) throw new Error("Asset not found");

    const stats = summary && summary.length > 0 ? summary[0] : null;

    // 2. FETCH FUTURE SCHEDULE (from asset_reminders)
    const { data: reminders } = await supabase
      .from("asset_reminders")
      .select("*")
      .eq("asset_id", assetId)
      .order("next_event_date", { ascending: true });

    // 3. FETCH ACTUAL PAYOUT HISTORY (from the new asset_payouts table)
    const { data: payouts } = await supabase
      .from("asset_payouts")
      .select("*")
      .eq("asset_id", assetId)
      .order("payout_date", { ascending: false });

    // 4. MAP TO AMORTIZATION MODEL
    let rollingBalance =
      stats?.total_expected || parseFloat(asset.price_usd || "0");
    const amortizationSchedule = (reminders || []).map((r, index) => {
      // Logic: Subtract expected amount from rolling balance
      rollingBalance = Math.max(
        0,
        rollingBalance - parseFloat(r.amount_expected),
      );
      return {
        paymentNumber: index + 1,
        dueDate: r.next_event_date,
        principalAmount: parseFloat(r.amount_expected) * 0.9,
        interestAmount: parseFloat(r.amount_expected) * 0.1,
        totalPayment: parseFloat(r.amount_expected),
        remainingBalance: rollingBalance,
        isPaid: r.is_completed,
      };
    });

    // 5. FINAL RESPONSE (Perfect match for Flutter Models)
    const responseData = {
      assetId: asset.id,
      name: asset.name,
      category: mapCategory(asset.type),
      currentValue:
        stats?.remaining_balance || parseFloat(asset.balance_usd || "0"),
      purchasePrice:
        stats?.total_expected || parseFloat(asset.price_usd || "0"),
      purchaseDate: asset.created_at,
      currency: asset.symbol || "USD",

      metadata: {
        ...asset.metadata,
        totalReceived: stats?.total_received || 0,
        payoutCount: stats?.payout_count || 0,
        lastPayoutDate: stats?.last_payout_date || null,
      },

      amortizationSchedule: amortizationSchedule,
      rruleString: reminders?.[0]?.rrule_expression || null,

      // We use the payout history amounts for the valueHistory chart
      valueHistory:
        payouts && payouts.length > 0
          ? payouts.map((p) => parseFloat(p.amount)).reverse()
          : [parseFloat(asset.balance_usd || "0")],
    };

    return new Response(JSON.stringify(responseData), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

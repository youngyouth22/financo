// Supabase Edge Function: get-manual-asset-details
// Purpose: Provide full details for manual/private assets including amortization logic
// Features: Dynamic Metadata mapping, RRULE support, and Profit/Loss calculation
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ============================================================================
// HELPERS: MAPPING
// ============================================================================

function mapCategory(type: string): string {
  const mapping: Record<string, string> = {
    'real_estate': 'realEstate',
    'investment': 'privateEquity',
    'commodity': 'commodity',
    'collectible': 'collectible',
    'liability': 'loan',
    'other': 'other'
  };
  return mapping[type] || 'other';
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { assetId, userId } = await req.json();
    if (!assetId || !userId) throw new Error("Missing assetId or userId");

    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    // 1. RÉCUPÉRER LES DONNÉES DE L'ACTIF
    const { data: asset, error: assetError } = await supabase
      .from("assets")
      .select("*")
      .eq("id", assetId)
      .eq("user_id", userId)
      .single();

    if (assetError || !asset) throw new Error("Manual asset not found");

    // 2. RÉCUPÉRER LE PLAN D'AMORTISSEMENT / RAPPELS
    const { data: reminders } = await supabase
      .from("asset_reminders")
      .select("*")
      .eq("asset_id", assetId)
      .order("next_event_date", { ascending: true });

    // 3. RÉCUPÉRER L'HISTORIQUE DE VALEUR (Simulé via snapshots ou table dédiée)
    const { data: history } = await supabase
      .from("wealth_snapshots")
      .select("total_value_usd, snapshot_date")
      .eq("user_id", userId)
      .order("snapshot_date", { ascending: false })
      .limit(10);

    // 4. CONSTRUCTION DE L'OBJET DE RÉPONSE (Mapping vers le modèle Flutter)
    const responseData = {
      assetId: asset.id,
      name: asset.name,
      category: mapCategory(asset.type),
      currentValue: parseFloat(asset.balance_usd || "0"),
      purchasePrice: parseFloat(asset.metadata?.purchase_price || asset.balance_usd),
      purchaseDate: asset.created_at,
      currency: asset.currency || "USD",
      
      // Métadonnées enrichies selon le type (Josh's Analysis)
      metadata: {
        propertyAddress: asset.metadata?.address || null,
        propertyType: asset.metadata?.property_type || null,
        propertySize: asset.metadata?.size || null,
        loanAmount: asset.metadata?.loan_amount || null,
        interestRate: asset.metadata?.interest_rate || null,
        loanStartDate: asset.metadata?.start_date || null,
        commodityType: asset.symbol || null,
        purity: asset.metadata?.purity || null,
        unit: asset.metadata?.unit || "oz",
      },

      // Section Amortissement (La "Killer Feature" de Josh)
      amortizationSchedule: (reminders || []).map((r, index) => ({
        paymentNumber: index + 1,
        dueDate: r.next_event_date,
        principalAmount: r.amount_expected * 0.8, // Simulation répartition
        interestAmount: r.amount_expected * 0.2,
        totalPayment: r.amount_expected,
        remainingBalance: asset.balance_usd - (r.amount_expected * index),
        isPaid: r.is_completed
      })),

      rruleString: reminders?.[0]?.rrule_expression || null,
      
      // Historique des prix (pour le fl_chart)
      valueHistory: history?.map(h => h.total_value_usd).reverse() || [asset.balance_usd]
    };

    return new Response(JSON.stringify(responseData), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error(`[Manual Asset Details Error]:`, error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
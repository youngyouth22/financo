// Supabase Edge Function: get-bank-details
// Features: Fetch real-time balances for ALL accounts in a bank, Transaction history, and Net Worth breakdown
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const PLAID_CLIENT_ID = Deno.env.get("PLAID_CLIENT_ID");
const PLAID_SECRET = Deno.env.get("PLAID_SECRET");
const PLAID_ENV = Deno.env.get("PLAID_ENV") || "sandbox";
const ENCRYPTION_KEY = Deno.env.get("ENCRYPTION_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// --- CRYPTO HELPER ---
async function decryptToken(encryptedToken: string, iv: string) {
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(ENCRYPTION_KEY), "AES-GCM", false, ["decrypt"]);
  const decrypted = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: Uint8Array.from(atob(iv), (c) => c.charCodeAt(0)) },
    key,
    Uint8Array.from(atob(encryptedToken), (c) => c.charCodeAt(0)),
  );
  return new TextDecoder().decode(decrypted);
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const payload = await req.json();
    console.log("[Log] Request for bank details:", JSON.stringify(payload));

    let rawItemId = payload.itemId || payload.item_id;
    const userId = payload.userId || payload.user_id;

    if (!rawItemId || !userId) throw new Error("Missing itemId or userId");

    // Extraction de l'ID Plaid réel (on retire le préfixe plaid: si présent)
    const finalPlaidItemId = rawItemId.startsWith("plaid:") ? rawItemId.split(":")[1] : rawItemId;

    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    // 1. Récupérer le token chiffré
    const { data: connection, error: connError } = await supabase
      .from("plaid_items")
      .select("access_token_encrypted, iv")
      .eq("item_id", finalPlaidItemId)
      .eq("user_id", userId)
      .single();

    if (connError || !connection) throw new Error("Bank connection not found.");

    // 2. Décryptage
    const realAccessToken = await decryptToken(connection.access_token_encrypted, connection.iv);

    // 3. Appels Plaid (Balances de TOUS les comptes + Transactions)
    const plaidBaseUrl = `https://${PLAID_ENV}.plaid.com`;
    const today = new Date().toISOString().split("T")[0];
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split("T")[0];

    const [balanceRes, transRes] = await Promise.all([
      fetch(`${plaidBaseUrl}/accounts/balance/get`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          client_id: PLAID_CLIENT_ID,
          secret: PLAID_SECRET,
          access_token: realAccessToken,
        }),
      }).then((r) => r.json()),
      fetch(`${plaidBaseUrl}/transactions/get`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          client_id: PLAID_CLIENT_ID,
          secret: PLAID_SECRET,
          access_token: realAccessToken,
          start_date: thirtyDaysAgo,
          end_date: today,
          options: { count: 30 },
        }),
      }).then((r) => r.json()),
    ]);

    if (balanceRes.error_code) throw new Error(`Plaid Error: ${balanceRes.error_message}`);

    // 4. Calcul du Net Worth Global et mapping des comptes
    let totalNetWorth = 0;
    const accounts = balanceRes.accounts.map((acc: any) => {
      const balance = acc.balances.current || 0;
      const isDebt = acc.type === "credit" || acc.type === "loan";
      
      if (isDebt) totalNetWorth -= Math.abs(balance);
      else totalNetWorth += balance;

      return {
        accountId: acc.account_id,
        name: acc.name,
        officialName: acc.official_name || acc.name,
        mask: acc.mask || "0000",
        type: acc.type,
        subtype: acc.subtype,
        balance: balance,
        isDebt: isDebt,
        currency: acc.balances.iso_currency_code || "USD"
      };
    });

    // 5. Historique de balance (Somme agrégée de tous les comptes)
    let runningNetWorth = totalNetWorth;
    const history = [runningNetWorth];
    (transRes.transactions || []).forEach((t: any) => {
      // Si c'est une dépense (montant positif dans Plaid), on l'ajoute pour remonter le temps
      runningNetWorth += t.amount;
      history.push(runningNetWorth);
    });

    // 6. Réponse complète pour Flutter
    return new Response(
      JSON.stringify({
        institutionName: payload.institutionName || "My Bank",
        totalNetWorth: totalNetWorth,
        currency: accounts[0]?.currency || "USD",
        accountCount: accounts.length,
        // Liste de TOUS les comptes pour ton UI (cartes de crédit, épargne, etc.)
        accounts: accounts,
        // Liste des transactions récentes
        transactions: (transRes.transactions || []).map((t: any) => ({
          transactionId: t.transaction_id,
          name: t.name,
          merchant: t.merchant_name || t.name,
          amount: t.amount,
          date: t.date,
          category: t.category?.[0] || "General",
          pending: t.pending,
        })),
        // Graphique combiné de la banque
        balanceHistory: history.reverse(),
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error(`[Execution Error]: ${error.message}`);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
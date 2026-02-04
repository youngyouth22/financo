// Supabase Edge Function: get-bank-details
// Features: AES-GCM Decryption, Plaid Real-time Balance, and Transaction History
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
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// --- CRYPTO HELPER ---
async function decryptToken(encryptedToken: string, iv: string) {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(ENCRYPTION_KEY),
    "AES-GCM",
    false,
    ["decrypt"],
  );
  const decrypted = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: Uint8Array.from(atob(iv), (c) => c.charCodeAt(0)) },
    key,
    Uint8Array.from(atob(encryptedToken), (c) => c.charCodeAt(0)),
  );
  return new TextDecoder().decode(decrypted);
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: corsHeaders });

  try {
    const payload = await req.json();
    console.log("[Log] Payload received:", JSON.stringify(payload));

    let rawItemId = payload.itemId || payload.item_id;
    let providedAccountId = payload.accountId || payload.account_id;
    const userId = payload.userId || payload.user_id;

    if (!rawItemId || !userId) throw new Error("Missing itemId or userId");

    // ==========================================================
    // LOGIQUE D'EXTRACTION CRITIQUE (FIX POUR L'ERREUR 400)
    // ==========================================================
    let finalPlaidItemId = rawItemId;
    let finalPlaidAccountId = providedAccountId;

    // Si rawItemId est au format "plaid:item_id:account_id"
    if (rawItemId.startsWith("plaid:")) {
      const parts = rawItemId.split(":");
      finalPlaidItemId = parts[1]; // Le vrai Item ID de Plaid
      // Priorité ABSOLUE au 3ème segment du composite ID car c'est le vrai ID Plaid
      if (parts[2]) {
        finalPlaidAccountId = parts[2];
        console.log(
          `[Log] Extracted real Plaid Account ID: ${finalPlaidAccountId}`,
        );
      }
    }

    if (!finalPlaidAccountId || finalPlaidAccountId.includes("-")) {
      // Si l'ID contient des tirets, c'est probablement un UUID de base de données, pas un ID Plaid.
      console.warn(
        "[Warning] The accountId looks like a Database UUID, this might fail Plaid API.",
      );
    }

    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    // 1. Fetch connection using the extracted Item ID
    const { data: connection, error: connError } = await supabase
      .from("plaid_items")
      .select("access_token_encrypted, iv")
      .eq("item_id", finalPlaidItemId)
      .eq("user_id", userId)
      .single();

    if (connError || !connection) {
      throw new Error(`Connection not found for Item ID: ${finalPlaidItemId}`);
    }

    // 2. Decrypt
    const realAccessToken = await decryptToken(
      connection.access_token_encrypted,
      connection.iv,
    );

    // 3. Plaid API calls
    const plaidBaseUrl = `https://${PLAID_ENV}.plaid.com`;
    const today = new Date().toISOString().split("T")[0];
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
      .toISOString()
      .split("T")[0];

    console.log(`[Log] Requesting Plaid for account: ${finalPlaidAccountId}`);

    const [balanceRes, transRes] = await Promise.all([
      fetch(`${plaidBaseUrl}/accounts/balance/get`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          client_id: PLAID_CLIENT_ID,
          secret: PLAID_SECRET,
          access_token: realAccessToken,
          options: { account_ids: [finalPlaidAccountId] }, // Doit être l'ID Plaid
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
          options: { account_ids: [finalPlaidAccountId], count: 20 },
        }),
      }).then((r) => r.json()),
    ]);

    if (balanceRes.error_code)
      throw new Error(`Plaid Error: ${balanceRes.error_message}`);

    const account = balanceRes.accounts?.[0];
    if (!account) throw new Error("Account not found in Plaid response");

    // 4. Map Balance History
    let current = account.balances.current;
    const history = [current];
    (transRes.transactions || []).forEach((t: any) => {
      current += t.amount;
      history.push(current);
    });

    return new Response(
      JSON.stringify({
        accountId: account.account_id,
        name: account.name,
        accountMask: `**** ${account.mask || "0000"}`,
        currentBalance: account.balances.current,
        currency: account.balances.iso_currency_code || "USD",
        transactions: (transRes.transactions || []).map((t: any) => ({
          transactionId: t.transaction_id,
          name: t.name,
          amount: t.amount,
          date: t.date,
          logoUrl: t.personal_finance_category_icon_url || null,
        })),
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

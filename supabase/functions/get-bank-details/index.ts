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
    console.log("Received payload:", JSON.stringify(payload));

    // Utilisation de noms de clés flexibles (camelCase ou snake_case)
    const itemId = payload.itemId || payload.item_id;
    const accountId = payload.accountId || payload.account_id;
    const userId = payload.userId || payload.user_id;

    if (!itemId || !accountId || !userId) {
      throw new Error(
        `Missing parameters. Received: itemId=${itemId}, accountId=${accountId}, userId=${userId}`,
      );
    }

    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    // 1. Fetch connection
    const { data: connection, error: connError } = await supabase
      .from("bank_connections")
      .select("access_token, iv, institution_name")
      .eq("item_id", itemId)
      .eq("user_id", userId)
      .single();

    if (connError || !connection)
      throw new Error("Bank connection not found in database");

    // 2. Decrypt
    const realAccessToken = await decryptToken(
      connection.access_token,
      connection.iv,
    );

    // 3. Plaid Calls
    const today = new Date().toISOString().split("T")[0];
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
      .toISOString()
      .split("T")[0];

    const [balanceRes, transRes] = await Promise.all([
      fetch(`https://${PLAID_ENV}.plaid.com/accounts/balance/get`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          client_id: PLAID_CLIENT_ID,
          secret: PLAID_SECRET,
          access_token: realAccessToken,
          options: { account_ids: [accountId] },
        }),
      }).then((r) => r.json()),
      fetch(`https://${PLAID_ENV}.plaid.com/transactions/get`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          client_id: PLAID_CLIENT_ID,
          secret: PLAID_SECRET,
          access_token: realAccessToken,
          start_date: thirtyDaysAgo,
          end_date: today,
          options: { account_ids: [accountId], count: 15 },
        }),
      }).then((r) => r.json()),
    ]);

    const account = balanceRes.accounts?.[0];
    if (!account) throw new Error("Plaid could not find this specific account");

    // 4. Map History
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
        institutionName: connection.institution_name,
        accountMask: `**** ${account.mask || "0000"}`,
        accountType: account.type,
        accountSubtype: account.subtype,
        currentBalance: account.balances.current,
        availableBalance:
          account.balances.available || account.balances.current,
        creditLimit: account.balances.limit || null,
        currency: account.balances.iso_currency_code || "USD",
        transactions: (transRes.transactions || []).map((t: any) => ({
          transactionId: t.transaction_id,
          name: t.name,
          merchantName: t.merchant_name,
          amount: t.amount,
          category: t.category?.[0] || "General",
          date: t.date,
          isPending: t.pending,
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
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: corsHeaders,
    });
  }
});

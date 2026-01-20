// Supabase Edge Function: finance-webhook
// Purpose: Handle Moralis Streams webhooks for real-time crypto asset updates
// Author: Finance Realtime Engine
// Date: 2026-01-20

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ============================================================================
// TYPES & INTERFACES
// ============================================================================

interface MoralisWebhookPayload {
  confirmed: boolean;
  chainId: string;
  abi: any[];
  streamId: string;
  tag: string;
  retries: number;
  block: {
    number: string;
    hash: string;
    timestamp: string;
  };
  logs: any[];
  txs: any[];
  txsInternal: any[];
  erc20Transfers: any[];
  erc20Approvals: any[];
  nftTransfers: any[];
  nativeBalances?: Array<{
    address: string;
    balance: string;
  }>;
}

interface MoralisNetworthResponse {
  total_networth_usd: string;
  chains: Array<{
    chain: string;
    native_balance: string;
    native_balance_formatted: string;
    native_balance_usd: string;
    token_balance_usd: string;
    networth_usd: string;
  }>;
}

// ============================================================================
// CONFIGURATION
// ============================================================================

const MORALIS_API_KEY = Deno.env.get("MORALIS_API_KEY");
const MORALIS_WEBHOOK_SECRET = Deno.env.get("MORALIS_WEBHOOK_SECRET");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Verify Moralis webhook signature
 * @param payload - The webhook payload
 * @param signature - The signature from headers
 * @returns boolean indicating if signature is valid
 */
async function verifyMoralisSignature(
  payload: string,
  signature: string | null
): Promise<boolean> {
  if (!signature || !MORALIS_WEBHOOK_SECRET) {
    console.warn("Missing signature or webhook secret");
    return false;
  }

  try {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(MORALIS_WEBHOOK_SECRET),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const signatureBuffer = await crypto.subtle.sign(
      "HMAC",
      key,
      encoder.encode(payload)
    );

    const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    return expectedSignature === signature;
  } catch (error) {
    console.error("Signature verification error:", error);
    return false;
  }
}

/**
 * Fetch wallet networth from Moralis API
 * @param walletAddress - The wallet address to query
 * @returns Networth in USD
 */
async function fetchWalletNetworth(
  walletAddress: string
): Promise<number> {
  if (!MORALIS_API_KEY) {
    throw new Error("MORALIS_API_KEY not configured");
  }

  try {
    const response = await fetch(
      `https://deep-index.moralis.io/api/v2.2/wallets/${walletAddress}/net-worth?chains=eth,polygon,bsc,avalanche,arbitrum,optimism,base&exclude_spam=true&exclude_unverified_contracts=true`,
      {
        headers: {
          "X-API-Key": MORALIS_API_KEY,
          "accept": "application/json",
        },
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Moralis API error: ${response.status} - ${errorText}`);
    }

    const data: MoralisNetworthResponse = await response.json();
    return parseFloat(data.total_networth_usd || "0");
  } catch (error) {
    console.error("Error fetching wallet networth:", error);
    throw error;
  }
}

/**
 * Update asset in Supabase database
 * @param supabase - Supabase client
 * @param walletAddress - Wallet address
 * @param networthUsd - Networth in USD
 */
async function updateAssetInDatabase(
  supabase: any,
  walletAddress: string,
  networthUsd: number
): Promise<void> {
  // Find the asset by wallet address
  const { data: asset, error: findError } = await supabase
    .from("assets")
    .select("id, user_id")
    .eq("asset_address_or_id", walletAddress)
    .eq("provider", "moralis")
    .single();

  if (findError || !asset) {
    console.warn(`Asset not found for wallet: ${walletAddress}`);
    return;
  }

  // Update the asset balance
  const { error: updateError } = await supabase
    .from("assets")
    .update({
      balance_usd: networthUsd,
      last_sync: new Date().toISOString(),
    })
    .eq("id", asset.id);

  if (updateError) {
    console.error("Error updating asset:", updateError);
    throw updateError;
  }

  console.log(`Asset updated: ${walletAddress} -> $${networthUsd}`);

  // Record wealth snapshot
  await recordWealthSnapshot(supabase, asset.user_id);
}

/**
 * Record wealth snapshot in wealth_history
 * @param supabase - Supabase client
 * @param userId - User ID
 */
async function recordWealthSnapshot(
  supabase: any,
  userId: string
): Promise<void> {
  try {
    const { error } = await supabase.rpc("record_wealth_snapshot", {
      p_user_id: userId,
    });

    if (error) {
      console.error("Error recording wealth snapshot:", error);
    } else {
      console.log(`Wealth snapshot recorded for user: ${userId}`);
    }
  } catch (error) {
    console.error("Exception recording wealth snapshot:", error);
  }
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, x-signature",
      },
    });
  }

  // Only accept POST requests
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      {
        status: 405,
        headers: { "Content-Type": "application/json" },
      }
    );
  }

  try {
    // Read the raw body for signature verification
    const rawBody = await req.text();
    const signature = req.headers.get("x-signature");

    // Verify signature (skip for test webhooks)
    const isTestWebhook = rawBody.includes('"test":true');
    if (!isTestWebhook) {
      const isValid = await verifyMoralisSignature(rawBody, signature);
      if (!isValid) {
        console.warn("Invalid webhook signature");
        return new Response(
          JSON.stringify({ error: "Invalid signature" }),
          {
            status: 401,
            headers: { "Content-Type": "application/json" },
          }
        );
      }
    }

    // Parse the webhook payload
    const payload: MoralisWebhookPayload = JSON.parse(rawBody);

    // Handle test webhook
    if (isTestWebhook) {
      console.log("Test webhook received");
      return new Response(
        JSON.stringify({ success: true, message: "Test webhook received" }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // Only process confirmed transactions
    if (!payload.confirmed) {
      console.log("Unconfirmed transaction, skipping");
      return new Response(
        JSON.stringify({ success: true, message: "Unconfirmed transaction" }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // Initialize Supabase client
    if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error("Supabase configuration missing");
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Extract wallet addresses from native balances
    const walletAddresses = new Set<string>();

    // From native balances
    if (payload.nativeBalances) {
      payload.nativeBalances.forEach((balance) => {
        walletAddresses.add(balance.address.toLowerCase());
      });
    }

    // From transactions
    payload.txs.forEach((tx: any) => {
      if (tx.from) walletAddresses.add(tx.from.toLowerCase());
      if (tx.to) walletAddresses.add(tx.to.toLowerCase());
    });

    // From ERC20 transfers
    payload.erc20Transfers.forEach((transfer: any) => {
      if (transfer.from) walletAddresses.add(transfer.from.toLowerCase());
      if (transfer.to) walletAddresses.add(transfer.to.toLowerCase());
    });

    console.log(`Processing ${walletAddresses.size} wallet addresses`);

    // Process each wallet address
    const updatePromises = Array.from(walletAddresses).map(
      async (walletAddress) => {
        try {
          const networthUsd = await fetchWalletNetworth(walletAddress);
          await updateAssetInDatabase(supabase, walletAddress, networthUsd);
        } catch (error) {
          console.error(`Error processing wallet ${walletAddress}:`, error);
        }
      }
    );

    await Promise.all(updatePromises);

    return new Response(
      JSON.stringify({
        success: true,
        message: `Processed ${walletAddresses.size} wallets`,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Webhook processing error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        message: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});

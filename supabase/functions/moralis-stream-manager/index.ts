// Supabase Edge Function: moralis-stream-manager
// Purpose: Manage Moralis Streams (create, add/remove addresses, cleanup)
// Author: Finance Realtime Engine
// Date: 2026-01-20

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ============================================================================
// TYPES & INTERFACES
// ============================================================================

interface StreamConfig {
  chains: string[];
  description: string;
  tag: string;
  webhookUrl: string;
  includeNativeTxs: boolean;
  includeContractLogs: boolean;
  includeInternalTxs: boolean;
  getNativeBalances: Array<{
    selectors: string[];
    type: string;
  }>;
}

interface MoralisStream {
  id: string;
  tag: string;
  description: string;
  webhookUrl: string;
  chains: string[];
  status: string;
}

interface RequestPayload {
  action: "setup" | "add_address" | "remove_address" | "cleanup_user";
  address?: string;
  userId?: string;
}

// ============================================================================
// CONFIGURATION
// ============================================================================

const MORALIS_API_KEY = Deno.env.get("MORALIS_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const WEBHOOK_URL = Deno.env.get("FINANCE_WEBHOOK_URL") || 
  `${SUPABASE_URL}/functions/v1/finance-webhook`;

const STREAM_TAG = "financo-global-stream";
const SUPPORTED_CHAINS = [
  "0x1",      // Ethereum
  "0x89",     // Polygon
  "0x38",     // BSC
  "0xa86a",   // Avalanche
  "0xa4b1",   // Arbitrum
  "0xa",      // Optimism
  "0x2105",   // Base
];

// ============================================================================
// MORALIS API HELPERS
// ============================================================================

/**
 * Make authenticated request to Moralis API
 */
async function moralisRequest(
  endpoint: string,
  method: string = "GET",
  body?: any
): Promise<any> {
  if (!MORALIS_API_KEY) {
    throw new Error("MORALIS_API_KEY not configured");
  }

  const options: RequestInit = {
    method,
    headers: {
      "X-API-Key": MORALIS_API_KEY,
      "Content-Type": "application/json",
      "accept": "application/json",
    },
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  const response = await fetch(
    `https://api.moralis-streams.com/streams/evm${endpoint}`,
    options
  );

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Moralis API error: ${response.status} - ${errorText}`);
  }

  return response.json();
}

/**
 * Find existing stream by tag
 */
async function findStreamByTag(tag: string): Promise<MoralisStream | null> {
  try {
    const response = await moralisRequest("");
    const streams = response.result || [];
    
    return streams.find((s: MoralisStream) => s.tag === tag) || null;
  } catch (error) {
    console.error("Error finding stream:", error);
    return null;
  }
}

/**
 * Create new Moralis stream
 */
async function createStream(): Promise<MoralisStream> {
  const config: StreamConfig = {
    chains: SUPPORTED_CHAINS,
    description: "Financo global wallet monitoring stream",
    tag: STREAM_TAG,
    webhookUrl: WEBHOOK_URL,
    includeNativeTxs: true,
    includeContractLogs: true,
    includeInternalTxs: true,
    getNativeBalances: [
      {
        selectors: ["$from", "$to"],
        type: "tx",
      },
    ],
  };

  console.log("Creating new stream with config:", config);
  return await moralisRequest("", "PUT", config);
}

/**
 * Setup or verify Moralis stream exists
 */
async function setupMoralisStream(): Promise<MoralisStream> {
  // Check if stream already exists
  let stream = await findStreamByTag(STREAM_TAG);

  if (stream) {
    console.log("Stream already exists:", stream.id);
    return stream;
  }

  // Create new stream
  console.log("Creating new stream...");
  stream = await createStream();
  console.log("Stream created:", stream.id);

  return stream;
}

/**
 * Add wallet address to stream
 */
async function addAddressToStream(
  streamId: string,
  address: string
): Promise<void> {
  console.log(`Adding address ${address} to stream ${streamId}`);
  
  await moralisRequest(`/${streamId}/address`, "POST", {
    address: address.toLowerCase(),
  });

  console.log(`Address ${address} added successfully`);
}

/**
 * Remove wallet address from stream
 */
async function removeAddressFromStream(
  streamId: string,
  address: string
): Promise<void> {
  console.log(`Removing address ${address} from stream ${streamId}`);
  
  await moralisRequest(
    `/${streamId}/address?address=${address.toLowerCase()}`,
    "DELETE"
  );

  console.log(`Address ${address} removed successfully`);
}

/**
 * Get all addresses in a stream
 */
async function getStreamAddresses(streamId: string): Promise<string[]> {
  try {
    const response = await moralisRequest(`/${streamId}/address`);
    return response.result?.map((item: any) => item.address) || [];
  } catch (error) {
    console.error("Error getting stream addresses:", error);
    return [];
  }
}

// ============================================================================
// DATABASE HELPERS
// ============================================================================

/**
 * Get all wallet addresses for a user
 */
async function getUserWalletAddresses(
  supabase: any,
  userId: string
): Promise<string[]> {
  const { data, error } = await supabase
    .from("assets")
    .select("asset_address_or_id")
    .eq("user_id", userId)
    .eq("provider", "moralis")
    .eq("type", "crypto");

  if (error) {
    console.error("Error fetching user wallets:", error);
    return [];
  }

  return data?.map((asset: any) => asset.asset_address_or_id) || [];
}

/**
 * Delete user's crypto assets from database
 */
async function deleteUserCryptoAssets(
  supabase: any,
  userId: string
): Promise<void> {
  const { error } = await supabase
    .from("assets")
    .delete()
    .eq("user_id", userId)
    .eq("provider", "moralis")
    .eq("type", "crypto");

  if (error) {
    console.error("Error deleting user crypto assets:", error);
    throw error;
  }

  console.log(`Deleted crypto assets for user ${userId}`);
}

// ============================================================================
// ACTION HANDLERS
// ============================================================================

/**
 * Handle setup action
 */
async function handleSetup(): Promise<any> {
  const stream = await setupMoralisStream();
  return {
    success: true,
    message: "Stream setup completed",
    streamId: stream.id,
    tag: stream.tag,
  };
}

/**
 * Handle add address action
 */
async function handleAddAddress(address: string): Promise<any> {
  if (!address) {
    throw new Error("Address is required");
  }

  const stream = await setupMoralisStream();
  await addAddressToStream(stream.id, address);

  return {
    success: true,
    message: `Address ${address} added to stream`,
    streamId: stream.id,
  };
}

/**
 * Handle remove address action
 */
async function handleRemoveAddress(address: string): Promise<any> {
  if (!address) {
    throw new Error("Address is required");
  }

  const stream = await findStreamByTag(STREAM_TAG);
  if (!stream) {
    throw new Error("Stream not found");
  }

  await removeAddressFromStream(stream.id, address);

  // Also remove from database
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error("Supabase configuration missing");
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  
  const { error } = await supabase
    .from("assets")
    .delete()
    .eq("asset_address_or_id", address.toLowerCase())
    .eq("provider", "moralis");

  if (error) {
    console.error("Error removing asset from database:", error);
  }

  return {
    success: true,
    message: `Address ${address} removed from stream and database`,
    streamId: stream.id,
  };
}

/**
 * Handle cleanup user action
 */
async function handleCleanupUser(userId: string): Promise<any> {
  if (!userId) {
    throw new Error("User ID is required");
  }

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error("Supabase configuration missing");
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // Get all user wallet addresses
  const walletAddresses = await getUserWalletAddresses(supabase, userId);

  if (walletAddresses.length === 0) {
    return {
      success: true,
      message: "No wallets to cleanup",
      removedCount: 0,
    };
  }

  // Find stream
  const stream = await findStreamByTag(STREAM_TAG);
  if (!stream) {
    console.warn("Stream not found, skipping Moralis cleanup");
  } else {
    // Remove each address from stream
    const removePromises = walletAddresses.map((address) =>
      removeAddressFromStream(stream.id, address).catch((error) => {
        console.error(`Error removing address ${address}:`, error);
      })
    );

    await Promise.all(removePromises);
  }

  // Delete from database
  await deleteUserCryptoAssets(supabase, userId);

  return {
    success: true,
    message: `Cleaned up ${walletAddresses.length} wallet addresses`,
    removedCount: walletAddresses.length,
    addresses: walletAddresses,
  };
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
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
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
    // Parse request payload
    const payload: RequestPayload = await req.json();
    const { action, address, userId } = payload;

    let result;

    switch (action) {
      case "setup":
        result = await handleSetup();
        break;

      case "add_address":
        result = await handleAddAddress(address!);
        break;

      case "remove_address":
        result = await handleRemoveAddress(address!);
        break;

      case "cleanup_user":
        result = await handleCleanupUser(userId!);
        break;

      default:
        throw new Error(`Unknown action: ${action}`);
    }

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Stream manager error:", error);
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

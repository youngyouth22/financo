// Supabase Edge Function: moralis-stream-manager
// Purpose: Manage Moralis Streams (create, add/remove addresses, cleanup)
// Author: Finance Realtime Engine
// Date: 2026-01-20

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// ============================================================================
// TYPES & INTERFACES
// ============================================================================

interface MoralisStream {
  id?: string;
  streamId?: string; // Moralis uses both id and streamId in different responses
  tag: string;
  description: string;
  webhookUrl: string;
  chainIds: string[];
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

// Use provided Webhook URL or default to the finance-webhook edge function
const WEBHOOK_URL =
  Deno.env.get("FINANCE_WEBHOOK_URL") ||
  `${SUPABASE_URL}/functions/v1/finance-webhook`;

const STREAM_TAG = "financo-global-stream";
const SUPPORTED_CHAINS = [
  "0x1", // Ethereum
  "0x89", // Polygon
  "0x38", // BSC
  "0xa86a", // Avalanche
  "0xa4b1", // Arbitrum
  "0xa", // Optimism
  "0x2105", // Base
];

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ============================================================================
// MORALIS API HELPERS
// ============================================================================

/**
 * Helper to extract Stream ID from inconsistent Moralis responses
 */
function extractStreamId(stream: MoralisStream): string {
  const id = stream.id || stream.streamId;
  if (!id) throw new Error("Could not find Stream ID in Moralis response");
  return id;
}

/**
 * Make authenticated request to Moralis API
 */
async function moralisRequest(
  endpoint: string,
  method: string = "GET",
  body?: any,
): Promise<any> {
  if (!MORALIS_API_KEY) {
    throw new Error("MORALIS_API_KEY not configured");
  }

  const options: RequestInit = {
    method,
    headers: {
      "X-API-Key": MORALIS_API_KEY,
      "Content-Type": "application/json",
      accept: "application/json",
    },
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  const response = await fetch(
    `https://api.moralis-streams.com/streams/evm${endpoint}`,
    options,
  );

  const responseData = await response.json();

  if (!response.ok) {
    throw new Error(
      `Moralis API error: ${response.status} - ${JSON.stringify(responseData)}`,
    );
  }

  return responseData;
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
 * Create a new Moralis stream
 */
async function createStream(): Promise<MoralisStream> {
  const config = {
    chainIds: SUPPORTED_CHAINS,
    description: "Financo global wallet monitoring",
    tag: STREAM_TAG,
    webhookUrl: WEBHOOK_URL,
    includeNativeTxs: true,
    includeContractLogs: true,
    includeInternalTxs: true,
  };

  console.log("Creating new stream with config:", config);
  return await moralisRequest("", "PUT", config);
}

/**
 * Orchestrator: Find or Create the stream
 */
async function setupMoralisStream(): Promise<MoralisStream> {
  let stream = await findStreamByTag(STREAM_TAG);

  if (stream) {
    console.log("Existing stream found:", extractStreamId(stream));
    return stream;
  }

  console.log("No stream found with tag. Creating new one...");
  return await createStream();
}

/**
 * Add a wallet address to a stream
 */
async function addAddressToStream(
  streamId: string,
  address: string,
): Promise<void> {
  console.log(`Adding address ${address} to stream ${streamId}`);
  await moralisRequest(`/${streamId}/address`, "POST", {
    address: address.toLowerCase(),
  });
}

/**
 * Remove a wallet address from a stream
 */
async function removeAddressFromStream(
  streamId: string,
  address: string,
): Promise<void> {
  console.log(`Removing address ${address} from stream ${streamId}`);
  await moralisRequest(`/${streamId}/address`, "DELETE", {
    address: address.toLowerCase(),
  });
}

// ============================================================================
// DATABASE HELPERS
// ============================================================================

/**
 * Get all crypto wallet addresses for a specific user from Supabase
 */
async function getUserWalletAddresses(
  supabase: any,
  userId: string,
): Promise<string[]> {
  const { data, error } = await supabase
    .from("assets")
    .select("asset_address_or_id")
    .eq("user_id", userId)
    .eq("provider", "moralis")
    .eq("type", "crypto");

  if (error) throw error;
  return data?.map((asset: any) => asset.asset_address_or_id) || [];
}

/**
 * Delete a user's crypto assets from Supabase
 */
async function deleteUserCryptoAssets(
  supabase: any,
  userId: string,
): Promise<void> {
  const { error } = await supabase
    .from("assets")
    .delete()
    .eq("user_id", userId)
    .eq("provider", "moralis")
    .eq("type", "crypto");

  if (error) throw error;
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req: Request) => {
  // Handle CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload: RequestPayload = await req.json();
    const { action, address, userId } = payload;

    // Initialize Supabase client
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    let result;

    switch (action) {
      case "setup": {
        const stream = await setupMoralisStream();
        result = {
          success: true,
          message: "Stream is active",
          streamId: extractStreamId(stream),
          tag: stream.tag,
        };
        break;
      }

      case "add_address": {
        if (!address) throw new Error("Address is required");
        const stream = await setupMoralisStream();
        await addAddressToStream(extractStreamId(stream), address);
        result = { success: true, message: `Address ${address} added` };
        break;
      }

      case "remove_address": {
        if (!address) throw new Error("Address is required");
        const stream = await findStreamByTag(STREAM_TAG);
        if (!stream) throw new Error("Stream not found");

        const sId = extractStreamId(stream);
        await removeAddressFromStream(sId, address);

        // Cleanup database record
        await supabase
          .from("assets")
          .delete()
          .eq("asset_address_or_id", address.toLowerCase())
          .eq("provider", "moralis");

        result = { success: true, message: `Address ${address} removed` };
        break;
      }

      case "cleanup_user": {
        if (!userId) throw new Error("User ID is required");
        const walletAddresses = await getUserWalletAddresses(supabase, userId);

        if (walletAddresses.length > 0) {
          const stream = await findStreamByTag(STREAM_TAG);
          if (stream) {
            const sId = extractStreamId(stream);
            await Promise.all(
              walletAddresses.map((addr) =>
                removeAddressFromStream(sId, addr).catch((e) =>
                  console.error(e),
                ),
              ),
            );
          }
          await deleteUserCryptoAssets(supabase, userId);
        }

        result = { success: true, count: walletAddresses.length };
        break;
      }

      default:
        throw new Error(`Unknown action: ${action}`);
    }

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Manager Error:", error.message);
    return new Response(
      JSON.stringify({ error: "Internal Error", message: error.message }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});

// supabase functions deploy finance-webhook --no-verify-jwt
// supabase functions deploy moralis-stream-manager --no-verify-jwt
// // curl -X POST https://nbdfdlvbouoaoprbkbme.supabase.co/functions/v1/moralis-stream-manager -H "Content-Type: application/json" -d '{"action": "setup"}'

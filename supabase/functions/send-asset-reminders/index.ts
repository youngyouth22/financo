// Supabase Edge Function: send-asset-reminders
// Purpose: Send FCM push notifications for asset reminders due today
// Trigger: Daily cron job at 08:00 AM UTC

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// Firebase Cloud Messaging API endpoint
const FCM_API_URL = "https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send";

// Types
interface AssetReminder {
  id: string;
  user_id: string;
  asset_id: string;
  title: string;
  next_event_date: string;
  amount_expected: number | null;
  asset_name: string;
  fcm_token: string | null;
}

interface FCMMessage {
  message: {
    token: string;
    notification: {
      title: string;
      body: string;
    };
    data: {
      type: string;
      asset_id: string;
      reminder_id: string;
      amount: string;
    };
    android: {
      priority: string;
      notification: {
        sound: string;
        channel_id: string;
      };
    };
    apns: {
      payload: {
        aps: {
          sound: string;
          badge: number;
        };
      };
    };
  };
}

/**
 * Get OAuth2 access token for Firebase Cloud Messaging
 * Uses service account credentials stored in Supabase Secrets
 */
async function getAccessToken(): Promise<string> {
  try {
    // Get Firebase service account from Supabase Secrets
    const serviceAccount = JSON.parse(
      Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "{}"
    );

    if (!serviceAccount.private_key || !serviceAccount.client_email) {
      throw new Error("Invalid Firebase service account credentials");
    }

    // Create JWT for OAuth2
    const header = {
      alg: "RS256",
      typ: "JWT",
    };

    const now = Math.floor(Date.now() / 1000);
    const payload = {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    };

    // Sign JWT (simplified - in production use proper JWT library)
    const encoder = new TextEncoder();
    const headerB64 = btoa(JSON.stringify(header));
    const payloadB64 = btoa(JSON.stringify(payload));
    const signatureInput = `${headerB64}.${payloadB64}`;

    // Import private key
    const privateKey = await crypto.subtle.importKey(
      "pkcs8",
      encoder.encode(serviceAccount.private_key),
      {
        name: "RSASSA-PKCS1-v1_5",
        hash: "SHA-256",
      },
      false,
      ["sign"]
    );

    // Sign
    const signature = await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      privateKey,
      encoder.encode(signatureInput)
    );

    const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)));
    const jwt = `${signatureInput}.${signatureB64}`;

    // Exchange JWT for access token
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    });

    const tokenData = await tokenResponse.json();
    return tokenData.access_token;
  } catch (error) {
    console.error("Error getting access token:", error);
    throw error;
  }
}

/**
 * Send FCM push notification to a user
 */
async function sendFCMNotification(
  fcmToken: string,
  reminder: AssetReminder,
  accessToken: string
): Promise<boolean> {
  try {
    const message: FCMMessage = {
      message: {
        token: fcmToken,
        notification: {
          title: `💰 ${reminder.title}`,
          body: reminder.amount_expected
            ? `Expected payment: $${reminder.amount_expected.toLocaleString()} from ${reminder.asset_name}`
            : `Reminder for ${reminder.asset_name}`,
        },
        data: {
          type: "asset_reminder",
          asset_id: reminder.asset_id,
          reminder_id: reminder.id,
          amount: reminder.amount_expected?.toString() || "0",
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channel_id: "asset_reminders",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      },
    };

    const response = await fetch(FCM_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify(message),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error(`FCM error for user ${reminder.user_id}:`, error);
      return false;
    }

    console.log(`✓ Notification sent to user ${reminder.user_id} for reminder ${reminder.id}`);
    return true;
  } catch (error) {
    console.error(`Error sending FCM notification:`, error);
    return false;
  }
}

/**
 * Main handler
 */
serve(async (req) => {
  try {
    // CORS headers
    if (req.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get today's date (start and end of day in UTC)
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);
    const todayStart = today.toISOString();
    
    const todayEnd = new Date(today);
    todayEnd.setUTCHours(23, 59, 59, 999);
    const todayEndStr = todayEnd.toISOString();

    console.log(`Checking reminders for date range: ${todayStart} to ${todayEndStr}`);

    // Fetch all reminders due today with user FCM tokens
    const { data: reminders, error: fetchError } = await supabase
      .from("asset_reminders")
      .select(`
        id,
        user_id,
        asset_id,
        title,
        next_event_date,
        amount_expected,
        assets!inner (
          name
        ),
        profiles!inner (
          fcm_token
        )
      `)
      .gte("next_event_date", todayStart)
      .lte("next_event_date", todayEndStr)
      .not("profiles.fcm_token", "is", null);

    if (fetchError) {
      console.error("Error fetching reminders:", fetchError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch reminders", details: fetchError }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    if (!reminders || reminders.length === 0) {
      console.log("No reminders due today");
      return new Response(
        JSON.stringify({ message: "No reminders due today", count: 0 }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`Found ${reminders.length} reminders due today`);

    // Get FCM access token
    const accessToken = await getAccessToken();

    // Send notifications
    const results = await Promise.allSettled(
      reminders.map(async (reminder: any) => {
        const fcmToken = reminder.profiles?.fcm_token;
        const assetName = reminder.assets?.name || "Unknown Asset";

        if (!fcmToken) {
          console.log(`Skipping reminder ${reminder.id}: No FCM token`);
          return { success: false, reason: "no_token" };
        }

        const reminderData: AssetReminder = {
          id: reminder.id,
          user_id: reminder.user_id,
          asset_id: reminder.asset_id,
          title: reminder.title,
          next_event_date: reminder.next_event_date,
          amount_expected: reminder.amount_expected,
          asset_name: assetName,
          fcm_token: fcmToken,
        };

        const sent = await sendFCMNotification(fcmToken, reminderData, accessToken);
        return { success: sent, reminder_id: reminder.id };
      })
    );

    // Count successes and failures
    const successCount = results.filter(
      (r) => r.status === "fulfilled" && r.value.success
    ).length;
    const failureCount = results.length - successCount;

    console.log(`Notifications sent: ${successCount} success, ${failureCount} failed`);

    return new Response(
      JSON.stringify({
        message: "Reminders processed",
        total: reminders.length,
        sent: successCount,
        failed: failureCount,
        timestamp: new Date().toISOString(),
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        message: error.message,
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});

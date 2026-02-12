// Supabase Edge Function: send-asset-reminders
// Purpose: Send FCM push notifications for asset reminders at 08:00 AM local time
// Trigger: Hourly cron job (checks which users are currently in the 08:00 AM window)
// Author: Finance Realtime Engine

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// Firebase Cloud Messaging API endpoint
const FCM_API_URL = "https://fcm.googleapis.com/v1/projects/financo-13f01/messages:send";

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

/**
 * Get OAuth2 access token for Firebase Cloud Messaging
 */
async function getAccessToken(): Promise<string> {
  try {
    const serviceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") || "{}");
    if (!serviceAccount.private_key || !serviceAccount.client_email) {
      throw new Error("Invalid Firebase service account credentials");
    }

    const header = { alg: "RS256", typ: "JWT" };
    const now = Math.floor(Date.now() / 1000);
    const payload = {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    };

    const encoder = new TextEncoder();
    const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, "");
    const payloadB64 = btoa(JSON.stringify(payload)).replace(/=/g, "");
    const signatureInput = `${headerB64}.${payloadB64}`;

    const privateKey = await crypto.subtle.importKey(
      "pkcs8",
      encoder.encode(serviceAccount.private_key),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", privateKey, encoder.encode(signatureInput));
    const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
    const jwt = `${signatureInput}.${signatureB64}`;

    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
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
 * Send FCM push notification
 */
async function sendFCMNotification(fcmToken: string, reminder: AssetReminder, accessToken: string) {
  const message = {
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
      },
      android: { priority: "high", notification: { sound: "default", channel_id: "asset_reminders" } },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    },
  };

  const response = await fetch(FCM_API_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${accessToken}` },
    body: JSON.stringify(message),
  });

  return response.ok;
}

/**
 * Main Handler
 */
serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: { "Access-Control-Allow-Origin": "*" } });

  try {
    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

    // 1. Define the 24h window (UTC) to find potential reminders
    const nowUTC = new Date();
    const startOfDay = new Date(nowUTC);
    startOfDay.setUTCHours(0, 0, 0, 0);
    const endOfDay = new Date(nowUTC);
    endOfDay.setUTCHours(23, 59, 59, 999);

    // 2. Fetch reminders due today + user timezone/token
    const { data: reminders, error: fetchError } = await supabase
      .from("asset_reminders")
      .select(`
        id, user_id, asset_id, title, next_event_date, amount_expected,
        assets!inner ( name ),
        profiles!inner ( fcm_token, timezone )
      `)
      .gte("next_event_date", startOfDay.toISOString())
      .lte("next_event_date", endOfDay.toISOString())
      .eq("is_completed", false)
      .not("profiles.fcm_token", "is", null);

    if (fetchError) throw fetchError;
    if (!reminders || reminders.length === 0) return new Response(JSON.stringify({ message: "No reminders found today" }));

    // 3. FILTERING: Only keep reminders where local user time is 08:00 AM
    const targets = reminders.filter((rem: any) => {
      const userTimezone = rem.profiles?.timezone || "UTC";
      try {
        const localHour = new Intl.DateTimeFormat("en-US", {
          hour: "numeric",
          hour12: false,
          timeZone: userTimezone,
        }).format(nowUTC);
        
        return parseInt(localHour) === 8;
      } catch (e) {
        console.error(`Invalid timezone ${userTimezone} for user ${rem.user_id}`);
        return false;
      }
    });

    if (targets.length === 0) {
      return new Response(JSON.stringify({ message: "No users in the 08:00 AM window currently" }));
    }

    // 4. Send notifications to filtered targets
    const accessToken = await getAccessToken();
    const notificationResults = await Promise.all(
      targets.map(async (rem: any) => {
        const success = await sendFCMNotification(rem.profiles.fcm_token, {
          ...rem,
          asset_name: rem.assets.name,
        }, accessToken);
        return { id: rem.id, success };
      })
    );

    const sentCount = notificationResults.filter(r => r.success).length;

    return new Response(JSON.stringify({ 
      processed: targets.length, 
      sent: sentCount,
      timestamp: nowUTC.toISOString() 
    }), { status: 200 });

  } catch (error) {
    console.error("Critical Error:", error.message);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});
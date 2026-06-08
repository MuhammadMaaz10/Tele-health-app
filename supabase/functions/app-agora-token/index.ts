import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { RtcRole, RtcTokenBuilder } from "npm:agora-token@2.0.4";

type AppointmentRow = {
  id: number;
  start_time: string;
  end_time: string;
  status: string;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const AGORA_APP_ID = Deno.env.get("AGORA_APP_ID") ?? "";
const AGORA_APP_CERTIFICATE = Deno.env.get("AGORA_APP_CERTIFICATE") ?? "";
const AGORA_TOKEN_TTL_SECONDS = Number(Deno.env.get("AGORA_TOKEN_TTL_SECONDS") ?? "120");

/** Required for Flutter Web / browser: `functions.invoke` uses `fetch`, which enforces CORS. */
const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-supabase-api-version",
  "Access-Control-Max-Age": "86400",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  });

async function stableAgoraUid(input: string): Promise<number> {
  const bytes = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  const arr = new Uint8Array(digest);
  const value = (arr[0] << 24) | (arr[1] << 16) | (arr[2] << 8) | arr[3];
  const positive = Math.abs(value);
  // Agora uid must be non-zero for integer uid mode.
  return (positive % 2147483646) + 1;
}

Deno.serve(async (req) => {
  try {
    console.log("[app-agora-token] request received", { method: req.method });

    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (req.method !== "POST") {
      console.log("[app-agora-token] method not allowed");
      return json({ error: "Method not allowed." }, 405);
    }

    if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
      console.error("[app-agora-token] missing Supabase env");
      return json({ error: "Missing Supabase env configuration." }, 500);
    }
    if (!AGORA_APP_ID || !AGORA_APP_CERTIFICATE) {
      console.error("[app-agora-token] missing Agora env");
      return json({ error: "Missing Agora env configuration." }, 500);
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      console.log("[app-agora-token] missing Authorization header");
      return json({ error: "Missing Authorization header." }, 401);
    }

    const payload = await req.json().catch(() => null);
    const appointmentIdRaw = payload?.appointment_id;
    const appointmentId = Number(appointmentIdRaw);
    if (!Number.isFinite(appointmentId) || appointmentId <= 0) {
      console.log("[app-agora-token] invalid appointment_id", { appointmentIdRaw });
      return json({ error: "Invalid appointment_id." }, 400);
    }
    console.log("[app-agora-token] parsed request", { appointmentId });

    // Use caller JWT so RLS enforces participant access.
    const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });

    const { data: userData, error: userError } = await client.auth.getUser();
    if (userError || !userData.user) {
      console.log("[app-agora-token] unauthorized user", { userError });
      return json({ error: "Unauthorized." }, 401);
    }
    console.log("[app-agora-token] auth user", { userId: userData.user.id });

    const { data: appointment, error: apptError } = await client
      .from("appointments")
      .select("id,start_time,end_time,status")
      .eq("id", appointmentId)
      .single<AppointmentRow>();

    if (apptError || !appointment) {
      console.log("[app-agora-token] appointment not found/access denied", { appointmentId, apptError });
      return json({ error: "Appointment not found or access denied." }, 403);
    }
    console.log("[app-agora-token] appointment loaded", {
      appointmentId: appointment.id,
      status: appointment.status,
      start: appointment.start_time,
      end: appointment.end_time,
    });

    if (appointment.status !== "CONFIRMED") {
      console.log("[app-agora-token] appointment status not confirmed", { status: appointment.status });
      return json({ error: "Call is only available for confirmed appointments." }, 400);
    }

    const now = new Date();
    const startTime = new Date(appointment.start_time);
    const endTime = new Date(appointment.end_time);
    const joinWindowStart = new Date(startTime.getTime() - 5 * 60 * 1000);

    if (now < joinWindowStart) {
      console.log("[app-agora-token] join window not started", {
        now: now.toISOString(),
        joinWindowStart: joinWindowStart.toISOString(),
      });
      return json({ error: "Call is not available yet. Join up to 5 minutes before start time." }, 400);
    }
    if (now >= endTime) {
      console.log("[app-agora-token] appointment ended", {
        now: now.toISOString(),
        endTime: endTime.toISOString(),
      });
      return json({ error: "Call is no longer available because this appointment has ended." }, 400);
    }

    const uid = await stableAgoraUid(userData.user.id);
    const channelName = `appointment-${appointment.id}`;
    const expireUnix = Math.floor(Date.now() / 1000) + AGORA_TOKEN_TTL_SECONDS;

    const accessToken = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      uid,
      RtcRole.PUBLISHER,
      expireUnix,
      expireUnix,
    );

    console.log("[app-agora-token] token generated", {
      appointmentId: appointment.id,
      channelName,
      uid,
      expiresAt: new Date(expireUnix * 1000).toISOString(),
    });
    return json({
      appId: AGORA_APP_ID,
      roomName: channelName,
      accessToken,
      uid,
      expiresAt: new Date(expireUnix * 1000).toISOString(),
    });
  } catch (error) {
    console.error("[app-agora-token] unexpected error", error);
    return json({ error: "Unexpected server error." }, 500);
  }
});

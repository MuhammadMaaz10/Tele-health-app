# Agora Call Setup (Done + Next Steps)

This project now includes app-side Agora calling and a Supabase Edge Function implementation for secure token issuing.

## What was already done (app side)

- Added Flutter packages:
  - `agora_rtc_engine`
  - `permission_handler`
- Added call screen + RTC service:
  - `lib/features/appointments/view/agora_call_view.dart`
  - `lib/features/appointments/services/agora_call_service.dart`
- Appointment details now shows `Join Video/Audio Call` for confirmed appointments.
- Added call-window logic in app model:
  - join allowed from 5 minutes before start until appointment end.
- Added permission texts:
  - Android microphone permission in `AndroidManifest.xml`
  - iOS camera/microphone usage in `Info.plist`

## What is done now (Supabase + token flow)

- Added Edge Function code:
  - `supabase/functions/app-agora-token/index.ts`
- `AppointmentApi.startVideo()` calls this function.
- Added token refresh path (`refreshVideoToken`) so refresh does not create extra session rows.
- Security checks in function:
  1. Auth required
  2. Caller must have RLS access to appointment
  3. Appointment must be `CONFIRMED`
  4. Time window enforced (start-5min to end)

## Deploy steps (Supabase)

### 1) Link project (once)

```bash
supabase login
supabase link --project-ref <your-project-ref>
```

### 2) Set function secrets

```bash
supabase secrets set AGORA_APP_ID=<your_agora_app_id>
supabase secrets set AGORA_APP_CERTIFICATE=<your_agora_app_certificate>
supabase secrets set AGORA_TOKEN_TTL_SECONDS=120
```

### 3) Deploy function

```bash
supabase functions deploy app-agora-token --no-verify-jwt=false
```

### 4) Test function

```bash
supabase functions invoke app-agora-token --body '{"appointment_id":123}'
```

## Function contract (already used by app)

### Request

```json
{ "appointment_id": 123 }
```

### Success response

```json
{
  "appId": "YOUR_AGORA_APP_ID",
  "roomName": "appointment-123",
  "accessToken": "007eJx...",
  "uid": 123456,
  "expiresAt": "2026-05-07T14:30:00.000Z"
}
```

## What you must do in Agora console

1. Create an Agora project (RTC).
2. Enable App Certificate.
3. Copy:
   - `App ID`
   - `App Certificate`
4. Put both values only in Supabase secrets (never in Flutter env).
5. For production, keep token TTL short (90-180s) and rely on token renewal.

## Final checklist

- [ ] Agora project created with certificate enabled
- [ ] Supabase secrets set
- [ ] `app-agora-token` deployed
- [ ] Doctor and patient both have `CONFIRMED` appointment
- [ ] Join tested from both accounts inside allowed time window

# Supabase keys, `.env`, and email OTP

## Where to find values in the Supabase Dashboard

Sign in at [https://supabase.com/dashboard](https://supabase.com/dashboard), open your project, then:

| Variable | Where to find |
|----------|----------------|
| **SUPABASE_URL** | **Project Settings** (gear) → **API** → **Project URL** — looks like `https://xxxxxxxx.supabase.co`. |
| **SUPABASE_ANON_KEY** | Same page → **Project API keys** → **anon** / **public** — safe to use in mobile/web apps with **Row Level Security** enabled. |
| **Service role** (optional, not for Flutter) | Same **API** page → **service_role** — **secret**; bypasses RLS. Use only in trusted backends or Edge Functions, never in the client. |
| **JWT settings** (advanced) | **Project Settings** → **API** → JWT expiry etc. — usually you do not need these in the app. |
| **Auth providers** | **Authentication** → **Providers** — enable **Email**, configure SMTP (or use Supabase default mail) for production deliverability. |
| **Email templates** | **Authentication** → **Email** (or **Email Templates**) — edit subjects and bodies for magic links and OTP-style emails. |

Copy `SUPABASE_URL` and `SUPABASE_ANON_KEY` into your local `.env` file (create it from `.env.example`).

## Email OTP in Supabase

1. **Authentication** → **Providers** → **Email** — ensure email sign-in is enabled.
2. For **passwordless OTP** (code in email), use the Flutter flow: `signInWithOtp` then `verifyOtp` with `OtpType.email` (see template below).
3. **Authentication** → **Email templates** — choose the template that corresponds to **sign-in OTP** / **magic link** (wording varies by Supabase version). The editor often lists **available variables** (e.g. token or link). Use those names exactly.

### Example HTML body (customize to match your brand)

Supabase may expose a variable such as `{{ .Token }}` for a one-time code. **Check the template editor** for the exact variable names your project shows.

```html
<!DOCTYPE html>
<html>
<body style="font-family: system-ui, sans-serif; line-height: 1.5; color: #111;">
  <h2 style="margin-bottom: 8px;">Your verification code</h2>
  <p>Use this code in the Telehealth app to continue. It expires soon.</p>
  <p style="font-size: 28px; font-weight: 700; letter-spacing: 4px; margin: 24px 0;">
    {{ .Token }}
  </p>
  <p style="font-size: 12px; color: #666;">If you did not request this, you can ignore this email.</p>
</body>
</html>
```

If the editor uses a different placeholder (for example only a magic link), use the documented variable for **Email OTP** in your Supabase version.

### Flutter template (after `supabase_flutter` + `flutter_dotenv` are wired)

Request OTP:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> sendEmailOtp(String email) async {
  await Supabase.instance.client.auth.signInWithOtp(
    email: email.trim(),
    emailRedirectTo: null, // set a deep link if you use magic links + web
  );
}
```

Verify the code the user typed:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> verifyEmailOtp({
  required String email,
  required String token,
}) async {
  await Supabase.instance.client.auth.verifyOTP(
    email: email.trim(),
    token: token.trim(),
    type: OtpType.email,
  );
}
```

Listen for session changes as usual (`onAuthStateChange`). Persisting the session is handled by `supabase_flutter` when configured with a suitable local storage (see package docs).

## Security reminders

- Commit **`.env.example`** only; keep **`.env`** local and gitignored.
- Do **not** put the **service_role** key in Flutter, `.env` bundled in the app, or public repos.
- RLS policies on your tables are what protect data when using the **anon** key.

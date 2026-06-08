-- Run in Supabase SQL Editor once.
-- Stops auto-inserting into [profiles] on auth.users insert so the app only
-- writes profile data after OTP verification (see registration save flows).

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

-- Run in Supabase SQL Editor (once). Used by the Flutter app instead of REST /check-email.
-- Returns JSON: { "status": "NEW" | "EXISTS" | "INACTIVE", "message": "..." }

create or replace function public.app_check_signup_email(p_email text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_enabled boolean;
  v_has_profile boolean;
begin
  if p_email is null or trim(p_email) = '' then
    return jsonb_build_object(
      'status', 'NEW',
      'message', 'Enter a valid email.'
    );
  end if;

  select u.id into v_uid
  from auth.users u
  where lower(trim(u.email)) = lower(trim(p_email))
  limit 1;

  if v_uid is null then
    return jsonb_build_object(
      'status', 'NEW',
      'message', 'Continue with registration.'
    );
  end if;

  select
    exists (select 1 from public.profiles p where p.id = v_uid),
    coalesce((select p.enabled from public.profiles p where p.id = v_uid), true)
  into v_has_profile, v_enabled;

  -- Final registration check is based on profiles table presence.
  if v_has_profile and v_enabled then
    return jsonb_build_object(
      'status', 'EXISTS',
      'message', 'Email already registered, please login.'
    );
  end if;

  return jsonb_build_object(
    'status', 'INACTIVE',
    'message', 'Continue registration.'
  );
end;
$$;

revoke all on function public.app_check_signup_email(text) from public;
grant execute on function public.app_check_signup_email(text) to anon, authenticated;

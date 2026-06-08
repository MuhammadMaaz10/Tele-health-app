-- Run in Supabase SQL Editor (once)
create or replace function public.app_get_patients_directory()
returns table(email text, username text, enabled boolean)
language sql
security definer
set search_path = public
as $$
  select p.email, p.username, p.enabled
  from public.profiles p
  where p.enabled = true
    and public.user_has_role(p.id, 'PATIENT')
  order by p.email asc;
$$;

revoke all on function public.app_get_patients_directory() from public;
grant execute on function public.app_get_patients_directory() to authenticated;

-- Run in Supabase SQL Editor (once)
create or replace function public.app_set_appointment_status(
  p_appointment_id bigint,
  p_status text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;

  if not public.is_appointment_participant(p_appointment_id, auth.uid()) then
    raise exception 'You do not have permission to update this appointment.';
  end if;

  update public.appointments a
  set
    status = p_status::public.appointment_status,
    updated_at = now()
  where a.id = p_appointment_id;

  return p_status;
end;
$$;

revoke all on function public.app_set_appointment_status(bigint, text) from public;
grant execute on function public.app_set_appointment_status(bigint, text) to authenticated;

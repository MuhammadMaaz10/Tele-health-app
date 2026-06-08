-- Run in Supabase SQL Editor (once)
create or replace function public.app_update_appointment(
  p_appointment_id bigint,
  p_appointment_start_time timestamptz,
  p_appointment_end_time timestamptz,
  p_appointment_time text default ''
)
returns table (
  id bigint,
  "doctorAssigned" text,
  "patientBooked" text,
  "startTime" timestamptz,
  "endTime" timestamptz,
  description text,
  status text,
  "createdAt" timestamptz,
  "updatedAt" timestamptz,
  "appointmentTime" text,
  rescheduled boolean
)
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
    start_time = p_appointment_start_time,
    end_time = p_appointment_end_time,
    appointment_time = coalesce(p_appointment_time, ''),
    status = 'RESCHEDULED',
    rescheduled = true,
    updated_at = now()
  where a.id = p_appointment_id;

  return query
  select
    a.id,
    d.email as "doctorAssigned",
    p.email as "patientBooked",
    a.start_time as "startTime",
    a.end_time as "endTime",
    a.description,
    a.status::text as status,
    a.created_at as "createdAt",
    a.updated_at as "updatedAt",
    a.appointment_time as "appointmentTime",
    a.rescheduled
  from public.appointments a
  join public.profiles d on d.id = a.doctor_id
  join public.profiles p on p.id = a.patient_id
  where a.id = p_appointment_id;
end;
$$;

revoke all on function public.app_update_appointment(bigint, timestamptz, timestamptz, text) from public;
grant execute on function public.app_update_appointment(bigint, timestamptz, timestamptz, text) to authenticated;

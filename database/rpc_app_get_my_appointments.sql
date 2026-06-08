-- Run in Supabase SQL Editor.
-- Returns appointments for the signed-in user using participant visibility rules.

drop function if exists public.app_get_my_appointments(text);

create or replace function public.app_get_my_appointments(p_email text)
returns table (
  id bigint,
  "doctorName" text,
  "doctorAssigned" text,
  "patientName" text,
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
language sql
security definer
set search_path = public
as $$
  select
    a.id,
    coalesce(nullif(trim(d.username), ''), split_part(d.email, '@', 1)) as "doctorName",
    d.email as "doctorAssigned",
    coalesce(nullif(trim(p.username), ''), split_part(p.email, '@', 1)) as "patientName",
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
  where lower(trim(d.email)) = lower(trim(p_email))
     or lower(trim(p.email)) = lower(trim(p_email))
  order by a.created_at desc, a.start_time desc;
$$;

revoke all on function public.app_get_my_appointments(text) from public;
grant execute on function public.app_get_my_appointments(text) to authenticated;

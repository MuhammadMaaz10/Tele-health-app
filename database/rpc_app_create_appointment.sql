-- Run in Supabase SQL Editor (once)
create or replace function public.app_create_appointment(
  p_doctor_email text,
  p_patient_email text,
  p_short_description text,
  p_appointment_start_time timestamptz,
  p_appointment_end_time timestamptz,
  p_appointment_time text default '',
  p_status text default 'PENDING'
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
declare
  v_doctor_id uuid;
  v_patient_id uuid;
  v_inserted_id bigint;
begin
  select p.id into v_doctor_id
  from public.profiles p
  where lower(trim(p.email)) = lower(trim(p_doctor_email))
    and p.enabled = true
  limit 1;

  select p.id into v_patient_id
  from public.profiles p
  where lower(trim(p.email)) = lower(trim(p_patient_email))
    and p.enabled = true
  limit 1;

  if v_doctor_id is null then
    raise exception 'Doctor not found or disabled.';
  end if;
  if v_patient_id is null then
    raise exception 'Patient not found or disabled.';
  end if;

  if not (public.user_has_role(v_doctor_id, 'DOCTOR') or public.user_has_role(v_doctor_id, 'NURSE')) then
    raise exception 'Selected doctor email is not a practitioner.';
  end if;

  if not public.user_has_role(v_patient_id, 'PATIENT') then
    raise exception 'Selected patient email is not a patient.';
  end if;

  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;

  if auth.uid() <> v_doctor_id and auth.uid() <> v_patient_id then
    raise exception 'You can only create appointments where you are a participant.';
  end if;

  insert into public.appointments (
    doctor_id,
    patient_id,
    description,
    start_time,
    end_time,
    appointment_time,
    status,
    rescheduled
  )
  values (
    v_doctor_id,
    v_patient_id,
    coalesce(p_short_description, ''),
    p_appointment_start_time,
    p_appointment_end_time,
    coalesce(p_appointment_time, ''),
    coalesce(p_status, 'PENDING')::public.appointment_status,
    false
  )
  returning appointments.id into v_inserted_id;

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
  where a.id = v_inserted_id;
end;
$$;

revoke all on function public.app_create_appointment(text, text, text, timestamptz, timestamptz, text, text) from public;
grant execute on function public.app_create_appointment(text, text, text, timestamptz, timestamptz, text, text) to authenticated;

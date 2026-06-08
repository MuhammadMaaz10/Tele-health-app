-- =============================================================================
-- Telehealth — baseline schema (Postgres / Supabase)
-- Source of truth for what was applied in the SQL Editor.
-- Re-apply cautiously on non-empty databases (prefer migrations for changes).
-- =============================================================================

create extension if not exists "pgcrypto";

-- Enums
do $$ begin
  create type public.appointment_status as enum (
    'PENDING', 'CONFIRMED', 'RESCHEDULED', 'CANCELLED', 'COMPLETED'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.appointment_note_type as enum (
    'SUBJECTIVE', 'OBJECTIVE', 'ASSESSMENT', 'PLAN', 'GENERAL',
    'FOLLOW_UP', 'EMERGENCY', 'ROUTINE'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.approval_status as enum (
    'pending', 'approved', 'rejected'
  );
exception when duplicate_object then null;
end $$;

-- Roles
create table if not exists public.roles (
  id smallserial primary key,
  name text not null unique,
  constraint roles_name_upper_chk check (name = upper(name))
);

insert into public.roles (name) values
  ('PATIENT'), ('DOCTOR'), ('NURSE')
on conflict (name) do nothing;

-- Profiles
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  phone text,
  username text,
  enabled boolean not null default true,
  latitude double precision,
  longitude double precision,
  dob date,
  gender text,
  specialization text,
  profile_pic_url text,
  id_document_url text,
  medical_certificate_url text,
  educational_certificate_url text,
  approval_status public.approval_status not null default 'approved',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_email on public.profiles (email);

-- User roles
create table if not exists public.user_roles (
  user_id uuid not null references public.profiles (id) on delete cascade,
  role_id smallint not null references public.roles (id) on delete restrict,
  primary key (user_id, role_id)
);

create index if not exists idx_user_roles_role on public.user_roles (role_id);

-- Appointments
create table if not exists public.appointments (
  id bigserial primary key,
  doctor_id uuid not null references public.profiles (id) on delete restrict,
  patient_id uuid not null references public.profiles (id) on delete restrict,
  description text not null default '',
  start_time timestamptz not null,
  end_time timestamptz not null,
  appointment_time text not null default '',
  status public.appointment_status not null default 'PENDING',
  rescheduled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz,
  constraint appointments_time_chk check (end_time > start_time)
);

create index if not exists idx_appointments_doctor on public.appointments (doctor_id);
create index if not exists idx_appointments_patient on public.appointments (patient_id);
create index if not exists idx_appointments_start on public.appointments (start_time);

-- Notes
create table if not exists public.appointment_notes (
  id bigserial primary key,
  appointment_id bigint not null references public.appointments (id) on delete cascade,
  author_id uuid references public.profiles (id) on delete set null,
  note_type public.appointment_note_type,
  clinical_notes text not null default '',
  diagnosis text not null default '',
  treatment_plan text not null default '',
  observations text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists idx_appointment_notes_appt on public.appointment_notes (appointment_id);

-- Video metadata
create table if not exists public.appointment_video_sessions (
  id bigserial primary key,
  appointment_id bigint not null references public.appointments (id) on delete cascade,
  room_name text not null default '',
  access_token text,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  ended_ok boolean not null default false
);

create index if not exists idx_video_sessions_appt on public.appointment_video_sessions (appointment_id);

-- Triggers
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_appointments_updated_at on public.appointments;
create trigger trg_appointments_updated_at
before update on public.appointments
for each row execute function public.set_updated_at();

-- Profile rows are created by the app after OTP verification (no trigger on auth.users).
-- If you previously had handle_new_user, run database/rpc_remove_profile_auto_insert.sql.

-- RLS helpers
create or replace function public.user_role_names(uid uuid)
returns text[] language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(r.name order by r.name), '{}')
  from public.user_roles ur
  join public.roles r on r.id = ur.role_id
  where ur.user_id = uid;
$$;

create or replace function public.user_has_role(uid uuid, role_name text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = uid and r.name = role_name
  );
$$;

create or replace function public.is_appointment_participant(appt_id bigint, uid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.appointments a
    where a.id = appt_id and (a.doctor_id = uid or a.patient_id = uid)
  );
$$;

-- Directory RPCs for Create Appointment dropdowns
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

create or replace function public.app_get_doctors_directory()
returns table(email text, username text, enabled boolean)
language sql
security definer
set search_path = public
as $$
  select p.email, p.username, p.enabled
  from public.profiles p
  where p.enabled = true
    and public.user_has_role(p.id, 'DOCTOR')
  order by p.email asc;
$$;

create or replace function public.app_get_nurses_directory()
returns table(email text, username text, enabled boolean)
language sql
security definer
set search_path = public
as $$
  select p.email, p.username, p.enabled
  from public.profiles p
  where p.enabled = true
    and public.user_has_role(p.id, 'NURSE')
  order by p.email asc;
$$;

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

-- RLS
alter table public.roles enable row level security;
alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.appointments enable row level security;
alter table public.appointment_notes enable row level security;
alter table public.appointment_video_sessions enable row level security;

drop policy if exists "roles_select_authenticated" on public.roles;
create policy "roles_select_authenticated" on public.roles for select to authenticated using (true);

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select to authenticated using (id = auth.uid());

drop policy if exists "profiles_select_directory_practitioners" on public.profiles;
create policy "profiles_select_directory_practitioners" on public.profiles for select to authenticated
using (public.user_has_role(id, 'DOCTOR') or public.user_has_role(id, 'NURSE'));

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles for insert to authenticated with check (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update to authenticated
using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "user_roles_select_own" on public.user_roles;
create policy "user_roles_select_own" on public.user_roles for select to authenticated using (user_id = auth.uid());

drop policy if exists "user_roles_select_directory" on public.user_roles;
create policy "user_roles_select_directory" on public.user_roles for select to authenticated
using (public.user_has_role(user_id, 'DOCTOR') or public.user_has_role(user_id, 'NURSE'));

drop policy if exists "user_roles_insert_own" on public.user_roles;
create policy "user_roles_insert_own" on public.user_roles for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "user_roles_delete_own" on public.user_roles;
create policy "user_roles_delete_own" on public.user_roles for delete to authenticated using (user_id = auth.uid());

drop policy if exists "appointments_select_participants" on public.appointments;
create policy "appointments_select_participants" on public.appointments for select to authenticated
using (doctor_id = auth.uid() or patient_id = auth.uid());

drop policy if exists "appointments_insert_patient_creates" on public.appointments;
create policy "appointments_insert_patient_creates" on public.appointments for insert to authenticated
with check (patient_id = auth.uid() and public.user_has_role(auth.uid(), 'PATIENT'));

drop policy if exists "appointments_update_participants" on public.appointments;
create policy "appointments_update_participants" on public.appointments for update to authenticated
using (doctor_id = auth.uid() or patient_id = auth.uid())
with check (doctor_id = auth.uid() or patient_id = auth.uid());

drop policy if exists "appointments_delete_participants" on public.appointments;
create policy "appointments_delete_participants" on public.appointments for delete to authenticated
using (doctor_id = auth.uid() or patient_id = auth.uid());

drop policy if exists "appointment_notes_select_participants" on public.appointment_notes;
create policy "appointment_notes_select_participants" on public.appointment_notes for select to authenticated
using (public.is_appointment_participant(appointment_id, auth.uid()));

drop policy if exists "appointment_notes_insert_practitioner" on public.appointment_notes;
create policy "appointment_notes_insert_practitioner" on public.appointment_notes for insert to authenticated
with check (
  public.is_appointment_participant(appointment_id, auth.uid())
  and (public.user_has_role(auth.uid(), 'DOCTOR') or public.user_has_role(auth.uid(), 'NURSE'))
  and author_id = auth.uid()
);

drop policy if exists "appointment_notes_update_author_practitioner" on public.appointment_notes;
create policy "appointment_notes_update_author_practitioner" on public.appointment_notes for update to authenticated
using (
  author_id = auth.uid()
  and (public.user_has_role(auth.uid(), 'DOCTOR') or public.user_has_role(auth.uid(), 'NURSE'))
)
with check (
  author_id = auth.uid()
  and (public.user_has_role(auth.uid(), 'DOCTOR') or public.user_has_role(auth.uid(), 'NURSE'))
);

drop policy if exists "appointment_notes_delete_author" on public.appointment_notes;
create policy "appointment_notes_delete_author" on public.appointment_notes for delete to authenticated
using (author_id = auth.uid());

drop policy if exists "video_sessions_select_participants" on public.appointment_video_sessions;
create policy "video_sessions_select_participants" on public.appointment_video_sessions for select to authenticated
using (public.is_appointment_participant(appointment_id, auth.uid()));

drop policy if exists "video_sessions_insert_participants" on public.appointment_video_sessions;
create policy "video_sessions_insert_participants" on public.appointment_video_sessions for insert to authenticated
with check (public.is_appointment_participant(appointment_id, auth.uid()));

drop policy if exists "video_sessions_update_participants" on public.appointment_video_sessions;
create policy "video_sessions_update_participants" on public.appointment_video_sessions for update to authenticated
using (public.is_appointment_participant(appointment_id, auth.uid()))
with check (public.is_appointment_participant(appointment_id, auth.uid()));

-- Storage buckets
insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true), ('documents', 'documents', false)
on conflict (id) do nothing;

drop policy if exists "avatars_select_authenticated" on storage.objects;
create policy "avatars_select_authenticated" on storage.objects for select to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_insert_authenticated" on storage.objects;
create policy "avatars_insert_authenticated" on storage.objects for insert to authenticated
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_update_authenticated" on storage.objects;
create policy "avatars_update_authenticated" on storage.objects for update to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars_delete_authenticated" on storage.objects;
create policy "avatars_delete_authenticated" on storage.objects for delete to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "documents_select_own" on storage.objects;
create policy "documents_select_own" on storage.objects for select to authenticated
using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "documents_insert_own" on storage.objects;
create policy "documents_insert_own" on storage.objects for insert to authenticated
with check (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "documents_update_own" on storage.objects;
create policy "documents_update_own" on storage.objects for update to authenticated
using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "documents_delete_own" on storage.objects;
create policy "documents_delete_own" on storage.objects for delete to authenticated
using (bucket_id = 'documents' and (storage.foldername(name))[1] = auth.uid()::text);

-- Sign-up email lookup (replaces REST /check-email). Also in database/rpc_app_check_signup_email.sql
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

revoke all on function public.app_get_patients_directory() from public;
grant execute on function public.app_get_patients_directory() to authenticated;

revoke all on function public.app_get_doctors_directory() from public;
grant execute on function public.app_get_doctors_directory() to authenticated;

revoke all on function public.app_get_nurses_directory() from public;
grant execute on function public.app_get_nurses_directory() to authenticated;

revoke all on function public.app_create_appointment(text, text, text, timestamptz, timestamptz, text, text) from public;
grant execute on function public.app_create_appointment(text, text, text, timestamptz, timestamptz, text, text) to authenticated;

revoke all on function public.app_update_appointment(bigint, timestamptz, timestamptz, text) from public;
grant execute on function public.app_update_appointment(bigint, timestamptz, timestamptz, text) to authenticated;

revoke all on function public.app_set_appointment_status(bigint, text) from public;
grant execute on function public.app_set_appointment_status(bigint, text) to authenticated;

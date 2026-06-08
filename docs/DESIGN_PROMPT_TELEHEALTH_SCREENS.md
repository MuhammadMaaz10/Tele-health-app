# Telehealth App – Design Prompt for Patient & Doctor Modules

Use this prompt with **Replit** (for UI mockups/wireframes) or **Cursor** (for Flutter implementation) to design or build screens for both mobile and web. Copy the paragraph(s) you need below.

---

## Single Paragraph Prompt (Replit / Cursor)

**Design the following screens for a telehealth Flutter app, supporting both Patient and Doctor modules, with responsive layouts for mobile (portrait/landscape) and web (breakpoints: &lt;600 mobile, 600–1024 tablet, &gt;1024 desktop). Use a clean medical/clinical aesthetic with primary blue (#6CA6FF), light gray background (#F5F5F5), white cards, and clear typography (e.g. Inter).**

**Patient module:** (1) **Dashboard:** greeting “Hi, [username]” and “Let’s finish your task today!”, a Statistics row with four cards (Total, Confirmed, Completed, Cancelled appointment counts with icons), an “Upcoming Appointments” horizontal list (up to 3 cards showing doctor name, date, time, description, status chip: Pending/Confirmed/Rescheduled/Cancelled/Completed), “View All” link, and Quick Actions (New Appointment, View All). (2) **Create Appointment:** form with Doctor Email (searchable dropdown), Description, Appointment Date (date picker), Appointment Time (time picker), info note “Appointments must be scheduled within 14 days from today”, and Create Appointment button. (3) **Appointments list (Get appointments):** page title “My Appointments”, refresh and add buttons, filter tabs (All, Confirmed, Cancelled), list or grid of appointment cards showing date badge (day + month), description, status badge, time, duration in minutes, and Doctor row (label “Doctor” + doctor email/name); each card has Details button; empty state with “No appointments found” and hint to create one. (4) **Appointment details:** segmented tabs “Appointment Details” and “Notes”; Details tab shows status badge, description (expandable if long), date, time, duration, rescheduled flag, People (Doctor / Patient emails), appointment created date; actions: Start Video Call / End Video Call (if confirmed and upcoming), Reschedule, Cancel; for patients no Confirm button. (5) **Notes screen (view):** section “Existing Notes” listing note cards with created date/time, Clinical Notes, Diagnosis, Treatment Plan, Observations; patients see read-only list only, no add/edit. (6) **Add/Edit notes (doctor only):** same Notes screen but with form below existing notes: Note Type dropdown (Subjective, Objective, Assessment, Plan, General, Follow Up, Emergency, Routine), Clinical Notes, Diagnosis, Treatment Plan, Observations (multiline fields), Add Note / Update Note button, and per-note Edit/Delete for doctors.

**Doctor module:** (1) **Dashboard:** same layout as patient but stats reflect doctor’s appointments; upcoming cards show **Patient** name and patient email instead of doctor; Quick Actions unchanged (New Appointment, View All). (2) **Create Appointment:** form shows **Patient Email** (searchable dropdown) instead of Doctor Email, plus Description, Date, Time, same info note and Create button. (3) **Appointments list:** same as patient but cards show “Patient” and patient email; filter tabs same; list/grid same; add Confirm button on cards for Pending appointments. (4) **Appointment details:** same as patient plus “Confirm Appointment” for Pending; Start/End Video, Reschedule, Cancel same. (5) **Notes screen (view):** same existing-notes list; doctors also see Add/Edit form and Edit/Delete on each note card.

**Data to display:** Appointment: id, doctorAssigned, patientBooked, startTime, endTime, description, status (PENDING, CONFIRMED, RESCHEDULED, CANCELLED, COMPLETED), createdAt, rescheduled, duration (endTime − startTime); format date as DD-MM-YYYY and time as HH:mm. Note: id, noteType, clinicalNotes, diagnosis, treatmentPlan, observations, createdAt; show formatted date/time on note cards. User: show username or email prefix for “Hi, [name]”; in dropdowns show email (and optional display name). **Responsive behavior:** mobile single column, 2 stat cards per row; tablet/desktop 4 stat cards in one row; appointments list on web desktop use 2-column grid, on mobile use vertical list; navigation: bottom nav or drawer on mobile, sidebar on web desktop; forms and detail views use max-width (e.g. 800px) on large screens and full-width on small. **Accessibility:** sufficient contrast, touch targets ≥44px on mobile, focus states for web. Produce high-fidelity wireframes (Replit) or Flutter UI code (Cursor) that matches this spec for both modules and both platforms.

---

## Shorter Prompt (Copy-Paste Ready)

Design all screens for a telehealth app’s **Patient** and **Doctor** modules for **mobile and web**. Include: (1) **Dashboards** — greeting, 4 stat cards (Total, Confirmed, Completed, Cancelled), upcoming appointments (3 cards; show doctor for patient, patient for doctor), Quick Actions (New Appointment, View All). (2) **Create Appointment** — Patient: Doctor dropdown + description + date + time + create button; Doctor: Patient dropdown + same fields; both: “within 14 days” note. (3) **Get/List Appointments** — title “My Appointments”, filters (All / Confirmed / Cancelled), cards with date, time, duration, description, status, Doctor/Patient row; Details button; Doctor sees Confirm on Pending. (4) **Appointment Details** — tabs: Details (status, description, date, time, duration, people, created date; actions: Video Start/End, Reschedule, Cancel; Doctor: Confirm if Pending) and Notes. (5) **Notes screen** — list of notes (clinical notes, diagnosis, treatment plan, observations, date); **Add notes (Doctor only)** — Note Type dropdown, clinical notes, diagnosis, treatment plan, observations, Add/Update button; Edit/Delete per note for doctor. Use primary #6CA6FF, background #F5F5F5; responsive (mobile &lt;600, tablet 600–1024, desktop &gt;1024); same layout rules for both roles with role-specific labels and actions. Output wireframes or Flutter UI for both modules and both platforms.

---

## Per-Screen Checklist (Reference)

| Screen | Patient | Doctor | Mobile | Web |
|--------|---------|--------|--------|-----|
| Dashboard | ✓ greeting, stats, upcoming (doctor info), quick actions | ✓ same, upcoming shows patient | ✓ | ✓ |
| Create Appointment | Doctor dropdown, description, date, time | Patient dropdown, same fields | ✓ | ✓ |
| Appointments List | Filters, cards, Details | + Confirm on Pending | ✓ list | ✓ grid 2-col |
| Appointment Details | Tabs: Details + Notes; Video, Reschedule, Cancel | + Confirm if Pending | ✓ | ✓ |
| Notes (view) | Read-only list of note cards | Read-only list | ✓ | ✓ |
| Add/Edit Notes | — | Form + Edit/Delete on cards | ✓ | ✓ |

---

*Generated for telehealth_app; align with `lib/features/*` and `lib/core/theme/app_colors.dart`.*

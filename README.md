# University Portal

A production-ready Flutter + Supabase university portal MVP for ~1,000 students.

## Features

| Role | Features |
|------|----------|
| **Student** | Login (roll number/email), Profile, Attendance (period-wise + %), Results (marks + grades), Hall Ticket download, Notices, Timetable |
| **Teacher** | Login, Mark Attendance (per student per period), Attendance Reports, Timetable, Notices |
| **Admin (Web)** | Academic structure management, Bulk CSV import, Upload & publish results (CSV), Upload & publish hall tickets (PDF), Notices, Timetable management |

## Tech Stack

- **Frontend:** Flutter 3.x (Android + iOS + Web — single codebase)
- **Backend:** Supabase (PostgreSQL + Auth + Storage + RLS)
- **Routing:** `go_router`
- **State:** `flutter_riverpod`
- **CI/CD:** GitHub Actions → Flutter Web build

## Security

- Row-Level Security (RLS) on **all** database tables
- Students can only see their own data; teachers only their class data
- Only **published** results and hall tickets are visible to students
- File uploads restricted to PDF only, 10 MB max
- Signed URLs for hall ticket downloads (1-hour TTL)
- Secrets loaded via `--dart-define` at build time — never hardcoded
- HTTPS enforced via Supabase + Cloudflare/Vercel

## Project Structure

```
project-r/
├── app/                         # Flutter application
│   ├── lib/
│   │   ├── main.dart            # Entry point (Supabase init)
│   │   ├── app.dart             # Router + MaterialApp
│   │   ├── core/
│   │   │   ├── constants/       # AppConstants (roles, limits, buckets)
│   │   │   ├── services/        # Supabase, Auth, Attendance, Results, HallTicket, Notice, Timetable
│   │   │   ├── theme/           # Material 3 theme
│   │   │   └── utils/           # Validators, date helpers, snackbar utils
│   │   └── features/
│   │       ├── auth/            # Login screen
│   │       ├── student/         # Home, Attendance, Results, Hall Ticket, Timetable
│   │       ├── teacher/         # Home, Mark Attendance, Reports, Timetable
│   │       ├── admin/           # All admin management screens
│   │       └── shared/          # Splash, Notices, Profile
│   └── test/
│       ├── unit/                # Validators, constants, date utils
│       └── widget/              # Login screen widget tests
├── supabase/
│   ├── schema.sql               # 16 tables with indexes
│   ├── policies.sql             # Full RLS policies
│   └── init.sql                 # Seed data (sample students/teachers/results)
├── data/
│   └── templates/               # CSV import templates
│       ├── students_template.csv
│       ├── teachers_template.csv
│       ├── subjects_template.csv
│       ├── enrollments_template.csv
│       └── results_template.csv
└── .github/
    └── workflows/
        └── flutter_web.yml      # CI: analyze + test + build web
```

## Local Setup

### Prerequisites

- Flutter SDK 3.22+ ([install](https://docs.flutter.dev/get-started/install))
- A [Supabase](https://supabase.com) project (free tier works)

### Step 1: Set up Supabase

1. Create a project at [supabase.com](https://supabase.com)
2. In the **SQL Editor**, run files **in this order**:
   ```
   supabase/schema.sql     → creates all 16 tables + indexes
   supabase/policies.sql   → enables RLS + creates all policies
   supabase/init.sql       → seeds sample data (read instructions inside)
   ```
3. In **Storage**, create private buckets: `hall-tickets`, `documents`, `profile-photos`

### Step 2: Create Auth Users

Students log in with their **roll number** (e.g. `2024CS001`) — the app converts it to `2024cs001@portal.local` internally.

Create users via **Supabase Dashboard → Authentication → Users** or via the API:

```bash
# Admin user
curl -X POST 'https://YOUR_PROJECT.supabase.co/auth/v1/admin/users' \
  -H 'apikey: YOUR_SERVICE_ROLE_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@portal.local","password":"ChangeMe@123","email_confirm":true}'

# Student user (roll number login)
curl -X POST 'https://YOUR_PROJECT.supabase.co/auth/v1/admin/users' \
  -H 'apikey: YOUR_SERVICE_ROLE_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"email":"2024cs001@portal.local","password":"TempPass@123","email_confirm":true}'
```

After creating users, update the UUID placeholders in `init.sql` and run it.

### Step 3: Run the App

```bash
cd app
flutter pub get

# Web (Chrome)
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key

# Android
flutter run -d android \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key

# iOS (macOS only)
flutter run -d ios \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### Step 4: Run Tests

```bash
cd app
flutter test test/unit/
flutter test test/widget/
```

## CI/CD (GitHub Actions)

### Required Secrets

Add at **Settings → Secrets and variables → Actions**:

| Secret | Value |
|--------|-------|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon key |

The workflow: analyze → test → build web → upload artifact.

To deploy to Cloudflare Pages, uncomment the `deploy` job in `flutter_web.yml` and add `CLOUDFLARE_API_TOKEN` + `CLOUDFLARE_ACCOUNT_ID` secrets.

## Key Flows

### Attendance
1. Admin creates academic structure (programs → branches → batches → sections → subjects → course offerings → assigns teachers)
2. Teacher logs in → selects course offering → picks date + period → marks each student Present/Absent/Late
3. Student sees per-subject attendance % and full history

### Results
1. Admin fills `data/templates/results_template.csv` and uploads via Admin → Results → Import CSV
2. Imported results are **unpublished** (hidden from students)
3. Admin selects records → Publish
4. Students see marks + grade per subject, per semester

### Hall Tickets
1. Admin uploads PDF per student via Admin → Hall Tickets (using exam session label)
2. Uploaded tickets are **unpublished** by default
3. Admin publishes → Students can download via signed URL (1-hour expiry)

## Sample Login Credentials

After running `init.sql` and creating the matching auth users:

| Role | Login | Notes |
|------|-------|-------|
| Admin | `admin@portal.local` | Full admin access |
| Teacher | `teacher1@portal.local` | Teacher dashboard |
| Student | `2024CS001` (roll number) | Student dashboard |

> Change all default passwords in production.

## License

MIT

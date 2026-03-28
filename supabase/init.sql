-- =============================================================================
-- University Portal MVP — Seed / Init Data
-- Run AFTER schema.sql and policies.sql
--
-- HOW TO CREATE AUTH USERS (do this BEFORE running this file):
-- ─────────────────────────────────────────────────────────────
-- Option A — Supabase Dashboard
--   Authentication → Users → "Invite user" (or "Add user")
--   Create one user per row in the profiles INSERT below.
--   Copy the generated UUIDs and paste them into this file.
--
-- Option B — Supabase Management API (scripted)
--   POST https://<project-ref>.supabase.co/auth/v1/admin/users
--   Headers: apikey: <service_role_key>, Authorization: Bearer <service_role_key>
--   Body: { "email": "...", "password": "...", "email_confirm": true }
--   The response contains the UUID to use below.
--
-- Option C — Supabase CLI
--   supabase users create --email student1@uni.edu --password SecurePass1!
--
-- Replace every placeholder UUID below with the real auth.users IDs.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Placeholder UUIDs
-- Replace these with real auth.users UUIDs before running.
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  RAISE NOTICE
    'REMINDER: Replace placeholder UUIDs with real auth.users IDs before executing init.sql';
END;
$$;


-- ===========================================================================
-- PROGRAMS
-- ===========================================================================
INSERT INTO programs (id, name, code) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Bachelor of Technology', 'BTECH'),
  ('00000000-0000-0000-0000-000000000002', 'Master of Technology',   'MTECH')
ON CONFLICT (code) DO NOTHING;


-- ===========================================================================
-- BRANCHES
-- ===========================================================================
INSERT INTO branches (id, program_id, name, code) VALUES
  -- B.Tech branches
  ('00000000-0000-0000-0001-000000000001',
   '00000000-0000-0000-0000-000000000001', 'Computer Science & Engineering',    'CSE'),
  ('00000000-0000-0000-0001-000000000002',
   '00000000-0000-0000-0000-000000000001', 'Electronics & Communication Engineering', 'ECE'),
  ('00000000-0000-0000-0001-000000000003',
   '00000000-0000-0000-0000-000000000001', 'Mechanical Engineering',             'MECH'),
  -- M.Tech branch
  ('00000000-0000-0000-0001-000000000004',
   '00000000-0000-0000-0000-000000000002', 'Computer Science & Engineering',    'MCSE')
ON CONFLICT (code) DO NOTHING;


-- ===========================================================================
-- BATCHES  (current admitted cohort — 2022)
-- ===========================================================================
INSERT INTO batches (id, branch_id, name, year) VALUES
  -- CSE batches
  ('00000000-0000-0000-0002-000000000001',
   '00000000-0000-0000-0001-000000000001', '2022-26', 2022),
  ('00000000-0000-0000-0002-000000000002',
   '00000000-0000-0000-0001-000000000001', '2021-25', 2021),
  -- ECE batch
  ('00000000-0000-0000-0002-000000000003',
   '00000000-0000-0000-0001-000000000002', '2022-26', 2022),
  -- MECH batch
  ('00000000-0000-0000-0002-000000000004',
   '00000000-0000-0000-0001-000000000003', '2022-26', 2022)
ON CONFLICT DO NOTHING;


-- ===========================================================================
-- SECTIONS
-- ===========================================================================
INSERT INTO sections (id, batch_id, name) VALUES
  -- CSE 2022-26
  ('00000000-0000-0000-0003-000000000001',
   '00000000-0000-0000-0002-000000000001', 'A'),
  ('00000000-0000-0000-0003-000000000002',
   '00000000-0000-0000-0002-000000000001', 'B'),
  -- CSE 2021-25
  ('00000000-0000-0000-0003-000000000003',
   '00000000-0000-0000-0002-000000000002', 'A'),
  -- ECE 2022-26
  ('00000000-0000-0000-0003-000000000004',
   '00000000-0000-0000-0002-000000000003', 'A'),
  -- MECH 2022-26
  ('00000000-0000-0000-0003-000000000005',
   '00000000-0000-0000-0002-000000000004', 'A')
ON CONFLICT DO NOTHING;


-- ===========================================================================
-- SUBJECTS  (Semester 5 — CSE core)
-- ===========================================================================
INSERT INTO subjects (id, name, code, credits) VALUES
  ('00000000-0000-0000-0004-000000000001', 'Data Structures',           'CS301', 4),
  ('00000000-0000-0000-0004-000000000002', 'Design & Analysis of Algorithms', 'CS302', 4),
  ('00000000-0000-0000-0004-000000000003', 'Database Management Systems',    'CS303', 4),
  ('00000000-0000-0000-0004-000000000004', 'Computer Networks',          'CS304', 3),
  ('00000000-0000-0000-0004-000000000005', 'Operating Systems',          'CS305', 4),
  -- ECE subjects
  ('00000000-0000-0000-0004-000000000006', 'Digital Signal Processing',  'EC301', 4),
  ('00000000-0000-0000-0004-000000000007', 'Microprocessors & Interfacing', 'EC302', 3)
ON CONFLICT (code) DO NOTHING;


-- ===========================================================================
-- PROFILES
-- ---------------------------------------------------------------------------
-- Replace the UUIDs below with the real IDs from auth.users.
-- Sample layout:
--   1 admin, 3 teachers (t1=CSE, t2=CSE/DBMS, t3=ECE), 6 students
-- ===========================================================================

-- ── Admin ───────────────────────────────────────────────────────────────────
-- Auth user: admin@uni.edu  (create in dashboard first)
INSERT INTO profiles
  (id, role, name, email, phone,
   program_id, branch_id, batch_id, section_id,
   program, branch, batch, section, semester)
VALUES
  (
    'aaaaaaaa-0000-0000-0000-000000000001',  -- REPLACE with real auth.users UUID
    'admin',
    'Portal Admin',
    'admin@uni.edu',
    '+91-9000000001',
    NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL
  )
ON CONFLICT (id) DO NOTHING;

-- ── Teachers ────────────────────────────────────────────────────────────────
-- Auth users: teacher1@uni.edu, teacher2@uni.edu, teacher3@uni.edu
INSERT INTO profiles
  (id, role, name, email, phone,
   program_id, branch_id, batch_id, section_id,
   program, branch, batch, section, semester)
VALUES
  (
    'bbbbbbbb-0000-0000-0000-000000000001',  -- REPLACE
    'teacher', 'Dr. Priya Sharma', 'teacher1@uni.edu', '+91-9000000002',
    NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000002',  -- REPLACE
    'teacher', 'Prof. Arjun Mehta', 'teacher2@uni.edu', '+91-9000000003',
    NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL
  ),
  (
    'bbbbbbbb-0000-0000-0000-000000000003',  -- REPLACE
    'teacher', 'Dr. Kavitha Nair', 'teacher3@uni.edu', '+91-9000000004',
    NULL, NULL, NULL, NULL,
    NULL, NULL, NULL, NULL, NULL
  )
ON CONFLICT (id) DO NOTHING;

-- ── Students — CSE 2022-26 Section A ────────────────────────────────────────
INSERT INTO profiles
  (id, role, roll_number, name, email, phone,
   program_id, branch_id, batch_id, section_id,
   program, branch, batch, section, semester)
VALUES
  (
    'cccccccc-0000-0000-0000-000000000001',  -- REPLACE
    'student', '22CS001', 'Aarav Patel', 'aarav.patel@student.uni.edu',
    '+91-9000000010',
    '00000000-0000-0000-0000-000000000001',  -- B.Tech
    '00000000-0000-0000-0001-000000000001',  -- CSE
    '00000000-0000-0000-0002-000000000001',  -- 2022-26
    '00000000-0000-0000-0003-000000000001',  -- Section A
    'Bachelor of Technology', 'CSE', '2022-26', 'A', 5
  ),
  (
    'cccccccc-0000-0000-0000-000000000002',  -- REPLACE
    'student', '22CS002', 'Bhavna Iyer', 'bhavna.iyer@student.uni.edu',
    '+91-9000000011',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0001-000000000001',
    '00000000-0000-0000-0002-000000000001',
    '00000000-0000-0000-0003-000000000001',
    'Bachelor of Technology', 'CSE', '2022-26', 'A', 5
  ),
  (
    'cccccccc-0000-0000-0000-000000000003',  -- REPLACE
    'student', '22CS003', 'Chirag Desai', 'chirag.desai@student.uni.edu',
    '+91-9000000012',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0001-000000000001',
    '00000000-0000-0000-0002-000000000001',
    '00000000-0000-0000-0003-000000000001',
    'Bachelor of Technology', 'CSE', '2022-26', 'A', 5
  )
ON CONFLICT (id) DO NOTHING;

-- ── Students — CSE 2022-26 Section B ────────────────────────────────────────
INSERT INTO profiles
  (id, role, roll_number, name, email, phone,
   program_id, branch_id, batch_id, section_id,
   program, branch, batch, section, semester)
VALUES
  (
    'cccccccc-0000-0000-0000-000000000004',  -- REPLACE
    'student', '22CS051', 'Divya Reddy', 'divya.reddy@student.uni.edu',
    '+91-9000000013',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0001-000000000001',
    '00000000-0000-0000-0002-000000000001',
    '00000000-0000-0000-0003-000000000002',  -- Section B
    'Bachelor of Technology', 'CSE', '2022-26', 'B', 5
  ),
  (
    'cccccccc-0000-0000-0000-000000000005',  -- REPLACE
    'student', '22CS052', 'Eshan Gupta', 'eshan.gupta@student.uni.edu',
    '+91-9000000014',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0001-000000000001',
    '00000000-0000-0000-0002-000000000001',
    '00000000-0000-0000-0003-000000000002',  -- Section B
    'Bachelor of Technology', 'CSE', '2022-26', 'B', 5
  )
ON CONFLICT (id) DO NOTHING;

-- ── Student — ECE 2022-26 Section A ─────────────────────────────────────────
INSERT INTO profiles
  (id, role, roll_number, name, email, phone,
   program_id, branch_id, batch_id, section_id,
   program, branch, batch, section, semester)
VALUES
  (
    'cccccccc-0000-0000-0000-000000000006',  -- REPLACE
    'student', '22EC001', 'Farhan Khan', 'farhan.khan@student.uni.edu',
    '+91-9000000015',
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0001-000000000002',  -- ECE
    '00000000-0000-0000-0002-000000000003',  -- ECE 2022-26
    '00000000-0000-0000-0003-000000000004',  -- ECE Section A
    'Bachelor of Technology', 'ECE', '2022-26', 'A', 5
  )
ON CONFLICT (id) DO NOTHING;


-- ===========================================================================
-- COURSE OFFERINGS  (Academic Year 2024-25, Semester 5)
-- ===========================================================================
INSERT INTO course_offerings
  (id, subject_id, section_id, teacher_id, semester, academic_year)
VALUES
  -- CSE 2022-26 Section A
  ('00000000-0000-0000-0005-000000000001',
   '00000000-0000-0000-0004-000000000001',   -- Data Structures
   '00000000-0000-0000-0003-000000000001',   -- CSE-A
   'bbbbbbbb-0000-0000-0000-000000000001',   -- Dr. Priya Sharma
   5, '2024-25'),

  ('00000000-0000-0000-0005-000000000002',
   '00000000-0000-0000-0004-000000000002',   -- Algorithms
   '00000000-0000-0000-0003-000000000001',   -- CSE-A
   'bbbbbbbb-0000-0000-0000-000000000001',   -- Dr. Priya Sharma
   5, '2024-25'),

  ('00000000-0000-0000-0005-000000000003',
   '00000000-0000-0000-0004-000000000003',   -- DBMS
   '00000000-0000-0000-0003-000000000001',   -- CSE-A
   'bbbbbbbb-0000-0000-0000-000000000002',   -- Prof. Arjun Mehta
   5, '2024-25'),

  ('00000000-0000-0000-0005-000000000004',
   '00000000-0000-0000-0004-000000000004',   -- Networks
   '00000000-0000-0000-0003-000000000001',   -- CSE-A
   'bbbbbbbb-0000-0000-0000-000000000002',   -- Prof. Arjun Mehta
   5, '2024-25'),

  ('00000000-0000-0000-0005-000000000005',
   '00000000-0000-0000-0004-000000000005',   -- OS
   '00000000-0000-0000-0003-000000000001',   -- CSE-A
   'bbbbbbbb-0000-0000-0000-000000000001',   -- Dr. Priya Sharma
   5, '2024-25'),

  -- CSE 2022-26 Section B (same teachers, different section)
  ('00000000-0000-0000-0005-000000000006',
   '00000000-0000-0000-0004-000000000001',   -- Data Structures
   '00000000-0000-0000-0003-000000000002',   -- CSE-B
   'bbbbbbbb-0000-0000-0000-000000000001',   -- Dr. Priya Sharma
   5, '2024-25'),

  ('00000000-0000-0000-0005-000000000007',
   '00000000-0000-0000-0004-000000000003',   -- DBMS
   '00000000-0000-0000-0003-000000000002',   -- CSE-B
   'bbbbbbbb-0000-0000-0000-000000000002',   -- Prof. Arjun Mehta
   5, '2024-25'),

  -- ECE 2022-26 Section A
  ('00000000-0000-0000-0005-000000000008',
   '00000000-0000-0000-0004-000000000006',   -- DSP
   '00000000-0000-0000-0003-000000000004',   -- ECE-A
   'bbbbbbbb-0000-0000-0000-000000000003',   -- Dr. Kavitha Nair
   5, '2024-25'),

  ('00000000-0000-0000-0005-000000000009',
   '00000000-0000-0000-0004-000000000007',   -- Microprocessors
   '00000000-0000-0000-0003-000000000004',   -- ECE-A
   'bbbbbbbb-0000-0000-0000-000000000003',   -- Dr. Kavitha Nair
   5, '2024-25')
ON CONFLICT DO NOTHING;


-- ===========================================================================
-- ENROLLMENTS  (wire students to their section offerings)
-- ===========================================================================
INSERT INTO enrollments (student_id, course_offering_id) VALUES
  -- CSE-A students → 5 CSE-A offerings
  ('cccccccc-0000-0000-0000-000000000001', '00000000-0000-0000-0005-000000000001'),
  ('cccccccc-0000-0000-0000-000000000001', '00000000-0000-0000-0005-000000000002'),
  ('cccccccc-0000-0000-0000-000000000001', '00000000-0000-0000-0005-000000000003'),
  ('cccccccc-0000-0000-0000-000000000001', '00000000-0000-0000-0005-000000000004'),
  ('cccccccc-0000-0000-0000-000000000001', '00000000-0000-0000-0005-000000000005'),

  ('cccccccc-0000-0000-0000-000000000002', '00000000-0000-0000-0005-000000000001'),
  ('cccccccc-0000-0000-0000-000000000002', '00000000-0000-0000-0005-000000000002'),
  ('cccccccc-0000-0000-0000-000000000002', '00000000-0000-0000-0005-000000000003'),
  ('cccccccc-0000-0000-0000-000000000002', '00000000-0000-0000-0005-000000000004'),
  ('cccccccc-0000-0000-0000-000000000002', '00000000-0000-0000-0005-000000000005'),

  ('cccccccc-0000-0000-0000-000000000003', '00000000-0000-0000-0005-000000000001'),
  ('cccccccc-0000-0000-0000-000000000003', '00000000-0000-0000-0005-000000000002'),
  ('cccccccc-0000-0000-0000-000000000003', '00000000-0000-0000-0005-000000000003'),
  ('cccccccc-0000-0000-0000-000000000003', '00000000-0000-0000-0005-000000000004'),
  ('cccccccc-0000-0000-0000-000000000003', '00000000-0000-0000-0005-000000000005'),

  -- CSE-B students → 2 CSE-B offerings
  ('cccccccc-0000-0000-0000-000000000004', '00000000-0000-0000-0005-000000000006'),
  ('cccccccc-0000-0000-0000-000000000004', '00000000-0000-0000-0005-000000000007'),

  ('cccccccc-0000-0000-0000-000000000005', '00000000-0000-0000-0005-000000000006'),
  ('cccccccc-0000-0000-0000-000000000005', '00000000-0000-0000-0005-000000000007'),

  -- ECE-A student → 2 ECE-A offerings
  ('cccccccc-0000-0000-0000-000000000006', '00000000-0000-0000-0005-000000000008'),
  ('cccccccc-0000-0000-0000-000000000006', '00000000-0000-0000-0005-000000000009')
ON CONFLICT DO NOTHING;


-- ===========================================================================
-- TIMETABLE ENTRIES
-- day_of_week: 0=Sunday, 1=Monday … 6=Saturday  (ISO-style)
-- University working week uses 1 (Monday) through 5 (Friday).
-- Periods: 1-8  (each slot 1 hour)
-- ===========================================================================
INSERT INTO timetable_entries
  (section_id, subject_id, teacher_id, day_of_week, period_number,
   room, academic_year, semester)
VALUES
  -- ── CSE-A  (Mon–Fri, periods 1-5 used) ───────────────────────────────────
  -- Monday
  ('00000000-0000-0000-0003-000000000001',
   '00000000-0000-0000-0004-000000000001',   -- Data Structures
   'bbbbbbbb-0000-0000-0000-000000000001',
   1, 1, 'CS-LAB-101', '2024-25', 5),

  ('00000000-0000-0000-0003-000000000001',
   '00000000-0000-0000-0004-000000000002',   -- Algorithms
   'bbbbbbbb-0000-0000-0000-000000000001',
   1, 2, 'CS-101', '2024-25', 5),

  ('00000000-0000-0000-0003-000000000001',
   '00000000-0000-0000-0004-000000000003',   -- DBMS
   'bbbbbbbb-0000-0000-0000-000000000002',
   1, 3, 'CS-102', '2024-25', 5),

  -- Tuesday
  ('00000000-0000-0000-0003-000000000001',
   '00000000-0000-0000-0004-000000000004',   -- Networks
   'bbbbbbbb-0000-0000-0000-000000000002',
   2, 1, 'CS-103', '2024-25', 5),

  ('00000000-0000-0000-0003-000000000001',
   '00000000-0000-0000-0004-000000000005',   -- OS
   'bbbbbbbb-0000-0000-0000-000000000001',
   2, 2, 'CS-104', '2024-25', 5),

  -- Wednesday
  ('00000000-0000-0000-0003-000000000001',
   '00000000-0000-0000-0004-000000000001',   -- Data Structures
   'bbbbbbbb-0000-0000-0000-000000000001',
   3, 1, 'CS-101', '2024-25', 5),

  ('00000000-0000-0000-0003-000000000001',
   '00000000-0000-0000-0004-000000000003',   -- DBMS
   'bbbbbbbb-0000-0000-0000-000000000002',
   3, 2, 'CS-102', '2024-25', 5),

  -- Thursday
  ('00000000-0000-0000-0003-000000000001',
   '00000000-0000-0000-0004-000000000002',   -- Algorithms
   'bbbbbbbb-0000-0000-0000-000000000001',
   4, 1, 'CS-LAB-101', '2024-25', 5),

  ('00000000-0000-0000-0003-000000000001',
   '00000000-0000-0000-0004-000000000004',   -- Networks
   'bbbbbbbb-0000-0000-0000-000000000002',
   4, 2, 'CS-103', '2024-25', 5),

  -- Friday
  ('00000000-0000-0000-0003-000000000001',
   '00000000-0000-0000-0004-000000000005',   -- OS
   'bbbbbbbb-0000-0000-0000-000000000001',
   5, 1, 'CS-104', '2024-25', 5),

  -- ── ECE-A  (Mon, Wed, Fri sample) ────────────────────────────────────────
  ('00000000-0000-0000-0003-000000000004',
   '00000000-0000-0000-0004-000000000006',   -- DSP
   'bbbbbbbb-0000-0000-0000-000000000003',
   1, 1, 'EC-201', '2024-25', 5),

  ('00000000-0000-0000-0003-000000000004',
   '00000000-0000-0000-0004-000000000007',   -- Microprocessors
   'bbbbbbbb-0000-0000-0000-000000000003',
   3, 1, 'EC-LAB-201', '2024-25', 5),

  ('00000000-0000-0000-0003-000000000004',
   '00000000-0000-0000-0004-000000000006',   -- DSP
   'bbbbbbbb-0000-0000-0000-000000000003',
   5, 1, 'EC-201', '2024-25', 5)
ON CONFLICT DO NOTHING;


-- ===========================================================================
-- SAMPLE ATTENDANCE SESSION + RECORDS
-- (demonstrates a complete attendance workflow for testing)
-- ===========================================================================

-- Session: Data Structures, CSE-A, 2024-07-15, Period 1
INSERT INTO attendance_sessions
  (id, course_offering_id, session_date, period_number, marked_by)
VALUES
  (
    '00000000-0000-0000-0006-000000000001',
    '00000000-0000-0000-0005-000000000001',   -- DS / CSE-A
    '2024-07-15',
    1,
    'bbbbbbbb-0000-0000-0000-000000000001'    -- Dr. Priya Sharma
  )
ON CONFLICT DO NOTHING;

-- Records for that session
INSERT INTO attendance_records (session_id, student_id, status)
VALUES
  ('00000000-0000-0000-0006-000000000001',
   'cccccccc-0000-0000-0000-000000000001', 'present'),
  ('00000000-0000-0000-0006-000000000001',
   'cccccccc-0000-0000-0000-000000000002', 'late'),
  ('00000000-0000-0000-0006-000000000001',
   'cccccccc-0000-0000-0000-000000000003', 'absent')
ON CONFLICT DO NOTHING;


-- ===========================================================================
-- SAMPLE RESULTS  (published and unpublished — tests RLS visibility)
-- ===========================================================================
INSERT INTO results
  (student_id, subject_id, semester, academic_year,
   marks_obtained, max_marks, grade, is_published, published_at, published_by)
VALUES
  -- Published result — student should see this
  (
    'cccccccc-0000-0000-0000-000000000001',
    '00000000-0000-0000-0004-000000000001',   -- DS
    5, '2024-25', 72, 100, 'B+', TRUE,
    NOW(), 'aaaaaaaa-0000-0000-0000-000000000001'
  ),
  -- Unpublished result — student should NOT see this via RLS
  (
    'cccccccc-0000-0000-0000-000000000001',
    '00000000-0000-0000-0004-000000000002',   -- Algorithms
    5, '2024-25', 85, 100, 'A',  FALSE, NULL, NULL
  ),
  (
    'cccccccc-0000-0000-0000-000000000002',
    '00000000-0000-0000-0004-000000000001',   -- DS
    5, '2024-25', 60, 100, 'B',  TRUE,
    NOW(), 'aaaaaaaa-0000-0000-0000-000000000001'
  )
ON CONFLICT DO NOTHING;


-- ===========================================================================
-- SAMPLE NOTICES
-- ===========================================================================
INSERT INTO notices
  (title, content, target_role, is_published, published_by)
VALUES
  (
    'Welcome to Semester 5',
    'Dear students and faculty, Semester 5 begins on 1st August 2024. '
    'Please check your timetables.',
    'all', TRUE,
    'aaaaaaaa-0000-0000-0000-000000000001'
  ),
  (
    'Hall Ticket Distribution',
    'Hall tickets for the End-Semester Examination (Nov-Dec 2024) will be '
    'available from 15th October 2024 on this portal.',
    'student', TRUE,
    'aaaaaaaa-0000-0000-0000-000000000001'
  ),
  (
    'Faculty Meeting — Exam Planning',
    'All faculty members are requested to attend the exam planning meeting '
    'on 20th September 2024 at 2:00 PM in Conference Room 1.',
    'teacher', TRUE,
    'aaaaaaaa-0000-0000-0000-000000000001'
  ),
  (
    'Draft: Upcoming Sports Day',
    'Sports Day is tentatively planned for November. Details TBD.',
    'all', FALSE,   -- draft — not yet published
    'aaaaaaaa-0000-0000-0000-000000000001'
  )
ON CONFLICT DO NOTHING;


-- ===========================================================================
-- SAMPLE DOCUMENTS
-- ===========================================================================
INSERT INTO documents
  (title, description, file_path, file_type, file_size, uploaded_by, target_role)
VALUES
  (
    'Data Structures — Lecture Notes Unit 1',
    'Covers arrays, linked lists, stacks, and queues.',
    'documents/cs301/ds-unit1-notes.pdf',
    'application/pdf', 2097152,    -- 2 MB
    'bbbbbbbb-0000-0000-0000-000000000001', 'student'
  ),
  (
    'Academic Calendar 2024-25',
    'Full academic calendar including exam dates and holidays.',
    'documents/general/academic-calendar-2024-25.pdf',
    'application/pdf', 512000,
    'aaaaaaaa-0000-0000-0000-000000000001', 'all'
  ),
  (
    'Grading Policy',
    'Detailed grading and attendance policy for faculty reference.',
    'documents/admin/grading-policy.pdf',
    'application/pdf', 256000,
    'aaaaaaaa-0000-0000-0000-000000000001', 'teacher'
  )
ON CONFLICT DO NOTHING;


-- ===========================================================================
-- END OF SEED DATA
-- ===========================================================================
DO $$
BEGIN
  RAISE NOTICE '✓ Seed data inserted. Remember to replace placeholder UUIDs.';
END;
$$;

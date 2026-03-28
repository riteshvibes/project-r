-- =============================================================================
-- University Portal MVP — Schema
-- Target: ~1,000 students on Supabase (PostgreSQL)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- for gen_random_uuid()


-- ---------------------------------------------------------------------------
-- Helper: auto-update updated_at on every write
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


-- ===========================================================================
-- 1. PROFILES
--    One row per auth.users entry; role drives all RLS decisions.
--    FK columns (program_id, branch_id, batch_id, section_id) are the
--    canonical references; the TEXT fields are kept as denormalised
--    display-cache for quick reads and are populated via triggers or app logic.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS profiles (
  id            UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role          TEXT        NOT NULL CHECK (role IN ('student', 'teacher', 'admin'))
                            DEFAULT 'student',
  roll_number   TEXT        UNIQUE,                  -- NULL for teachers/admins
  name          TEXT        NOT NULL,
  email         TEXT        NOT NULL UNIQUE,
  phone         TEXT,
  photo_url     TEXT,
  -- Normalised FK references (preferred for joins / RLS)
  program_id    UUID        REFERENCES programs(id)  ON DELETE SET NULL,
  branch_id     UUID        REFERENCES branches(id)  ON DELETE SET NULL,
  batch_id      UUID        REFERENCES batches(id)   ON DELETE SET NULL,
  section_id    UUID        REFERENCES sections(id)  ON DELETE SET NULL,
  -- Denormalised text cache (convenient for display without extra joins)
  program       TEXT,                                -- e.g. "B.Tech"
  branch        TEXT,                                -- e.g. "CSE"
  batch         TEXT,                                -- e.g. "2022-26"
  section       TEXT,                                -- e.g. "A"
  semester      SMALLINT    CHECK (semester BETWEEN 1 AND 12),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_role        ON profiles (role);
CREATE INDEX IF NOT EXISTS idx_profiles_roll_number ON profiles (roll_number);
CREATE INDEX IF NOT EXISTS idx_profiles_email       ON profiles (email);
CREATE INDEX IF NOT EXISTS idx_profiles_program_id  ON profiles (program_id);
CREATE INDEX IF NOT EXISTS idx_profiles_branch_id   ON profiles (branch_id);
CREATE INDEX IF NOT EXISTS idx_profiles_batch_id    ON profiles (batch_id);
CREATE INDEX IF NOT EXISTS idx_profiles_section_id  ON profiles (section_id);
CREATE INDEX IF NOT EXISTS idx_profiles_batch       ON profiles (batch);
CREATE INDEX IF NOT EXISTS idx_profiles_section     ON profiles (section);

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ===========================================================================
-- 2. PROGRAMS  (e.g. B.Tech, M.Tech, BCA)
-- ===========================================================================
CREATE TABLE IF NOT EXISTS programs (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT        NOT NULL,
  code        TEXT        NOT NULL UNIQUE,           -- e.g. "BTECH"
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ===========================================================================
-- 3. BRANCHES  (e.g. CSE, ECE — belong to a program)
-- ===========================================================================
CREATE TABLE IF NOT EXISTS branches (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id  UUID        NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,
  code        TEXT        NOT NULL UNIQUE,           -- e.g. "CSE"
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_branches_program_id ON branches (program_id);


-- ===========================================================================
-- 4. BATCHES  (year-group within a branch, e.g. "2022-26")
-- ===========================================================================
CREATE TABLE IF NOT EXISTS batches (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id   UUID        NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,                  -- e.g. "2022-26"
  year        SMALLINT    NOT NULL,                  -- admission year, e.g. 2022
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_batches_branch_id ON batches (branch_id);


-- ===========================================================================
-- 5. SECTIONS  (classroom divisions within a batch, e.g. "A", "B")
-- ===========================================================================
CREATE TABLE IF NOT EXISTS sections (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id    UUID        NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,                  -- e.g. "A"
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sections_batch_id ON sections (batch_id);


-- ===========================================================================
-- 6. SUBJECTS
-- ===========================================================================
CREATE TABLE IF NOT EXISTS subjects (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT        NOT NULL,
  code        TEXT        NOT NULL UNIQUE,           -- e.g. "CS301"
  credits     SMALLINT    NOT NULL DEFAULT 3 CHECK (credits > 0),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ===========================================================================
-- 7. COURSE_OFFERINGS
--    A subject taught to a specific section by a teacher in a given semester.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS course_offerings (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id      UUID        NOT NULL REFERENCES subjects(id)  ON DELETE RESTRICT,
  section_id      UUID        NOT NULL REFERENCES sections(id)  ON DELETE RESTRICT,
  teacher_id      UUID        NOT NULL REFERENCES profiles(id)  ON DELETE RESTRICT,
  semester        SMALLINT    NOT NULL CHECK (semester BETWEEN 1 AND 12),
  academic_year   TEXT        NOT NULL,              -- e.g. "2024-25"
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (subject_id, section_id, academic_year, semester)
);

CREATE INDEX IF NOT EXISTS idx_course_offerings_subject_id    ON course_offerings (subject_id);
CREATE INDEX IF NOT EXISTS idx_course_offerings_section_id    ON course_offerings (section_id);
CREATE INDEX IF NOT EXISTS idx_course_offerings_teacher_id    ON course_offerings (teacher_id);
CREATE INDEX IF NOT EXISTS idx_course_offerings_academic_year ON course_offerings (academic_year);


-- ===========================================================================
-- 8. ENROLLMENTS
--    Students enrolled in a course offering (auto-populated or manual).
-- ===========================================================================
CREATE TABLE IF NOT EXISTS enrollments (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id          UUID        NOT NULL REFERENCES profiles(id)          ON DELETE CASCADE,
  course_offering_id  UUID        NOT NULL REFERENCES course_offerings(id)  ON DELETE CASCADE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, course_offering_id)
);

CREATE INDEX IF NOT EXISTS idx_enrollments_student_id         ON enrollments (student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course_offering_id ON enrollments (course_offering_id);


-- ===========================================================================
-- 9. ATTENDANCE_SESSIONS
--    A single class period for which attendance is taken.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS attendance_sessions (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  course_offering_id  UUID        NOT NULL REFERENCES course_offerings(id) ON DELETE CASCADE,
  session_date        DATE        NOT NULL,          -- renamed from 'date' (reserved keyword)
  period_number       SMALLINT    NOT NULL CHECK (period_number BETWEEN 1 AND 8),
  marked_by           UUID        NOT NULL REFERENCES profiles(id)         ON DELETE RESTRICT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (course_offering_id, session_date, period_number)
);

CREATE INDEX IF NOT EXISTS idx_attendance_sessions_course_offering_id ON attendance_sessions (course_offering_id);
CREATE INDEX IF NOT EXISTS idx_attendance_sessions_session_date       ON attendance_sessions (session_date);
CREATE INDEX IF NOT EXISTS idx_attendance_sessions_marked_by          ON attendance_sessions (marked_by);


-- ===========================================================================
-- 10. ATTENDANCE_RECORDS
--     Per-student status for a session.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS attendance_records (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id  UUID        NOT NULL REFERENCES attendance_sessions(id) ON DELETE CASCADE,
  student_id  UUID        NOT NULL REFERENCES profiles(id)            ON DELETE CASCADE,
  status      TEXT        NOT NULL CHECK (status IN ('present', 'absent', 'late')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (session_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_attendance_records_session_id ON attendance_records (session_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_student_id ON attendance_records (student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_status     ON attendance_records (status);


-- ===========================================================================
-- 11. ATTENDANCE_EDITS  (immutable audit log for status changes)
-- ===========================================================================
CREATE TABLE IF NOT EXISTS attendance_edits (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  record_id   UUID        NOT NULL REFERENCES attendance_records(id) ON DELETE CASCADE,
  changed_by  UUID        NOT NULL REFERENCES profiles(id)           ON DELETE RESTRICT,
  old_status  TEXT        NOT NULL CHECK (old_status IN ('present', 'absent', 'late')),
  new_status  TEXT        NOT NULL CHECK (new_status IN ('present', 'absent', 'late')),
  reason      TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attendance_edits_record_id  ON attendance_edits (record_id);
CREATE INDEX IF NOT EXISTS idx_attendance_edits_changed_by ON attendance_edits (changed_by);


-- ===========================================================================
-- 12. RESULTS
--     Exam / assessment results per student per subject per semester.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS results (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id      UUID        NOT NULL REFERENCES profiles(id)   ON DELETE CASCADE,
  subject_id      UUID        NOT NULL REFERENCES subjects(id)   ON DELETE RESTRICT,
  semester        SMALLINT    NOT NULL CHECK (semester BETWEEN 1 AND 12),
  academic_year   TEXT        NOT NULL,
  marks_obtained  NUMERIC(5,2) NOT NULL CHECK (marks_obtained >= 0),
  max_marks       NUMERIC(5,2) NOT NULL CHECK (max_marks > 0),
  -- Ensure obtained marks never exceed the maximum
  CONSTRAINT chk_marks_not_exceed_max CHECK (marks_obtained <= max_marks),
  grade           TEXT,
  is_published    BOOLEAN     NOT NULL DEFAULT FALSE,
  published_at    TIMESTAMPTZ,
  published_by    UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, subject_id, semester, academic_year)
);

CREATE INDEX IF NOT EXISTS idx_results_student_id    ON results (student_id);
CREATE INDEX IF NOT EXISTS idx_results_subject_id    ON results (subject_id);
CREATE INDEX IF NOT EXISTS idx_results_is_published  ON results (is_published);
CREATE INDEX IF NOT EXISTS idx_results_academic_year ON results (academic_year);


-- ===========================================================================
-- 13. HALL_TICKETS
--     Exam hall ticket files per student per exam session.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS hall_tickets (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  exam_session     TEXT        NOT NULL,             -- e.g. "Nov-Dec 2024"
  file_path        TEXT        NOT NULL,             -- Storage path
  signed_url_cache TEXT,                             -- Short-lived URL cache
  is_published     BOOLEAN     NOT NULL DEFAULT FALSE,
  published_at     TIMESTAMPTZ,
  published_by     UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, exam_session)
);

CREATE INDEX IF NOT EXISTS idx_hall_tickets_student_id   ON hall_tickets (student_id);
CREATE INDEX IF NOT EXISTS idx_hall_tickets_is_published ON hall_tickets (is_published);
CREATE INDEX IF NOT EXISTS idx_hall_tickets_exam_session ON hall_tickets (exam_session);


-- ===========================================================================
-- 14. NOTICES
--     Announcements with optional targeting by role / program / branch / section.
-- ===========================================================================
CREATE TABLE IF NOT EXISTS notices (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title               TEXT        NOT NULL,
  content             TEXT        NOT NULL,
  target_role         TEXT        NOT NULL DEFAULT 'all'
                                  CHECK (target_role IN ('all', 'student', 'teacher')),
  target_program_id   UUID        REFERENCES programs(id) ON DELETE SET NULL,
  target_branch_id    UUID        REFERENCES branches(id) ON DELETE SET NULL,
  target_section_id   UUID        REFERENCES sections(id) ON DELETE SET NULL,
  attachment_url      TEXT,
  is_published        BOOLEAN     NOT NULL DEFAULT FALSE,
  published_by        UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notices_is_published      ON notices (is_published);
CREATE INDEX IF NOT EXISTS idx_notices_target_role       ON notices (target_role);
CREATE INDEX IF NOT EXISTS idx_notices_target_program_id ON notices (target_program_id);
CREATE INDEX IF NOT EXISTS idx_notices_target_branch_id  ON notices (target_branch_id);
CREATE INDEX IF NOT EXISTS idx_notices_target_section_id ON notices (target_section_id);

CREATE TRIGGER trg_notices_updated_at
  BEFORE UPDATE ON notices
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ===========================================================================
-- 15. TIMETABLE_ENTRIES
-- ===========================================================================
CREATE TABLE IF NOT EXISTS timetable_entries (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  section_id    UUID        NOT NULL REFERENCES sections(id)  ON DELETE CASCADE,
  subject_id    UUID        NOT NULL REFERENCES subjects(id)  ON DELETE RESTRICT,
  teacher_id    UUID        NOT NULL REFERENCES profiles(id)  ON DELETE RESTRICT,
  day_of_week   SMALLINT    NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
                                          -- PostgreSQL/JavaScript convention: 0=Sunday, 1=Monday … 6=Saturday
                                          -- Typical university week uses 1 (Mon) – 5 (Fri)
  period_number SMALLINT    NOT NULL CHECK (period_number BETWEEN 1 AND 8),
  room          TEXT,
  academic_year TEXT        NOT NULL,
  semester      SMALLINT    NOT NULL CHECK (semester BETWEEN 1 AND 12),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (section_id, day_of_week, period_number, academic_year, semester)
);

CREATE INDEX IF NOT EXISTS idx_timetable_entries_section_id    ON timetable_entries (section_id);
CREATE INDEX IF NOT EXISTS idx_timetable_entries_teacher_id    ON timetable_entries (teacher_id);
CREATE INDEX IF NOT EXISTS idx_timetable_entries_day_of_week   ON timetable_entries (day_of_week);
CREATE INDEX IF NOT EXISTS idx_timetable_entries_academic_year ON timetable_entries (academic_year);


-- ===========================================================================
-- 16. DOCUMENTS
--     Generic file uploads (study material, circulars, forms, etc.)
-- ===========================================================================
CREATE TABLE IF NOT EXISTS documents (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title         TEXT        NOT NULL,
  description   TEXT,
  file_path     TEXT        NOT NULL,                -- Supabase Storage path
  file_type     TEXT,                                -- MIME type
  file_size     BIGINT      CHECK (file_size > 0),   -- bytes
  uploaded_by   UUID        NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  target_role   TEXT        NOT NULL DEFAULT 'all'
                            CHECK (target_role IN ('all', 'student', 'teacher', 'admin')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documents_uploaded_by ON documents (uploaded_by);
CREATE INDEX IF NOT EXISTS idx_documents_target_role ON documents (target_role);

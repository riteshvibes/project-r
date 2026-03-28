-- =============================================================================
-- University Portal MVP — Row-Level Security Policies
-- Run AFTER schema.sql
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Helper: resolve the role of the currently authenticated user.
--   Returns NULL when called by unauthenticated requests (anon key),
--   so every policy that calls this will correctly deny access.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$;

-- Convenience: return TRUE when the caller is an admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT get_user_role() = 'admin';
$$;

-- Convenience: return TRUE when the caller is a teacher
CREATE OR REPLACE FUNCTION is_teacher()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT get_user_role() = 'teacher';
$$;


-- =============================================================================
-- 1. PROFILES
-- =============================================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Every authenticated user can read their own profile
CREATE POLICY "profiles: read own"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Admins can read all profiles
CREATE POLICY "profiles: admin read all"
  ON profiles FOR SELECT
  USING (is_admin());

-- Admins can insert / update / delete any profile
CREATE POLICY "profiles: admin write"
  ON profiles FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Users can update their own non-role fields
-- (role changes must go through admin)
CREATE POLICY "profiles: self update"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    -- Prevent self-elevation of role
    AND role = (SELECT role FROM profiles WHERE id = auth.uid())
  );

-- Teachers can read profiles of students enrolled in their offerings
CREATE POLICY "profiles: teacher read student"
  ON profiles FOR SELECT
  USING (
    is_teacher()
    AND role = 'student'
    AND id IN (
      SELECT e.student_id
      FROM   enrollments      e
      JOIN   course_offerings co ON co.id = e.course_offering_id
      WHERE  co.teacher_id = auth.uid()
    )
  );


-- =============================================================================
-- 2. PROGRAMS
-- =============================================================================
ALTER TABLE programs ENABLE ROW LEVEL SECURITY;

-- Everyone authenticated can read
CREATE POLICY "programs: authenticated read"
  ON programs FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Only admins can write
CREATE POLICY "programs: admin write"
  ON programs FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 3. BRANCHES
-- =============================================================================
ALTER TABLE branches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "branches: authenticated read"
  ON branches FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "branches: admin write"
  ON branches FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 4. BATCHES
-- =============================================================================
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "batches: authenticated read"
  ON batches FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "batches: admin write"
  ON batches FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 5. SECTIONS
-- =============================================================================
ALTER TABLE sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sections: authenticated read"
  ON sections FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "sections: admin write"
  ON sections FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 6. SUBJECTS
-- =============================================================================
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "subjects: authenticated read"
  ON subjects FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "subjects: admin write"
  ON subjects FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 7. COURSE_OFFERINGS
-- =============================================================================
ALTER TABLE course_offerings ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read offerings
CREATE POLICY "course_offerings: authenticated read"
  ON course_offerings FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Only admins can create / modify offerings
CREATE POLICY "course_offerings: admin write"
  ON course_offerings FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 8. ENROLLMENTS
-- =============================================================================
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

-- Students can see their own enrollments
CREATE POLICY "enrollments: student read own"
  ON enrollments FOR SELECT
  USING (auth.uid() = student_id);

-- Teachers can see enrollments for their offerings
CREATE POLICY "enrollments: teacher read own offerings"
  ON enrollments FOR SELECT
  USING (
    is_teacher()
    AND course_offering_id IN (
      SELECT id FROM course_offerings WHERE teacher_id = auth.uid()
    )
  );

-- Admins full access
CREATE POLICY "enrollments: admin full"
  ON enrollments FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 9. ATTENDANCE_SESSIONS
-- =============================================================================
ALTER TABLE attendance_sessions ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read sessions
CREATE POLICY "attendance_sessions: authenticated read"
  ON attendance_sessions FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Teachers can insert sessions for their own offerings
CREATE POLICY "attendance_sessions: teacher insert own"
  ON attendance_sessions FOR INSERT
  WITH CHECK (
    is_teacher()
    AND course_offering_id IN (
      SELECT id FROM course_offerings WHERE teacher_id = auth.uid()
    )
    AND marked_by = auth.uid()
  );

-- Teachers can update sessions they created
CREATE POLICY "attendance_sessions: teacher update own"
  ON attendance_sessions FOR UPDATE
  USING (
    is_teacher()
    AND marked_by = auth.uid()
  )
  WITH CHECK (
    is_teacher()
    AND marked_by = auth.uid()
  );

-- Admins full access
CREATE POLICY "attendance_sessions: admin full"
  ON attendance_sessions FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 10. ATTENDANCE_RECORDS
-- =============================================================================
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

-- Students can read their own records
CREATE POLICY "attendance_records: student read own"
  ON attendance_records FOR SELECT
  USING (auth.uid() = student_id);

-- Teachers can read records for sessions they own
CREATE POLICY "attendance_records: teacher read own sessions"
  ON attendance_records FOR SELECT
  USING (
    is_teacher()
    AND session_id IN (
      SELECT id FROM attendance_sessions WHERE marked_by = auth.uid()
    )
  );

-- Teachers can insert records for their sessions
CREATE POLICY "attendance_records: teacher insert"
  ON attendance_records FOR INSERT
  WITH CHECK (
    is_teacher()
    AND session_id IN (
      SELECT id FROM attendance_sessions WHERE marked_by = auth.uid()
    )
  );

-- Teachers can update records for their sessions
CREATE POLICY "attendance_records: teacher update"
  ON attendance_records FOR UPDATE
  USING (
    is_teacher()
    AND session_id IN (
      SELECT id FROM attendance_sessions WHERE marked_by = auth.uid()
    )
  )
  WITH CHECK (
    is_teacher()
    AND session_id IN (
      SELECT id FROM attendance_sessions WHERE marked_by = auth.uid()
    )
  );

-- Admins full access
CREATE POLICY "attendance_records: admin full"
  ON attendance_records FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 11. ATTENDANCE_EDITS  (append-only audit log)
-- =============================================================================
ALTER TABLE attendance_edits ENABLE ROW LEVEL SECURITY;

-- Admins can read all audit entries
CREATE POLICY "attendance_edits: admin read"
  ON attendance_edits FOR SELECT
  USING (is_admin());

-- Teachers can read edits they made
CREATE POLICY "attendance_edits: teacher read own"
  ON attendance_edits FOR SELECT
  USING (
    is_teacher()
    AND changed_by = auth.uid()
  );

-- Teachers and admins can insert audit entries (append only — no UPDATE/DELETE)
CREATE POLICY "attendance_edits: teacher insert"
  ON attendance_edits FOR INSERT
  WITH CHECK (
    (is_teacher() OR is_admin())
    AND changed_by = auth.uid()
  );

-- NOTE: No UPDATE or DELETE policies — audit log is intentionally immutable.


-- =============================================================================
-- 12. RESULTS
-- =============================================================================
ALTER TABLE results ENABLE ROW LEVEL SECURITY;

-- Students can only see their OWN PUBLISHED results
CREATE POLICY "results: student read own published"
  ON results FOR SELECT
  USING (
    auth.uid() = student_id
    AND is_published = TRUE
  );

-- Teachers can read results for subjects they teach
CREATE POLICY "results: teacher read own subjects"
  ON results FOR SELECT
  USING (
    is_teacher()
    AND subject_id IN (
      SELECT subject_id FROM course_offerings WHERE teacher_id = auth.uid()
    )
  );

-- Admins full access
CREATE POLICY "results: admin full"
  ON results FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 13. HALL_TICKETS
-- =============================================================================
ALTER TABLE hall_tickets ENABLE ROW LEVEL SECURITY;

-- Students can only read their own PUBLISHED hall tickets
CREATE POLICY "hall_tickets: student read own published"
  ON hall_tickets FOR SELECT
  USING (
    auth.uid() = student_id
    AND is_published = TRUE
  );

-- Admins full access
CREATE POLICY "hall_tickets: admin full"
  ON hall_tickets FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 14. NOTICES
-- =============================================================================
ALTER TABLE notices ENABLE ROW LEVEL SECURITY;

-- Authenticated users see published notices that target them:
--   target_role = 'all'                          → everyone
--   target_role matches the caller's role        → role-specific
-- Optional finer filters: program / branch / section stored on the caller's
-- profile must match if set on the notice.
CREATE POLICY "notices: read published"
  ON notices FOR SELECT
  USING (
    is_published = TRUE
    AND (
      -- Admin always sees everything
      is_admin()
      OR (
        -- Role filter
        (target_role = 'all' OR target_role = get_user_role())
        -- If program filter is set, caller's program must match
        AND (
          target_program_id IS NULL
          OR target_program_id = (
            SELECT p2.id
            FROM   programs p2
            JOIN   profiles pr ON pr.program = p2.name
            WHERE  pr.id = auth.uid()
            LIMIT  1
          )
        )
        -- If branch filter is set, caller's branch must match
        AND (
          target_branch_id IS NULL
          OR target_branch_id = (
            SELECT b.id
            FROM   branches b
            JOIN   profiles pr ON pr.branch = b.name
            WHERE  pr.id = auth.uid()
            LIMIT  1
          )
        )
        -- If section filter is set, caller's section must match
        AND (
          target_section_id IS NULL
          OR target_section_id = (
            SELECT s.id
            FROM   sections  s
            JOIN   batches   bt ON bt.id = s.batch_id
            JOIN   branches  br ON br.id = bt.branch_id
            JOIN   profiles  pr ON pr.section = s.name
                                AND pr.batch   = bt.name
                                AND pr.branch  = br.name
            WHERE  pr.id = auth.uid()
            LIMIT  1
          )
        )
      )
    )
  );

-- Admins full access (INSERT / UPDATE / DELETE)
CREATE POLICY "notices: admin write"
  ON notices FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 15. TIMETABLE_ENTRIES
-- =============================================================================
ALTER TABLE timetable_entries ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read the timetable
CREATE POLICY "timetable_entries: authenticated read"
  ON timetable_entries FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Only admins can write
CREATE POLICY "timetable_entries: admin write"
  ON timetable_entries FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());


-- =============================================================================
-- 16. DOCUMENTS
-- =============================================================================
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Authenticated users see documents whose target_role is 'all' or matches theirs
CREATE POLICY "documents: read by role"
  ON documents FOR SELECT
  USING (
    auth.uid() IS NOT NULL
    AND (
      target_role = 'all'
      OR target_role = get_user_role()
    )
  );

-- Admins full access
CREATE POLICY "documents: admin full"
  ON documents FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Teachers can upload documents targeted at students or all
CREATE POLICY "documents: teacher insert"
  ON documents FOR INSERT
  WITH CHECK (
    is_teacher()
    AND uploaded_by = auth.uid()
    AND target_role IN ('all', 'student', 'teacher')
  );

-- Teachers can update their own uploads
CREATE POLICY "documents: teacher update own"
  ON documents FOR UPDATE
  USING (
    is_teacher()
    AND uploaded_by = auth.uid()
  )
  WITH CHECK (
    is_teacher()
    AND uploaded_by = auth.uid()
  );

import 'supabase_service.dart';

class AttendanceService {
  static final _client = SupabaseService.client;

  /// Get all course offerings for current student with attendance summary.
  static Future<List<Map<String, dynamic>>> getStudentAttendanceSummary(
    String studentId,
  ) async {
    final enrollments = await _client
        .from('enrollments')
        .select('''
          id,
          course_offering_id,
          course_offerings(
            id,
            semester,
            academic_year,
            subjects(id, name, code),
            profiles!course_offerings_teacher_id_fkey(name)
          )
        ''')
        .eq('student_id', studentId);

    final result = <Map<String, dynamic>>[];
    for (final e in enrollments) {
      final offering = e['course_offerings'] as Map<String, dynamic>;
      final offeringId = offering['id'] as String;

      final sessionsResp = await _client
          .from('attendance_sessions')
          .select('id')
          .eq('course_offering_id', offeringId);
      final totalSessions = (sessionsResp as List).length;

      int presentCount = 0;
      if (totalSessions > 0) {
        final sessionIds = sessionsResp.map((s) => s['id']).toList();
        final records = await _client
            .from('attendance_records')
            .select('status')
            .eq('student_id', studentId)
            .inFilter('session_id', sessionIds)
            .inFilter('status', ['present', 'late']);
        presentCount = (records as List).length;
      }

      final percentage = totalSessions > 0
          ? (presentCount / totalSessions * 100).roundToDouble()
          : 0.0;

      result.add({
        'enrollment_id': e['id'],
        'offering_id': offeringId,
        'subject_name': offering['subjects']['name'],
        'subject_code': offering['subjects']['code'],
        'teacher_name': offering['profiles']['name'],
        'semester': offering['semester'],
        'academic_year': offering['academic_year'],
        'total_sessions': totalSessions,
        'present_count': presentCount,
        'percentage': percentage,
      });
    }
    return result;
  }

  /// Get attendance history for a student in a specific offering.
  static Future<List<Map<String, dynamic>>> getStudentAttendanceHistory({
    required String studentId,
    required String offeringId,
  }) async {
    final sessions = await _client
        .from('attendance_sessions')
        .select('id, session_date, period_number')
        .eq('course_offering_id', offeringId)
        .order('session_date', ascending: false);

    final result = <Map<String, dynamic>>[];
    for (final session in sessions) {
      final records = await _client
          .from('attendance_records')
          .select('status')
          .eq('session_id', session['id'])
          .eq('student_id', studentId)
          .maybeSingle();

      result.add({
        'session_date': session['session_date'],
        'period_number': session['period_number'],
        'status': records?['status'] ?? 'absent',
      });
    }
    return result;
  }

  /// Teacher: get students for a session to mark attendance.
  static Future<List<Map<String, dynamic>>> getSessionStudents(
    String offeringId,
  ) async {
    final enrollments = await _client
        .from('enrollments')
        .select('student_id, profiles!enrollments_student_id_fkey(name, roll_number, photo_url)')
        .eq('course_offering_id', offeringId);

    return (enrollments as List).map((e) => {
      'student_id': e['student_id'],
      'name': e['profiles']['name'],
      'roll_number': e['profiles']['roll_number'],
      'photo_url': e['profiles']['photo_url'],
    }).toList();
  }

  /// Teacher: create a session and mark attendance for all students.
  static Future<void> markAttendance({
    required String offeringId,
    required String sessionDate,
    required int periodNumber,
    required Map<String, String> studentStatuses,
  }) async {
    final teacherId = SupabaseService.currentUserId!;

    final session = await _client
        .from('attendance_sessions')
        .insert({
          'course_offering_id': offeringId,
          'session_date': sessionDate,
          'period_number': periodNumber,
          'marked_by': teacherId,
        })
        .select('id')
        .single();

    final sessionId = session['id'] as String;

    final records = studentStatuses.entries.map((entry) => {
      'session_id': sessionId,
      'student_id': entry.key,
      'status': entry.value,
    }).toList();

    await _client.from('attendance_records').insert(records);
  }

  /// Teacher: get their course offerings.
  static Future<List<Map<String, dynamic>>> getTeacherOfferings(
    String teacherId,
  ) async {
    final offerings = await _client
        .from('course_offerings')
        .select('''
          id,
          semester,
          academic_year,
          subjects(id, name, code),
          sections(id, name, batches(name, branches(name)))
        ''')
        .eq('teacher_id', teacherId);
    return (offerings as List).cast<Map<String, dynamic>>();
  }
}

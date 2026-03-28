import 'supabase_service.dart';

class TimetableService {
  static final _client = SupabaseService.client;

  /// Get timetable for a section.
  static Future<List<Map<String, dynamic>>> getSectionTimetable(
    String sectionId, {
    String? academicYear,
    int? semester,
  }) async {
    var query = _client
        .from('timetable_entries')
        .select('''
          *,
          subjects(name, code),
          profiles!timetable_entries_teacher_id_fkey(name)
        ''')
        .eq('section_id', sectionId);

    if (academicYear != null) query = query.eq('academic_year', academicYear);
    if (semester != null) query = query.eq('semester', semester);

    final results = await query.order('day_of_week').order('period_number');
    return (results as List).cast<Map<String, dynamic>>();
  }

  /// Get timetable for a teacher.
  static Future<List<Map<String, dynamic>>> getTeacherTimetable(
    String teacherId, {
    String? academicYear,
  }) async {
    var query = _client
        .from('timetable_entries')
        .select('''
          *,
          subjects(name, code),
          sections(name, batches(name, branches(name)))
        ''')
        .eq('teacher_id', teacherId);

    if (academicYear != null) query = query.eq('academic_year', academicYear);

    final results = await query.order('day_of_week').order('period_number');
    return (results as List).cast<Map<String, dynamic>>();
  }

  /// Admin: add a timetable entry.
  static Future<void> addEntry({
    required String sectionId,
    required String subjectId,
    required String teacherId,
    required int dayOfWeek,
    required int periodNumber,
    required String academicYear,
    required int semester,
    String? room,
  }) async {
    await _client.from('timetable_entries').insert({
      'section_id': sectionId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'day_of_week': dayOfWeek,
      'period_number': periodNumber,
      'academic_year': academicYear,
      'semester': semester,
      'room': room,
    });
  }

  /// Admin: delete a timetable entry.
  static Future<void> deleteEntry(String entryId) async {
    await _client.from('timetable_entries').delete().eq('id', entryId);
  }
}

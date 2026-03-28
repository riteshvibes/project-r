import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class ResultsService {
  static final _client = SupabaseService.client;

  /// Get published results for a student.
  static Future<List<Map<String, dynamic>>> getStudentResults(
    String studentId,
  ) async {
    final results = await _client
        .from('results')
        .select('*, subjects(name, code)')
        .eq('student_id', studentId)
        .eq('is_published', true)
        .order('semester');
    return (results as List).cast<Map<String, dynamic>>();
  }

  /// Admin: get all results (published + unpublished).
  static Future<List<Map<String, dynamic>>> getAllResults({
    String? studentId,
    int? semester,
    String? academicYear,
  }) async {
    var query = _client.from('results').select(
      '*, subjects(name, code), profiles!results_student_id_fkey(name, roll_number)',
    );
    if (studentId != null) query = query.eq('student_id', studentId);
    if (semester != null) query = query.eq('semester', semester);
    if (academicYear != null) query = query.eq('academic_year', academicYear);
    final results = await query.order('is_published', ascending: false);
    return (results as List).cast<Map<String, dynamic>>();
  }

  /// Admin: import results from CSV data.
  static Future<Map<String, dynamic>> importResultsCsv(
    List<Map<String, dynamic>> rows,
  ) async {
    int inserted = 0;
    final errors = <String>[];

    for (final row in rows) {
      try {
        final rollNumber = row['roll_number']?.toString().trim();
        final subjectCode = row['subject_code']?.toString().trim();
        final semester = int.tryParse(row['semester']?.toString() ?? '');
        final academicYear = row['academic_year']?.toString().trim();
        final marksObtained = double.tryParse(row['marks_obtained']?.toString() ?? '');
        final maxMarks = double.tryParse(row['max_marks']?.toString() ?? '100');
        final grade = row['grade']?.toString().trim();

        if (rollNumber == null || subjectCode == null || semester == null ||
            academicYear == null || marksObtained == null) {
          errors.add('Invalid row: ${row.toString()}');
          continue;
        }

        final studentResp = await _client
            .from('profiles')
            .select('id')
            .eq('roll_number', rollNumber)
            .single();
        final subjectResp = await _client
            .from('subjects')
            .select('id')
            .eq('code', subjectCode)
            .single();

        await _client.from('results').upsert({
          'student_id': studentResp['id'],
          'subject_id': subjectResp['id'],
          'semester': semester,
          'academic_year': academicYear,
          'marks_obtained': marksObtained,
          'max_marks': maxMarks ?? 100,
          'grade': grade,
          'is_published': false,
        }, onConflict: 'student_id,subject_id,semester,academic_year');
        inserted++;
      } catch (e) {
        errors.add('Error processing row: $e');
      }
    }
    return {'inserted': inserted, 'errors': errors};
  }

  /// Admin: publish/unpublish results.
  static Future<void> publishResults({
    required List<String> resultIds,
    required bool publish,
  }) async {
    final adminId = SupabaseService.currentUserId!;
    await _client.from('results').update({
      'is_published': publish,
      'published_at': publish ? DateTime.now().toIso8601String() : null,
      'published_by': publish ? adminId : null,
    }).inFilter('id', resultIds);
  }
}

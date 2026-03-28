import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../constants/app_constants.dart';

class HallTicketService {
  static final _client = SupabaseService.client;

  /// Student: get their published hall ticket.
  static Future<Map<String, dynamic>?> getStudentHallTicket(
    String studentId,
    String examSession,
  ) async {
    final result = await _client
        .from('hall_tickets')
        .select()
        .eq('student_id', studentId)
        .eq('exam_session', examSession)
        .eq('is_published', true)
        .maybeSingle();
    return result;
  }

  /// Student: list all published hall tickets.
  static Future<List<Map<String, dynamic>>> getStudentHallTickets(
    String studentId,
  ) async {
    final results = await _client
        .from('hall_tickets')
        .select()
        .eq('student_id', studentId)
        .eq('is_published', true)
        .order('created_at', ascending: false);
    return (results as List).cast<Map<String, dynamic>>();
  }

  /// Get signed URL for hall ticket download.
  static Future<String> getDownloadUrl(String filePath) async {
    return await SupabaseService.getSignedUrl(
      bucket: AppConstants.hallTicketsBucket,
      path: filePath,
      expiresInSeconds: 3600,
    );
  }

  /// Admin: upload a hall ticket PDF for a student.
  static Future<void> uploadHallTicket({
    required String studentId,
    required String examSession,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    final adminId = SupabaseService.currentUserId!;
    
    if (pdfBytes.length > AppConstants.maxFileSizeBytes) {
      throw Exception('PDF file exceeds ${AppConstants.maxFileSizeMB}MB limit');
    }

    final filePath = 'hall-tickets/$examSession/$studentId/$fileName';
    await SupabaseService.uploadFile(
      bucket: AppConstants.hallTicketsBucket,
      path: filePath,
      bytes: pdfBytes,
      mimeType: 'application/pdf',
      allowedMimeTypes: AppConstants.allowedPdfTypes,
    );

    await _client.from('hall_tickets').upsert({
      'student_id': studentId,
      'exam_session': examSession,
      'file_path': filePath,
      'is_published': false,
      'published_by': adminId,
    }, onConflict: 'student_id,exam_session');
  }

  /// Admin: publish/unpublish hall tickets.
  static Future<void> publishHallTickets({
    required List<String> ticketIds,
    required bool publish,
  }) async {
    final adminId = SupabaseService.currentUserId!;
    await _client.from('hall_tickets').update({
      'is_published': publish,
      'published_at': publish ? DateTime.now().toIso8601String() : null,
      'published_by': publish ? adminId : null,
    }).inFilter('id', ticketIds);
  }

  /// Admin: list all hall tickets.
  static Future<List<Map<String, dynamic>>> getAllHallTickets({
    String? examSession,
  }) async {
    var query = _client.from('hall_tickets').select(
      '*, profiles!hall_tickets_student_id_fkey(name, roll_number)',
    );
    if (examSession != null) query = query.eq('exam_session', examSession);
    final results = await query.order('created_at', ascending: false);
    return (results as List).cast<Map<String, dynamic>>();
  }

  /// Look up a student's UUID by roll number (admin use only).
  static Future<String?> getStudentIdByRollNumber(String rollNumber) async {
    final result = await _client
        .from('profiles')
        .select('id')
        .eq('roll_number', rollNumber)
        .eq('role', 'student')
        .maybeSingle();
    return result?['id'] as String?;
  }
}

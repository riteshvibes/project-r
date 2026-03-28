import 'supabase_service.dart';

class NoticeService {
  static final _client = SupabaseService.client;

  /// Get notices for a user based on their role and section.
  static Future<List<Map<String, dynamic>>> getNotices({
    String? role,
    String? programId,
    String? branchId,
    String? sectionId,
  }) async {
    final results = await _client
        .from('notices')
        .select('*, profiles!notices_published_by_fkey(name)')
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .limit(50);
    return (results as List).cast<Map<String, dynamic>>();
  }

  /// Admin: create a notice.
  static Future<void> createNotice({
    required String title,
    required String content,
    String targetRole = 'all',
    String? targetProgramId,
    String? targetBranchId,
    String? targetSectionId,
    String? attachmentUrl,
    bool publish = false,
  }) async {
    final adminId = SupabaseService.currentUserId!;
    await _client.from('notices').insert({
      'title': title,
      'content': content,
      'target_role': targetRole,
      'target_program_id': targetProgramId,
      'target_branch_id': targetBranchId,
      'target_section_id': targetSectionId,
      'attachment_url': attachmentUrl,
      'is_published': publish,
      'published_by': adminId,
    });
  }

  /// Admin: toggle publish status.
  static Future<void> togglePublish(String noticeId, bool publish) async {
    await _client.from('notices').update({
      'is_published': publish,
    }).eq('id', noticeId);
  }

  /// Admin: delete a notice.
  static Future<void> deleteNotice(String noticeId) async {
    await _client.from('notices').delete().eq('id', noticeId);
  }
}

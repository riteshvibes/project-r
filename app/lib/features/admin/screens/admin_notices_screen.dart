import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/notice_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/date_utils.dart';

class AdminNoticesScreen extends StatefulWidget {
  const AdminNoticesScreen({super.key});

  @override
  State<AdminNoticesScreen> createState() => _AdminNoticesScreenState();
}

class _AdminNoticesScreenState extends State<AdminNoticesScreen> {
  List<Map<String, dynamic>> _notices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() => _isLoading = true);
    try {
      final notices = await NoticeService.getNotices();
      if (mounted) setState(() => _notices = notices);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to load: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String targetRole = 'all';
    bool publish = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Notice'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: contentController,
                    decoration: const InputDecoration(labelText: 'Content'),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    maxLines: 4,
                    maxLength: 1000,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: targetRole,
                    decoration: const InputDecoration(labelText: 'Target Role'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'student', child: Text('Students only')),
                      DropdownMenuItem(value: 'teacher', child: Text('Teachers only')),
                    ],
                    onChanged: (v) => setDialogState(() => targetRole = v ?? 'all'),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Publish immediately'),
                    value: publish,
                    onChanged: (v) => setDialogState(() => publish = v ?? false),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await NoticeService.createNotice(
                    title: titleController.text.trim(),
                    content: contentController.text.trim(),
                    targetRole: targetRole,
                    publish: publish,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadNotices();
                  if (mounted) SnackbarUtils.showSuccess(context, 'Notice created');
                } catch (e) {
                  if (mounted) SnackbarUtils.showError(context, 'Failed: $e');
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNotice(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text('Are you sure you want to delete this notice?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await NoticeService.deleteNotice(id);
        _loadNotices();
        if (mounted) SnackbarUtils.showSuccess(context, 'Notice deleted');
      } catch (e) {
        if (mounted) SnackbarUtils.showError(context, 'Failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notices'),
        leading: BackButton(onPressed: () => context.go('/admin')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Notice'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty
              ? const Center(child: Text('No notices yet.'))
              : ListView.builder(
                  itemCount: _notices.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final n = _notices[index];
                    final isPublished = n['is_published'] == true;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(n['title'] ?? ''),
                        subtitle: Text(
                          '${n['content']?.toString().substring(0, (n['content']?.toString().length ?? 0).clamp(0, 80))}...'
                          '\nTarget: ${n['target_role']} | ${AppDateUtils.getRelativeTime(DateTime.parse(n['created_at']))}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isPublished,
                              onChanged: (v) async {
                                await NoticeService.togglePublish(n['id'] as String, v);
                                _loadNotices();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                              onPressed: () => _deleteNotice(n['id'] as String),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

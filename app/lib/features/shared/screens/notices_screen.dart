import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/notice_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';

class NoticesScreen extends StatefulWidget {
  final String role;

  const NoticesScreen({super.key, required this.role});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  List<Map<String, dynamic>> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await NoticeService.getNotices(role: widget.role);
      if (mounted) setState(() { _notices = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to load notices');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backPath = '/${widget.role}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notices'),
        leading: BackButton(onPressed: () => context.go(backPath)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty
              ? const Center(child: Text('No notices at this time'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notices.length,
                    itemBuilder: (context, index) {
                      final n = _notices[index];
                      final createdAt = AppDateUtils.getRelativeTime(
                        DateTime.parse(n['created_at'] as String),
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: const Icon(Icons.notifications,
                              color: AppTheme.primaryColor),
                          title: Text(n['title'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(createdAt),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(n['content'] as String),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

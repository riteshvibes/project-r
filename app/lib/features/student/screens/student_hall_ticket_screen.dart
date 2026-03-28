import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/hall_ticket_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/date_utils.dart';

class StudentHallTicketScreen extends StatefulWidget {
  const StudentHallTicketScreen({super.key});

  @override
  State<StudentHallTicketScreen> createState() => _StudentHallTicketScreenState();
}

class _StudentHallTicketScreenState extends State<StudentHallTicketScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final studentId = AuthService.currentUserId!;
      final data = await HallTicketService.getStudentHallTickets(studentId);
      if (mounted) setState(() { _tickets = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to load hall tickets');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _download(String filePath) async {
    try {
      final url = await HallTicketService.getDownloadUrl(filePath);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Download failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hall Tickets'),
        leading: BackButton(onPressed: () => context.go('/student')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? const Center(child: Text('No hall tickets available'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final t = _tickets[index];
                      final createdAt = AppDateUtils.formatDisplayDate(
                        DateTime.parse(t['created_at'] as String),
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf,
                              color: AppTheme.errorColor, size: 36),
                          title: Text(t['exam_session'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Issued: $createdAt'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download,
                                color: AppTheme.primaryColor),
                            onPressed: () => _download(t['file_path'] as String),
                            tooltip: 'Download',
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

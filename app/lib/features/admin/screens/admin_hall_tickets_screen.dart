import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/hall_ticket_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/date_utils.dart';

class AdminHallTicketsScreen extends StatefulWidget {
  const AdminHallTicketsScreen({super.key});

  @override
  State<AdminHallTicketsScreen> createState() => _AdminHallTicketsScreenState();
}

class _AdminHallTicketsScreenState extends State<AdminHallTicketsScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = false;
  bool _isUploading = false;
  final Set<String> _selectedIds = {};
  String _examSession = '';

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final tickets = await HallTicketService.getAllHallTickets();
      if (mounted) setState(() => _tickets = tickets);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to load: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadHallTicket() async {
    final formKey = GlobalKey<FormState>();
    final studentIdController = TextEditingController();
    final sessionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Hall Ticket'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: studentIdController,
                decoration: const InputDecoration(labelText: 'Student Roll Number'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: sessionController,
                decoration: const InputDecoration(
                  labelText: 'Exam Session (e.g. Nov-2024)',
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Choose PDF'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final rollNumber = studentIdController.text.trim();
    final examSession = sessionController.text.trim();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isUploading = true);
    try {
      final studentId = await _getStudentIdByRoll(rollNumber);
      if (studentId == null) {
        if (mounted) SnackbarUtils.showError(context, 'Student with roll number $rollNumber not found');
        return;
      }

      await HallTicketService.uploadHallTicket(
        studentId: studentId,
        examSession: examSession,
        pdfBytes: file.bytes!,
        fileName: file.name,
      );

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Hall ticket uploaded successfully');
        _loadTickets();
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<String?> _getStudentIdByRoll(String rollNumber) async {
    try {
      return await HallTicketService.getStudentIdByRollNumber(rollNumber);
    } catch (_) {
      return null;
    }
  }

  Future<void> _togglePublish(bool publish) async {
    if (_selectedIds.isEmpty) {
      SnackbarUtils.showInfo(context, 'Select tickets to ${publish ? 'publish' : 'unpublish'}');
      return;
    }
    try {
      await HallTicketService.publishHallTickets(
        ticketIds: _selectedIds.toList(),
        publish: publish,
      );
      SnackbarUtils.showSuccess(
        context,
        '${_selectedIds.length} tickets ${publish ? 'published' : 'unpublished'}',
      );
      _selectedIds.clear();
      _loadTickets();
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Operation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hall Tickets'),
        leading: BackButton(onPressed: () => context.go('/admin')),
        actions: [
          if (_selectedIds.isNotEmpty) ...[
            TextButton(
              onPressed: () => _togglePublish(true),
              child: const Text('Publish', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => _togglePublish(false),
              child: const Text('Unpublish', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadHallTicket,
        icon: _isUploading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.upload_file),
        label: Text(_isUploading ? 'Uploading...' : 'Upload Hall Ticket'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? const Center(child: Text('No hall tickets uploaded yet.'))
              : ListView.builder(
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final t = _tickets[index];
                    final isSelected = _selectedIds.contains(t['id']);
                    final isPublished = t['is_published'] == true;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : null,
                      child: ListTile(
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (_) => setState(() {
                            if (isSelected) _selectedIds.remove(t['id']);
                            else _selectedIds.add(t['id'] as String);
                          }),
                        ),
                        title: Text(t['profiles']?['name'] ?? 'Unknown'),
                        subtitle: Text(
                          '${t['profiles']?['roll_number'] ?? ''} | Session: ${t['exam_session']}'
                          '\nUploaded: ${AppDateUtils.formatDisplayDate(DateTime.parse(t['created_at']))}',
                        ),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text(
                            isPublished ? 'Published' : 'Draft',
                            style: TextStyle(
                              color: isPublished ? Colors.white : AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: isPublished ? AppTheme.successColor : Colors.grey.shade200,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

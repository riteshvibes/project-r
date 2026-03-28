import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';

class AdminTeachersScreen extends StatefulWidget {
  const AdminTeachersScreen({super.key});

  @override
  State<AdminTeachersScreen> createState() => _AdminTeachersScreenState();
}

class _AdminTeachersScreenState extends State<AdminTeachersScreen> {
  List<Map<String, dynamic>> _teachers = [];
  bool _isLoading = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    try {
      final teachers = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', 'teacher')
          .order('name');
      if (mounted) setState(() => _teachers = (teachers as List).cast<Map<String, dynamic>>());
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to load: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    setState(() => _isImporting = true);
    try {
      final csvString = String.fromCharCodes(bytes);
      final rows = const CsvToListConverter(eol: '\n').convert(csvString);
      if (rows.isEmpty) throw Exception('CSV is empty');

      final headers = (rows.first as List).map((h) => h.toString().trim().toLowerCase()).toList();
      int inserted = 0;
      final errors = <String>[];

      for (final row in rows.skip(1)) {
        try {
          final data = Map<String, dynamic>.fromIterables(
            headers,
            (row as List).map((v) => v?.toString().trim()),
          );
          final rollNumber = data['roll_number']?.toString();
          if (rollNumber == null || rollNumber.isEmpty) continue;

          await Supabase.instance.client.from('profiles').upsert({
            'roll_number': rollNumber,
            'name': data['name'] ?? '',
            'email': data['email'] ?? '$rollNumber@portal.local',
            'phone': data['phone'],
            'branch': data['department'],
            'role': 'teacher',
          }, onConflict: 'roll_number');
          inserted++;
        } catch (e) {
          errors.add('Row error: $e');
        }
      }
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Imported $inserted teachers. Errors: ${errors.length}');
        _loadTeachers();
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        leading: BackButton(onPressed: () => context.go('/admin')),
        actions: [
          IconButton(
            onPressed: _isImporting ? null : _importCsv,
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import CSV',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teachers.isEmpty
              ? const Center(child: Text('No teachers found. Import a CSV to get started.'))
              : ListView.builder(
                  itemCount: _teachers.length,
                  itemBuilder: (context, index) {
                    final t = _teachers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.secondaryColor,
                        child: Text(
                          (t['name'] as String? ?? 'T')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(t['name'] ?? 'Unknown'),
                      subtitle: Text('${t['roll_number'] ?? ''} | ${t['branch'] ?? 'N/A'}'),
                    );
                  },
                ),
    );
  }
}

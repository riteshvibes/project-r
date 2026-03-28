import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;
  bool _isImporting = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      var query = Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', 'student');
      if (_searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$_searchQuery%,roll_number.ilike.%$_searchQuery%');
      }
      final students = await query.order('name');
      if (mounted) setState(() => _students = (students as List).cast<Map<String, dynamic>>());
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to load students: $e');
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
          if (rollNumber == null || rollNumber.isEmpty) {
            errors.add('Missing roll_number in row');
            continue;
          }
          await Supabase.instance.client.from('profiles').upsert({
            'roll_number': rollNumber,
            'name': data['name'] ?? '',
            'email': data['email'] ?? '$rollNumber@portal.local',
            'phone': data['phone'],
            'program': data['program'],
            'branch': data['branch'],
            'batch': data['batch'],
            'section': data['section'],
            'semester': int.tryParse(data['semester']?.toString() ?? '1') ?? 1,
            'role': 'student',
          }, onConflict: 'roll_number');
          inserted++;
        } catch (e) {
          errors.add('Row error: $e');
        }
      }
      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          'Imported $inserted students. Errors: ${errors.length}',
        );
        _loadStudents();
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
        title: const Text('Students'),
        leading: BackButton(onPressed: () => context.go('/admin')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or roll number',
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onChanged: (v) {
                      setState(() => _searchQuery = v);
                      _loadStudents();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isImporting ? null : _importCsv,
                  icon: _isImporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.upload_file, size: 18),
                  label: const Text('Import'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const Center(child: Text('No students found.'))
                    : ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final s = _students[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                (s['name'] as String? ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(s['name'] ?? 'Unknown'),
                            subtitle: Text(
                              '${s['roll_number'] ?? ''} | ${s['branch'] ?? ''} ${s['section'] ?? ''} | Sem ${s['semester'] ?? ''}',
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

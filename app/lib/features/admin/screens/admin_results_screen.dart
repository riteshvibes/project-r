import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../../core/services/results_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/date_utils.dart';

class AdminResultsScreen extends StatefulWidget {
  const AdminResultsScreen({super.key});

  @override
  State<AdminResultsScreen> createState() => _AdminResultsScreenState();
}

class _AdminResultsScreenState extends State<AdminResultsScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _isImporting = false;
  final Set<String> _selectedIds = {};
  String? _filterSemester;
  String? _filterYear;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final results = await ResultsService.getAllResults(
        semester: _filterSemester != null ? int.tryParse(_filterSemester!) : null,
        academicYear: _filterYear,
      );
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to load results: $e');
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
      final dataRows = rows.skip(1).map((row) {
        return Map<String, dynamic>.fromIterables(
          headers,
          (row as List).map((v) => v?.toString().trim()),
        );
      }).toList();

      final importResult = await ResultsService.importResultsCsv(dataRows);
      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          'Imported ${importResult['inserted']} results. '
          'Errors: ${(importResult['errors'] as List).length}',
        );
        _loadResults();
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Import failed: $e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _togglePublish(bool publish) async {
    if (_selectedIds.isEmpty) {
      SnackbarUtils.showInfo(context, 'Select results to ${publish ? 'publish' : 'unpublish'}');
      return;
    }
    try {
      await ResultsService.publishResults(
        resultIds: _selectedIds.toList(),
        publish: publish,
      );
      SnackbarUtils.showSuccess(
        context,
        '${_selectedIds.length} results ${publish ? 'published' : 'unpublished'}',
      );
      _selectedIds.clear();
      _loadResults();
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Operation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Results'),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isImporting ? null : _importCsv,
                    icon: _isImporting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.upload_file),
                    label: Text(_isImporting ? 'Importing...' : 'Import CSV'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadResults,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(child: Text('No results found. Import a CSV to get started.'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final r = _results[index];
                          final isSelected = _selectedIds.contains(r['id']);
                          final isPublished = r['is_published'] == true;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : null,
                            child: ListTile(
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (_) => setState(() {
                                  if (isSelected) _selectedIds.remove(r['id']);
                                  else _selectedIds.add(r['id'] as String);
                                }),
                              ),
                              title: Text(
                                '${r['profiles']?['name'] ?? 'Unknown'} (${r['profiles']?['roll_number'] ?? ''})',
                              ),
                              subtitle: Text(
                                '${r['subjects']?['name'] ?? ''} | Sem ${r['semester']} | ${r['academic_year']}'
                                '\nMarks: ${r['marks_obtained']}/${r['max_marks']} | Grade: ${r['grade'] ?? '-'}',
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
          ),
        ],
      ),
    );
  }
}

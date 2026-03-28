import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/timetable_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/date_utils.dart';

class AdminTimetableScreen extends StatefulWidget {
  const AdminTimetableScreen({super.key});

  @override
  State<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends State<AdminTimetableScreen> {
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _entries = [];
  String? _selectedSectionId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      final sections = await Supabase.instance.client
          .from('sections')
          .select('id, name, batches(name, branches(name))')
          .order('name');
      if (mounted) setState(() => _sections = (sections as List).cast<Map<String, dynamic>>());
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to load sections: $e');
    }
  }

  Future<void> _loadEntries(String sectionId) async {
    setState(() => _isLoading = true);
    try {
      final entries = await TimetableService.getSectionTimetable(sectionId);
      if (mounted) setState(() => _entries = entries);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to load timetable: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEntry(String id) async {
    try {
      await TimetableService.deleteEntry(id);
      if (_selectedSectionId != null) _loadEntries(_selectedSectionId!);
      if (mounted) SnackbarUtils.showSuccess(context, 'Entry deleted');
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed: $e');
    }
  }

  Map<int, List<Map<String, dynamic>>> _groupByDay() {
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final entry in _entries) {
      final day = entry['day_of_week'] as int? ?? 0;
      grouped.putIfAbsent(day, () => []).add(entry);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        leading: BackButton(onPressed: () => context.go('/admin')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: _selectedSectionId,
              decoration: const InputDecoration(labelText: 'Select Section'),
              items: _sections.map((s) {
                final batch = s['batches'] as Map<String, dynamic>?;
                final branch = batch?['branches'] as Map<String, dynamic>?;
                return DropdownMenuItem(
                  value: s['id'] as String,
                  child: Text('${branch?['name'] ?? ''} - ${batch?['name'] ?? ''} - Sec ${s['name']}'),
                );
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedSectionId = v;
                  _entries = [];
                });
                if (v != null) _loadEntries(v);
              },
            ),
          ),
          Expanded(
            child: _selectedSectionId == null
                ? const Center(child: Text('Select a section to view timetable'))
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _entries.isEmpty
                        ? const Center(child: Text('No timetable entries for this section.'))
                        : ListView(
                            children: [
                              for (final day in grouped.keys.toList()..sort())
                                ExpansionTile(
                                  title: Text(
                                    AppDateUtils.getDayName(day),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  initiallyExpanded: true,
                                  children: [
                                    for (final entry in grouped[day]!)
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppTheme.primaryColor,
                                          child: Text(
                                            'P${entry['period_number']}',
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                        title: Text(entry['subjects']?['name'] ?? ''),
                                        subtitle: Text(
                                          '${entry['profiles']?['name'] ?? ''}'
                                          '${entry['room'] != null ? ' | Room: ${entry['room']}' : ''}',
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                                          onPressed: () => _deleteEntry(entry['id'] as String),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

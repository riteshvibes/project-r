import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/timetable_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';

class TeacherTimetableScreen extends StatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final teacherId = AuthService.currentUserId!;
      final data = await TimetableService.getTeacherTimetable(teacherId);
      if (mounted) setState(() { _entries = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to load timetable');
        setState(() => _isLoading = false);
      }
    }
  }

  Map<int, List<Map<String, dynamic>>> _groupByDay() {
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final e in _entries) {
      final day = e['day_of_week'] as int;
      grouped.putIfAbsent(day, () => []).add(e);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timetable'),
        leading: BackButton(onPressed: () => context.go('/teacher')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('No timetable available'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: grouped.entries.map((dayEntry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              AppDateUtils.getDayName(dayEntry.key),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                          ),
                          ...dayEntry.value.map((e) {
                            final section = e['sections'] as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.secondaryColor,
                                  child: Text('P${e['period_number']}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                                title: Text(e['subjects']['name'] as String),
                                subtitle: Text('Section ${section['name']}'),
                                trailing: e['room'] != null
                                    ? Chip(label: Text(e['room'] as String))
                                    : null,
                              ),
                            );
                          }),
                          const Divider(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/snackbar_utils.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<Map<String, dynamic>> _offerings = [];
  Map<String, dynamic>? _selectedOffering;
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _statuses = {};
  bool _isLoading = true;
  bool _isSaving = false;
  int _selectedPeriod = 1;
  DateTime _sessionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final teacherId = AuthService.currentUserId!;
      final data = await AttendanceService.getTeacherOfferings(teacherId);
      if (mounted) setState(() { _offerings = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to load courses');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStudents(String offeringId) async {
    setState(() => _isLoading = true);
    try {
      final students = await AttendanceService.getSessionStudents(offeringId);
      final statuses = {for (final s in students) s['student_id'] as String: AppConstants.statusPresent};
      if (mounted) setState(() { _students = students; _statuses = statuses; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to load students');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedOffering == null) return;
    setState(() => _isSaving = true);
    try {
      await AttendanceService.markAttendance(
        offeringId: _selectedOffering!['id'] as String,
        sessionDate: AppDateUtils.formatDbDate(_sessionDate),
        periodNumber: _selectedPeriod,
        studentStatuses: _statuses,
      );
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Attendance saved successfully');
        context.go('/teacher');
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to save attendance');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        leading: BackButton(onPressed: () => context.go('/teacher')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<Map<String, dynamic>>(
                        decoration: const InputDecoration(labelText: 'Select Course'),
                        items: _offerings.map((o) {
                          final subject = o['subjects'] as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: o,
                            child: Text('${subject['code']} - ${subject['name']}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedOffering = val);
                          if (val != null) _loadStudents(val['id'] as String);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Date: ${AppDateUtils.formatDisplayDate(_sessionDate)}'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _sessionDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) setState(() => _sessionDate = date);
                            },
                            child: const Text('Change'),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: _selectedPeriod,
                            items: List.generate(
                              AppConstants.maxPeriodsPerDay,
                              (i) => DropdownMenuItem(value: i + 1, child: Text('P${i + 1}')),
                            ),
                            onChanged: (v) => setState(() => _selectedPeriod = v!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_students.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text('${_students.length} students',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(() {
                            for (final k in _statuses.keys) {
                              _statuses[k] = AppConstants.statusPresent;
                            }
                          }),
                          child: const Text('Mark All Present'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, i) {
                        final s = _students[i];
                        final id = s['student_id'] as String;
                        return ListTile(
                          title: Text(s['name'] as String),
                          subtitle: Text(s['roll_number'] as String),
                          trailing: DropdownButton<String>(
                            value: _statuses[id],
                            items: [
                              AppConstants.statusPresent,
                              AppConstants.statusAbsent,
                              AppConstants.statusLate,
                            ]
                                .map((st) => DropdownMenuItem(
                                      value: st,
                                      child: Text(st.toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _statuses[id] = v!),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isSaving
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Save Attendance'),
                          ),
                  ),
                ],
              ],
            ),
    );
  }
}

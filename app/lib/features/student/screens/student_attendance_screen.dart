import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  List<Map<String, dynamic>> _summary = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final studentId = AuthService.currentUserId!;
      final data = await AttendanceService.getStudentAttendanceSummary(studentId);
      if (mounted) setState(() { _summary = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to load attendance');
        setState(() => _isLoading = false);
      }
    }
  }

  Color _percentageColor(double pct) {
    if (pct >= 75) return AppTheme.successColor;
    if (pct >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        leading: BackButton(onPressed: () => context.go('/student')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary.isEmpty
              ? const Center(child: Text('No attendance records found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _summary.length,
                    itemBuilder: (context, index) {
                      final item = _summary[index];
                      final pct = (item['percentage'] as double);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(item['subject_name'] as String,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            )),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _percentageColor(pct).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${pct.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: _percentageColor(pct),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(item['subject_code'] as String,
                                  style: const TextStyle(color: AppTheme.textSecondary)),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: pct / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(_percentageColor(pct)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${item['present_count']} / ${item['total_sessions']} classes attended',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

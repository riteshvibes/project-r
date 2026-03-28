import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  List<Map<String, dynamic>> _offerings = [];
  Map<String, dynamic>? _selectedOffering;
  List<Map<String, dynamic>> _studentSummaries = [];
  bool _isLoading = true;

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
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _pctColor(double pct) {
    if (pct >= 75) return AppTheme.successColor;
    if (pct >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        leading: BackButton(onPressed: () => context.go('/teacher')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(labelText: 'Select Course'),
                    items: _offerings.map((o) {
                      final subject = o['subjects'] as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: o,
                        child: Text('${subject['code']} - ${subject['name']}'),
                      );
                    }).toList(),
                    onChanged: (val) async {
                      setState(() { _selectedOffering = val; _isLoading = true; });
                      if (val == null) return;
                      try {
                        final students = await AttendanceService.getSessionStudents(val['id'] as String);
                        if (mounted) setState(() { _studentSummaries = students; _isLoading = false; });
                      } catch (_) {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                  ),
                ),
                if (_studentSummaries.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _studentSummaries.length,
                      itemBuilder: (context, i) {
                        final s = _studentSummaries[i];
                        return ListTile(
                          title: Text(s['name'] as String),
                          subtitle: Text(s['roll_number'] as String),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

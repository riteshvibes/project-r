import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/results_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final studentId = AuthService.currentUserId!;
      final data = await ResultsService.getStudentResults(studentId);
      if (mounted) setState(() { _results = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to load results');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Results'),
        leading: BackButton(onPressed: () => context.go('/student')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(child: Text('No results published yet'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final r = _results[index];
                      final grade = r['grade'] as String? ??
                          AppConstants.getGrade(
                              (r['marks_obtained'] as num).toDouble() /
                                  (r['max_marks'] as num).toDouble() *
                                  100);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(r['subjects']['name'] as String),
                          subtitle: Text(
                            'Semester ${r['semester']} • ${r['academic_year']}\n'
                            '${r['marks_obtained']} / ${r['max_marks']} marks',
                          ),
                          isThreeLine: true,
                          trailing: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              grade,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

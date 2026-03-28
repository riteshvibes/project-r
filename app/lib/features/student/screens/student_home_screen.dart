import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/snackbar_utils.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.getCurrentProfile();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _signOut() async {
    await AuthService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['name'] ?? 'Student';
    final rollNumber = _profile?['roll_number'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                )),
                        Text(rollNumber,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Quick Access',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _MenuCard(
                  icon: Icons.check_circle_outline,
                  label: 'Attendance',
                  color: AppTheme.secondaryColor,
                  onTap: () => context.go('/student/attendance'),
                ),
                _MenuCard(
                  icon: Icons.grade,
                  label: 'Results',
                  color: AppTheme.successColor,
                  onTap: () => context.go('/student/results'),
                ),
                _MenuCard(
                  icon: Icons.confirmation_number,
                  label: 'Hall Ticket',
                  color: AppTheme.warningColor,
                  onTap: () => context.go('/student/hall-ticket'),
                ),
                _MenuCard(
                  icon: Icons.notifications,
                  label: 'Notices',
                  color: AppTheme.accentColor,
                  onTap: () => context.go('/student/notices'),
                ),
                _MenuCard(
                  icon: Icons.calendar_today,
                  label: 'Timetable',
                  color: AppTheme.primaryColor,
                  onTap: () => context.go('/student/timetable'),
                ),
                _MenuCard(
                  icon: Icons.person,
                  label: 'Profile',
                  color: AppTheme.textSecondary,
                  onTap: () => context.go('/student/profile'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 8),
              Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

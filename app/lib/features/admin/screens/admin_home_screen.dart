import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_profile != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryColor,
                        child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Text(_profile!['name'] as String? ?? 'Admin',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Text('Management',
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
                  icon: Icons.people,
                  label: 'Students',
                  color: AppTheme.primaryColor,
                  onTap: () => context.go('/admin/students'),
                ),
                _MenuCard(
                  icon: Icons.school,
                  label: 'Teachers',
                  color: AppTheme.secondaryColor,
                  onTap: () => context.go('/admin/teachers'),
                ),
                _MenuCard(
                  icon: Icons.grade,
                  label: 'Results',
                  color: AppTheme.successColor,
                  onTap: () => context.go('/admin/results'),
                ),
                _MenuCard(
                  icon: Icons.confirmation_number,
                  label: 'Hall Tickets',
                  color: AppTheme.warningColor,
                  onTap: () => context.go('/admin/hall-tickets'),
                ),
                _MenuCard(
                  icon: Icons.notifications,
                  label: 'Notices',
                  color: AppTheme.accentColor,
                  onTap: () => context.go('/admin/notices'),
                ),
                _MenuCard(
                  icon: Icons.calendar_today,
                  label: 'Timetable',
                  color: AppTheme.errorColor,
                  onTap: () => context.go('/admin/timetable'),
                ),
                _MenuCard(
                  icon: Icons.account_tree,
                  label: 'Structure',
                  color: AppTheme.textSecondary,
                  onTap: () => context.go('/admin/structure'),
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

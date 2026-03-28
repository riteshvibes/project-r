import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/student/screens/student_home_screen.dart';
import 'features/teacher/screens/teacher_home_screen.dart';
import 'features/admin/screens/admin_home_screen.dart';
import 'features/shared/screens/splash_screen.dart';
import 'features/student/screens/student_attendance_screen.dart';
import 'features/student/screens/student_results_screen.dart';
import 'features/student/screens/student_hall_ticket_screen.dart';
import 'features/student/screens/student_timetable_screen.dart';
import 'features/shared/screens/notices_screen.dart';
import 'features/shared/screens/profile_screen.dart';
import 'features/teacher/screens/mark_attendance_screen.dart';
import 'features/teacher/screens/attendance_report_screen.dart';
import 'features/teacher/screens/teacher_timetable_screen.dart';
import 'features/admin/screens/admin_students_screen.dart';
import 'features/admin/screens/admin_teachers_screen.dart';
import 'features/admin/screens/admin_results_screen.dart';
import 'features/admin/screens/admin_hall_tickets_screen.dart';
import 'features/admin/screens/admin_notices_screen.dart';
import 'features/admin/screens/admin_timetable_screen.dart';
import 'features/admin/screens/admin_structure_screen.dart';

class UniversityPortalApp extends StatelessWidget {
  const UniversityPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) async {
    final session = Supabase.instance.client.auth.currentSession;
    final isOnSplash = state.matchedLocation == '/splash';
    final isOnLogin = state.matchedLocation == '/login';

    if (session == null && !isOnLogin && !isOnSplash) {
      return '/login';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/student',
      builder: (context, state) => const StudentHomeScreen(),
      routes: [
        GoRoute(
          path: 'attendance',
          builder: (context, state) => const StudentAttendanceScreen(),
        ),
        GoRoute(
          path: 'results',
          builder: (context, state) => const StudentResultsScreen(),
        ),
        GoRoute(
          path: 'hall-ticket',
          builder: (context, state) => const StudentHallTicketScreen(),
        ),
        GoRoute(
          path: 'notices',
          builder: (context, state) => const NoticesScreen(role: AppConstants.roleStudent),
        ),
        GoRoute(
          path: 'timetable',
          builder: (context, state) => const StudentTimetableScreen(),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/teacher',
      builder: (context, state) => const TeacherHomeScreen(),
      routes: [
        GoRoute(
          path: 'mark-attendance',
          builder: (context, state) => const MarkAttendanceScreen(),
        ),
        GoRoute(
          path: 'attendance-report',
          builder: (context, state) => const AttendanceReportScreen(),
        ),
        GoRoute(
          path: 'timetable',
          builder: (context, state) => const TeacherTimetableScreen(),
        ),
        GoRoute(
          path: 'notices',
          builder: (context, state) => const NoticesScreen(role: AppConstants.roleTeacher),
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminHomeScreen(),
      routes: [
        GoRoute(
          path: 'students',
          builder: (context, state) => const AdminStudentsScreen(),
        ),
        GoRoute(
          path: 'teachers',
          builder: (context, state) => const AdminTeachersScreen(),
        ),
        GoRoute(
          path: 'results',
          builder: (context, state) => const AdminResultsScreen(),
        ),
        GoRoute(
          path: 'hall-tickets',
          builder: (context, state) => const AdminHallTicketsScreen(),
        ),
        GoRoute(
          path: 'notices',
          builder: (context, state) => const AdminNoticesScreen(),
        ),
        GoRoute(
          path: 'timetable',
          builder: (context, state) => const AdminTimetableScreen(),
        ),
        GoRoute(
          path: 'structure',
          builder: (context, state) => const AdminStructureScreen(),
        ),
      ],
    ),
  ],
);

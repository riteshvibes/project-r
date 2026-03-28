import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminTimetableScreen extends StatelessWidget {
  const AdminTimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Timetable'),
        leading: BackButton(onPressed: () => context.go('/admin')),
      ),
      body: const Center(
        child: Text('Manage Timetable\nComing soon', textAlign: TextAlign.center),
      ),
    );
  }
}

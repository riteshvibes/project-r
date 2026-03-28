import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminStudentsScreen extends StatelessWidget {
  const AdminStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        leading: BackButton(onPressed: () => context.go('/admin')),
      ),
      body: const Center(
        child: Text('Manage Students\nComing soon', textAlign: TextAlign.center),
      ),
    );
  }
}

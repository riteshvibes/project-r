import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminTeachersScreen extends StatelessWidget {
  const AdminTeachersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teachers'),
        leading: BackButton(onPressed: () => context.go('/admin')),
      ),
      body: const Center(
        child: Text('Manage Teachers\nComing soon', textAlign: TextAlign.center),
      ),
    );
  }
}

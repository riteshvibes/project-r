import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminNoticesScreen extends StatelessWidget {
  const AdminNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Notices'),
        leading: BackButton(onPressed: () => context.go('/admin')),
      ),
      body: const Center(
        child: Text('Manage Notices\nComing soon', textAlign: TextAlign.center),
      ),
    );
  }
}

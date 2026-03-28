import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminResultsScreen extends StatelessWidget {
  const AdminResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Results'),
        leading: BackButton(onPressed: () => context.go('/admin')),
      ),
      body: const Center(
        child: Text('Manage Results\nComing soon', textAlign: TextAlign.center),
      ),
    );
  }
}

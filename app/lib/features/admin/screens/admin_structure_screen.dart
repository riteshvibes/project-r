import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminStructureScreen extends StatelessWidget {
  const AdminStructureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Structure'),
        leading: BackButton(onPressed: () => context.go('/admin')),
      ),
      body: const Center(
        child: Text('Academic Structure\nComing soon', textAlign: TextAlign.center),
      ),
    );
  }
}

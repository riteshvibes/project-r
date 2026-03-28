import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminHallTicketsScreen extends StatelessWidget {
  const AdminHallTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hall Tickets'),
        leading: BackButton(onPressed: () => context.go('/admin')),
      ),
      body: const Center(
        child: Text('Hall Tickets\nComing soon', textAlign: TextAlign.center),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ChecklistPage extends StatelessWidget {
  final String sessionId;

  const ChecklistPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Checklist')),
    );
  }
}

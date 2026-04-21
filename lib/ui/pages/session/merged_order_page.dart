import 'package:flutter/material.dart';

class MergedOrderPage extends StatelessWidget {
  final String sessionId;

  const MergedOrderPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Merged Order')),
    );
  }
}

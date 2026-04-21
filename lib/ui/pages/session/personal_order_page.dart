import 'package:flutter/material.dart';

class PersonalOrderPage extends StatelessWidget {
  final String sessionId;

  const PersonalOrderPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Personal Order')),
    );
  }
}

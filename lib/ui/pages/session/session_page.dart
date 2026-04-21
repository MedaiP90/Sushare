import 'package:flutter/material.dart';

class SessionPage extends StatelessWidget {
  final String sessionId;
  final Widget child;

  const SessionPage({
    super.key,
    required this.sessionId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
    );
  }
}

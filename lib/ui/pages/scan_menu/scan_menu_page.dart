import 'package:flutter/material.dart';

class ScanMenuPage extends StatelessWidget {
  final String restaurantId;

  const ScanMenuPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Scan Menu')),
    );
  }
}

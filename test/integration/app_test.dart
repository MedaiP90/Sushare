import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sushare/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sushare App Integration Tests', () {
    testWidgets('App launches and shows profile setup on first run', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: SushareApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Profile setup page renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: SushareApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Welcome to Sushare'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Can enter profile information', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: SushareApp()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Username'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'First Name'),
        'Test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Last Name'),
        'User',
      );
      await tester.pump();

      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);
    });
  });
}
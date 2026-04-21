import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'ui/viewmodels/profile_viewmodel.dart';
import 'ui/pages/home/settings_page.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SushareApp(),
    ),
  );
}

class SushareApp extends ConsumerWidget {
  const SushareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(profileViewModelProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Sushare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(context),
      darkTheme: AppTheme.dark(context),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
      builder: (context, child) {
        return userAsync.when(
          data: (_) => child ?? const SizedBox.shrink(),
          loading: () => MaterialApp(
            theme: AppTheme.light(context),
            darkTheme: AppTheme.dark(context),
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (e, _) => MaterialApp(
            theme: AppTheme.light(context),
            home: Scaffold(
              body: Center(
                child: Text('Error: $e'),
              ),
            ),
          ),
        );
      },
    );
  }
}

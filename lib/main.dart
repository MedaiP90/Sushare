import 'package:dynamic_color/dynamic_color.dart';
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
    final savedLocale = ref.watch(localeProvider);

    final Locale effectiveLocale;
    if (savedLocale != null) {
      effectiveLocale = savedLocale;
    } else {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final supported = AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .toSet();
      effectiveLocale = supported.contains(systemLocale.languageCode)
          ? Locale(systemLocale.languageCode)
          : const Locale('en');
    }

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          title: 'Sushare',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(dynamicScheme: lightDynamic),
          darkTheme: AppTheme.dark(dynamicScheme: darkDynamic),
          themeMode: themeMode,
          locale: effectiveLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
          builder: (context, child) {
            return userAsync.when(
              data: (_) => child ?? const SizedBox.shrink(),
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Scaffold(
                body: Center(child: Text('Error: $e')),
              ),
            );
          },
        );
      },
    );
  }
}

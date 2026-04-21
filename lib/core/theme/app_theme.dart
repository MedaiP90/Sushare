import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _fallbackSeed = Color(0xFFC0392B);

TextTheme buildTextTheme() => GoogleFonts.nunitoTextTheme().copyWith(
  displayLarge: GoogleFonts.nunito(fontWeight: FontWeight.w800),
  displayMedium: GoogleFonts.nunito(fontWeight: FontWeight.w700),
  displaySmall: GoogleFonts.nunito(fontWeight: FontWeight.w700),
  headlineLarge: GoogleFonts.nunito(fontWeight: FontWeight.w700),
  headlineMedium: GoogleFonts.nunito(fontWeight: FontWeight.w600),
  headlineSmall: GoogleFonts.nunito(fontWeight: FontWeight.w600),
  titleLarge: GoogleFonts.nunito(fontWeight: FontWeight.w600),
  titleMedium: GoogleFonts.nunito(fontWeight: FontWeight.w600),
  titleSmall: GoogleFonts.nunito(fontWeight: FontWeight.w500),
  bodyLarge: GoogleFonts.sourceSerif4(),
  bodyMedium: GoogleFonts.sourceSerif4(),
  bodySmall: GoogleFonts.sourceSerif4(),
  labelLarge: GoogleFonts.nunito(fontWeight: FontWeight.w600),
  labelMedium: GoogleFonts.nunito(fontWeight: FontWeight.w500),
  labelSmall: GoogleFonts.nunito(fontWeight: FontWeight.w500),
);

class AppTheme {
  static ThemeData light(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _fallbackSeed,
      brightness: Brightness.light,
    );

    return FlexThemeData.light(
      colorScheme: colorScheme,
      textTheme: buildTextTheme(),
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        cardRadius: 24,
        filledButtonRadius: 16,
        outlinedButtonRadius: 16,
        fabRadius: 16,
        chipRadius: 12,
        inputDecoratorRadius: 12,
        dialogRadius: 24,
        bottomSheetRadius: 24,
      ),
    );
  }

  static ThemeData dark(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _fallbackSeed,
      brightness: Brightness.dark,
    );

    return FlexThemeData.dark(
      colorScheme: colorScheme,
      textTheme: buildTextTheme(),
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        cardRadius: 24,
        filledButtonRadius: 16,
        outlinedButtonRadius: 16,
        fabRadius: 16,
        chipRadius: 12,
        inputDecoratorRadius: 12,
        dialogRadius: 24,
        bottomSheetRadius: 24,
      ),
    );
  }
}

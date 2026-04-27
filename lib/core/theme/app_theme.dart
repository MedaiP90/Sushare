import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

const Color fallbackSeed = Color(0xFFFF7E70);

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

const _subThemes = FlexSubThemesData(
  cardRadius: 24,
  filledButtonRadius: 16,
  outlinedButtonRadius: 16,
  fabRadius: 16,
  chipRadius: 12,
  inputDecoratorRadius: 12,
  dialogRadius: 24,
  bottomSheetRadius: 28,
);

class AppTheme {
  static ThemeData light({ColorScheme? dynamicScheme}) {
    final colorScheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: fallbackSeed,
          brightness: Brightness.light,
        );

    return FlexThemeData.light(
      colorScheme: colorScheme,
      textTheme: buildTextTheme(),
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: _subThemes,
    );
  }

  static ThemeData dark({ColorScheme? dynamicScheme}) {
    final colorScheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: fallbackSeed,
          brightness: Brightness.dark,
        );

    return FlexThemeData.dark(
      colorScheme: colorScheme,
      textTheme: buildTextTheme(),
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: _subThemes,
    );
  }
}

class AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delay;

  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 50),
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
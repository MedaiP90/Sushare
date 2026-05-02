import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../core/style/app_style.dart';

class GlassAwareAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const GlassAwareAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styleMode = ref.watch(styleModeProvider);

    if (styleMode == AppStyleMode.liquidGlass) {
      return _GlassBar(
        title: title,
        leading: leading,
        actions: actions,
        centerTitle: centerTitle,
        automaticallyImplyLeading: automaticallyImplyLeading,
        preferredSize: preferredSize,
      );
    }

    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}

LiquidGlassSettings glassBarButtonSettings(bool isLight) =>
    LiquidGlassSettings(
      blur: isLight ? 12 : 8,
      thickness: 25,
      glassColor: isLight ? const Color(0x18000000) : const Color(0x30FFFFFF),
    );

class _GlassBar extends StatelessWidget implements PreferredSizeWidget {
  const _GlassBar({
    required this.title,
    required this.leading,
    required this.actions,
    required this.centerTitle,
    required this.automaticallyImplyLeading,
    required this.preferredSize,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final iconColor = isLight ? Colors.black87 : Colors.white;
    final settings = glassBarButtonSettings(isLight);

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && automaticallyImplyLeading && canPop) {
      effectiveLeading = GlassIconButton(
        icon: Icon(Icons.arrow_back_ios_new, size: 18, color: iconColor),
        onPressed: () => Navigator.of(context).maybePop(),
        useOwnLayer: true,
        size: 36,
        settings: settings,
      );
    }

    Widget? glassTitle;
    if (title != null) {
      glassTitle = GlassContainer(
        useOwnLayer: true,
        settings: settings,
        shape: const LiquidRoundedSuperellipse(borderRadius: 20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: iconColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          child: title!,
        ),
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: glassTitle,
      leading: effectiveLeading,
      actions: actions,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
    );
  }
}

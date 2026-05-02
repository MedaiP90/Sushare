import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/style/app_style.dart';

/// A Scaffold that, in Liquid Glass mode, extends the body behind the app bar
/// and injects corrected top padding so scroll views start below the bar.
///
/// In Material mode it behaves exactly like a standard [Scaffold].
class GlassAwareScaffold extends ConsumerWidget {
  const GlassAwareScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGlass =
        ref.watch(styleModeProvider) == AppStyleMode.liquidGlass;

    if (!isGlass) {
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: backgroundColor,
      );
    }

    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final barHeight = appBar?.preferredSize.height ?? 0.0;
    final topInset = statusBarHeight + barHeight;

    // Inject extra top padding so SafeArea / scroll views start below the bar.
    final paddedBody = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: MediaQuery.paddingOf(context).copyWith(top: topInset),
      ),
      child: body,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: appBar,
      body: paddedBody,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
    );
  }
}

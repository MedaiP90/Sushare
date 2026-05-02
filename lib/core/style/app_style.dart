import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppStyleMode { material, liquidGlass }

final styleModeProvider =
    StateNotifierProvider<StyleModeNotifier, AppStyleMode>((ref) {
  return StyleModeNotifier();
});

class StyleModeNotifier extends StateNotifier<AppStyleMode> {
  StyleModeNotifier()
      : super(
          Platform.isIOS ? AppStyleMode.liquidGlass : AppStyleMode.material,
        ) {
    _load();
  }

  static const _key = 'style_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = AppStyleMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () =>
            Platform.isIOS ? AppStyleMode.liquidGlass : AppStyleMode.material,
      );
    }
  }

  Future<void> setStyle(AppStyleMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

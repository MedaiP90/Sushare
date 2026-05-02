import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bottomActionsProvider =
    StateNotifierProvider<BottomActionsNotifier, List<Widget>>(
      (ref) => BottomActionsNotifier(),
    );

class BottomActionsNotifier extends StateNotifier<List<Widget>> {
  BottomActionsNotifier() : super([]);
  void setActions(List<Widget> actions) => state = actions;
  void clear() => state = [];
}
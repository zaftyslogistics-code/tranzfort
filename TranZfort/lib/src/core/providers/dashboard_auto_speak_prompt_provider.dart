import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state_providers.dart';

class DashboardAutoSpeakPromptController extends StateNotifier<Set<String>> {
  DashboardAutoSpeakPromptController() : super(const <String>{});

  bool consume(String key) {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty || state.contains(normalizedKey)) {
      return false;
    }
    state = <String>{...state, normalizedKey};
    return true;
  }

  void reset() {
    if (state.isEmpty) {
      return;
    }
    state = const <String>{};
  }
}

final dashboardAutoSpeakPromptProvider =
    StateNotifierProvider<DashboardAutoSpeakPromptController, Set<String>>((ref) {
  final controller = DashboardAutoSpeakPromptController();
  ref.listen(currentAuthStateProvider, (previous, next) {
    if ((previous?.hasSession ?? false) && !next.hasSession) {
      controller.reset();
    }
  });
  return controller;
});

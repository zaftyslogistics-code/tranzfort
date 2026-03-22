import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_dashboard_repository.dart';

final adminDashboardProvider = AutoDisposeAsyncNotifierProvider<AdminDashboardNotifier, AdminDashboardSnapshot>(
  AdminDashboardNotifier.new,
);

class AdminDashboardNotifier extends AutoDisposeAsyncNotifier<AdminDashboardSnapshot> {
  @override
  Future<AdminDashboardSnapshot> build() {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<AdminDashboardSnapshot> _load() {
    return ref.read(adminDashboardRepositoryProvider).fetchSnapshot();
  }
}

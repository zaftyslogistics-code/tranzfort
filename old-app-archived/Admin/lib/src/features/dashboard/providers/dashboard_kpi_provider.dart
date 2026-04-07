import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_dashboard_repository.dart';

final dashboardKpiProvider =
    AutoDisposeAsyncNotifierProvider<
      DashboardKpiNotifier,
      AdminDashboardSnapshot
    >(DashboardKpiNotifier.new);

class DashboardKpiNotifier
    extends AutoDisposeAsyncNotifier<AdminDashboardSnapshot> {
  @override
  Future<AdminDashboardSnapshot> build() async {
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

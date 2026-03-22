import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_audit_log_repository.dart';
import '../../../core/repositories/admin_load_management_repository.dart';

class AdminLoadManagementState {
  final AdminLoadManagementQuery query;
  final bool isLoading;
  final List<AdminLoadListItem> items;

  const AdminLoadManagementState({required this.query, required this.isLoading, required this.items});

  factory AdminLoadManagementState.initial() {
    return AdminLoadManagementState(
      query: const AdminLoadManagementQuery(filter: AdminLoadFilter.all, search: ''),
      isLoading: false,
      items: const [],
    );
  }

  AdminLoadManagementState copyWith({AdminLoadManagementQuery? query, bool? isLoading, List<AdminLoadListItem>? items}) {
    return AdminLoadManagementState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
    );
  }
}

class AdminLoadActionState {
  final bool isLoading;

  const AdminLoadActionState({this.isLoading = false});
}

class AdminLoadManagementController extends AutoDisposeAsyncNotifier<AdminLoadManagementState> {
  @override
  Future<AdminLoadManagementState> build() async {
    final query = AdminLoadManagementState.initial().query;
    final items = await ref.read(adminLoadManagementRepositoryProvider).getLoads(query);
    return AdminLoadManagementState.initial().copyWith(query: query, items: items);
  }

  Future<void> updateSearch(String value) async {
    final current = state.value ?? AdminLoadManagementState.initial();
    await _reload(current.query.copyWith(search: value));
  }

  Future<void> updateFilter(AdminLoadFilter filter) async {
    final current = state.value ?? AdminLoadManagementState.initial();
    await _reload(current.query.copyWith(filter: filter));
  }

  Future<void> refresh() async {
    final current = state.value ?? AdminLoadManagementState.initial();
    await _reload(current.query);
  }

  Future<void> _reload(AdminLoadManagementQuery query) async {
    final current = state.value ?? AdminLoadManagementState.initial();
    state = AsyncData(current.copyWith(query: query, isLoading: true));
    final items = await ref.read(adminLoadManagementRepositoryProvider).getLoads(query);
    state = AsyncData(current.copyWith(query: query, isLoading: false, items: items));
  }
}

class AdminLoadActionController extends AutoDisposeNotifier<AdminLoadActionState> {
  @override
  AdminLoadActionState build() => const AdminLoadActionState();

  Future<bool> cancelLoad(String loadId) async {
    state = const AdminLoadActionState(isLoading: true);
    final ok = await ref.read(adminLoadManagementRepositoryProvider).cancelLoad(loadId);
    state = const AdminLoadActionState(isLoading: false);
    return ok;
  }
}

final adminLoadManagementProvider = AutoDisposeAsyncNotifierProvider<AdminLoadManagementController, AdminLoadManagementState>(
  AdminLoadManagementController.new,
);

final adminLoadActionProvider = AutoDisposeNotifierProvider<AdminLoadActionController, AdminLoadActionState>(
  AdminLoadActionController.new,
);

final adminLoadDetailProvider = FutureProvider.autoDispose.family<AdminLoadDetail?, String>((ref, loadId) async {
  return ref.watch(adminLoadManagementRepositoryProvider).getLoadDetail(loadId);
});

final adminLoadAuditTrailProvider = FutureProvider.autoDispose.family<List<AdminAuditLogEntry>, String>((ref, loadId) async {
  final page = await ref.watch(adminAuditLogRepositoryProvider).searchAuditLogs(
        AdminAuditLogQuery(
          filter: AdminAuditLogFilter.all,
          search: loadId,
          pageSize: 50,
        ),
      );
  return page.items
      .where(
        (entry) =>
            (entry.targetObjectType == 'load' && entry.targetObjectId == loadId) ||
            (entry.secondaryObjectType == 'load' && entry.secondaryObjectId == loadId),
      )
      .take(8)
      .toList(growable: false);
});

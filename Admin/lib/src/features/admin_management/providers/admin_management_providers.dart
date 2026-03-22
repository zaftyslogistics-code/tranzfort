import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_management_repository.dart';

class AdminManagementState {
  final AdminManagementQuery query;
  final bool isLoading;
  final List<AdminManagementListItem> items;
  final AdminManagementSummary summary;

  const AdminManagementState({
    required this.query,
    required this.isLoading,
    required this.items,
    required this.summary,
  });

  factory AdminManagementState.initial() {
    return AdminManagementState(
      query: const AdminManagementQuery(filter: AdminManagementFilter.all, search: ''),
      isLoading: false,
      items: const [],
      summary: AdminManagementSummary.empty(),
    );
  }

  AdminManagementState copyWith({
    AdminManagementQuery? query,
    bool? isLoading,
    List<AdminManagementListItem>? items,
    AdminManagementSummary? summary,
  }) {
    return AdminManagementState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      summary: summary ?? this.summary,
    );
  }
}

class AdminManagementController extends AutoDisposeAsyncNotifier<AdminManagementState> {
  @override
  Future<AdminManagementState> build() async {
    final query = const AdminManagementQuery(filter: AdminManagementFilter.all, search: '');
    final page = await ref.read(adminManagementRepositoryProvider).searchAdmins(query);
    return AdminManagementState.initial().copyWith(
      query: query,
      items: page.items,
      summary: page.summary,
    );
  }

  Future<void> updateSearch(String value) async {
    final current = state.value ?? AdminManagementState.initial();
    await _reload(current.query.copyWith(search: value));
  }

  Future<void> updateFilter(AdminManagementFilter filter) async {
    final current = state.value ?? AdminManagementState.initial();
    await _reload(current.query.copyWith(filter: filter));
  }

  Future<void> refresh() async {
    final current = state.value ?? AdminManagementState.initial();
    await _reload(current.query);
  }

  Future<void> _reload(AdminManagementQuery query) async {
    final current = state.value ?? AdminManagementState.initial();
    state = AsyncData(current.copyWith(query: query, isLoading: true));
    final page = await ref.read(adminManagementRepositoryProvider).searchAdmins(query);
    state = AsyncData(
      current.copyWith(
        query: query,
        isLoading: false,
        items: page.items,
        summary: page.summary,
      ),
    );
  }
}

final adminManagementProvider =
    AutoDisposeAsyncNotifierProvider<AdminManagementController, AdminManagementState>(
  AdminManagementController.new,
);

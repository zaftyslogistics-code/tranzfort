import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_audit_log_repository.dart';

class AdminAuditLogState {
  final AdminAuditLogQuery query;
  final bool isLoading;
  final List<AdminAuditLogEntry> items;
  final bool hasMore;
  final AdminAuditLogSummary summary;

  const AdminAuditLogState({
    required this.query,
    required this.isLoading,
    required this.items,
    required this.hasMore,
    required this.summary,
  });

  factory AdminAuditLogState.initial() {
    return AdminAuditLogState(
      query: const AdminAuditLogQuery(filter: AdminAuditLogFilter.all, search: ''),
      isLoading: false,
      items: const [],
      hasMore: false,
      summary: AdminAuditLogSummary.empty(),
    );
  }

  AdminAuditLogState copyWith({
    AdminAuditLogQuery? query,
    bool? isLoading,
    List<AdminAuditLogEntry>? items,
    bool? hasMore,
    AdminAuditLogSummary? summary,
  }) {
    return AdminAuditLogState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      summary: summary ?? this.summary,
    );
  }
}

class AdminAuditLogController extends AutoDisposeAsyncNotifier<AdminAuditLogState> {
  @override
  Future<AdminAuditLogState> build() async {
    final query = const AdminAuditLogQuery(filter: AdminAuditLogFilter.all, search: '');
    final page = await ref.read(adminAuditLogRepositoryProvider).searchAuditLogs(query);
    return AdminAuditLogState.initial().copyWith(
      query: query,
      items: page.items,
      hasMore: page.hasMore,
      summary: page.summary,
    );
  }

  Future<void> updateSearch(String value) async {
    final current = state.value ?? AdminAuditLogState.initial();
    await _reload(current.query.copyWith(search: value, page: 0));
  }

  Future<void> updateFilter(AdminAuditLogFilter filter) async {
    final current = state.value ?? AdminAuditLogState.initial();
    await _reload(current.query.copyWith(filter: filter, page: 0));
  }

  Future<void> updateActorType(String value) async {
    final current = state.value ?? AdminAuditLogState.initial();
    await _reload(current.query.copyWith(actorType: value, page: 0));
  }

  Future<void> updateTargetObjectType(String value) async {
    final current = state.value ?? AdminAuditLogState.initial();
    await _reload(current.query.copyWith(targetObjectType: value, page: 0));
  }

  Future<void> updateDateRange({
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    final current = state.value ?? AdminAuditLogState.initial();
    await _reload(
      current.query.copyWith(
        startDate: startDate,
        endDate: endDate,
        page: 0,
      ),
    );
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || current.isLoading || !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoading: true));
    final nextQuery = current.query.copyWith(page: current.query.page + 1);
    final nextPage = await ref.read(adminAuditLogRepositoryProvider).searchAuditLogs(nextQuery);
    state = AsyncData(
      current.copyWith(
        query: nextQuery,
        isLoading: false,
        items: [...current.items, ...nextPage.items],
        hasMore: nextPage.hasMore,
        summary: nextPage.summary,
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.value ?? AdminAuditLogState.initial();
    await _reload(current.query.copyWith(page: 0));
  }

  Future<void> _reload(AdminAuditLogQuery query) async {
    final current = state.value ?? AdminAuditLogState.initial();
    state = AsyncData(current.copyWith(query: query, isLoading: true));
    final page = await ref.read(adminAuditLogRepositoryProvider).searchAuditLogs(query);
    state = AsyncData(
      current.copyWith(
        query: query,
        isLoading: false,
        items: page.items,
        hasMore: page.hasMore,
        summary: page.summary,
      ),
    );
  }
}

final adminAuditLogProvider = AutoDisposeAsyncNotifierProvider<AdminAuditLogController, AdminAuditLogState>(
  AdminAuditLogController.new,
);

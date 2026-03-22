import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../data/supplier_dashboard_repository.dart';
import '../data/supplier_load_models.dart';
import '../data/supplier_load_repository.dart';
import '../data/supplier_profile_repository.dart';

final supplierProfileProvider = FutureProvider<SupplierProfile?>((ref) async {
  final result = await ref.watch(supplierProfileRepositoryProvider).fetchCurrentSupplierProfile();
  return result.when(
    success: (value) => value,
    failure: (failure) => throw failure,
  );
});

final supplierDashboardProvider = FutureProvider<SupplierDashboardStats>((ref) async {
  final result = await ref.watch(supplierDashboardRepositoryProvider).fetchDashboardStats();
  return result.when(
    success: (value) => value,
    failure: (failure) => throw failure,
  );
});

final supplierRecentLoadsProvider = FutureProvider<List<Load>>((ref) async {
  final result = await ref.watch(supplierLoadRepositoryProvider).getMyLoads(const LoadFilters());
  return result.when(
    success: (value) => value.take(5).toList(growable: false),
    failure: (failure) => throw failure,
  );
});

AppFailure? supplierAsyncFailure(AsyncValue<Object?> value) {
  final error = value.asError?.error;
  if (error is AppFailure) {
    return error;
  }

  return null;
}

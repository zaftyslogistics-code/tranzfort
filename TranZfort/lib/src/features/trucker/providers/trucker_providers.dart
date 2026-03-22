import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../data/trucker_dashboard_repository.dart';
import '../data/trucker_profile_repository.dart';

final truckerProfileProvider = FutureProvider<TruckerProfile?>((ref) async {
  final result = await ref.watch(truckerProfileRepositoryProvider).fetchCurrentTruckerProfile();
  return result.when(
    success: (value) => value,
    failure: (failure) => throw failure,
  );
});

final truckerDashboardProvider = FutureProvider<TruckerDashboardStats>((ref) async {
  final result = await ref.watch(truckerDashboardRepositoryProvider).fetchDashboardStats();
  return result.when(
    success: (value) => value,
    failure: (failure) => throw failure,
  );
});

AppFailure? truckerAsyncFailure(AsyncValue<Object?> value) {
  final error = value.asError?.error;
  if (error is AppFailure) {
    return error;
  }

  return null;
}

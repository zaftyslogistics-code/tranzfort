import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_verification_repository.dart';
import 'verification_queue_provider.dart';

final verificationDetailProvider =
    FutureProvider.family<VerificationDetail?, VerificationDetailArgs>((
      ref,
      args,
    ) {
      return ref
          .read(adminVerificationRepositoryProvider)
          .fetchDetail(type: args.type, id: args.id);
    });

final verificationActionProvider =
    StateNotifierProvider<VerificationActionNotifier, AsyncValue<void>>(
      (ref) => VerificationActionNotifier(ref),
    );

class VerificationActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  VerificationActionNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> approve({
    required VerificationEntityType type,
    required String id,
  }) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminVerificationRepositoryProvider)
        .approve(type: type, id: id);
    state = const AsyncData(null);
    if (ok) {
      _ref.invalidate(verificationQueuesProvider);
      _ref.invalidate(
        verificationDetailProvider(VerificationDetailArgs(type, id)),
      );
    }
    return ok;
  }

  Future<bool> reject({
    required VerificationEntityType type,
    required String id,
    required String reason,
    List<String> reasonCodes = const [],
  }) async {
    state = const AsyncLoading();
    final ok = await _ref
        .read(adminVerificationRepositoryProvider)
        .reject(type: type, id: id, reason: reason, reasonCodes: reasonCodes);
    state = const AsyncData(null);
    if (ok) {
      _ref.invalidate(verificationQueuesProvider);
      _ref.invalidate(
        verificationDetailProvider(VerificationDetailArgs(type, id)),
      );
    }
    return ok;
  }
}

class VerificationDetailArgs {
  final VerificationEntityType type;
  final String id;

  const VerificationDetailArgs(this.type, this.id);

  @override
  bool operator ==(Object other) {
    return other is VerificationDetailArgs &&
        other.type == type &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(type, id);
}

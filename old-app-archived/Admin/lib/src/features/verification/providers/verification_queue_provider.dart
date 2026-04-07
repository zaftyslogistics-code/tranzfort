import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_verification_repository.dart';

final verificationQueuesProvider =
    AutoDisposeAsyncNotifierProvider<
      VerificationQueuesNotifier,
      VerificationQueues
    >(VerificationQueuesNotifier.new);

class VerificationQueuesNotifier
    extends AutoDisposeAsyncNotifier<VerificationQueues> {
  @override
  Future<VerificationQueues> build() async {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<VerificationQueues> _load() {
    return ref.read(adminVerificationRepositoryProvider).fetchQueues();
  }
}

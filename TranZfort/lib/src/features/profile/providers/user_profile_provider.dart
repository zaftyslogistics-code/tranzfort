import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';

final currentUserProfileProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  return ref.watch(userProfileProvider).value;
});

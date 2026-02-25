import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';

class BanCheckWrapper extends ConsumerWidget {
  final Widget child;

  const BanCheckWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      data: (profile) {
        if (profile == null) {
          // Profile not yet loaded or user not logged in, just return child
          return child;
        }

        final isBanned = profile['is_banned'] as bool? ?? false;

        if (isBanned) {
          final banReason =
              profile['ban_reason'] as String? ?? 'Violation of terms.';

          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Account Suspended',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(banReason, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) {
                          context.go('/auth');
                        }
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Not banned
        return child;
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) =>
          Scaffold(body: Center(child: Text('Error loading profile: $e'))),
    );
  }
}

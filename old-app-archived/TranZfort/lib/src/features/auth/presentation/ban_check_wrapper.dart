import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
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
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: AppSpacing.iconDisplay,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Account Suspended',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(banReason, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Sign Out',
                      onPressed: () async {
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) {
                          context.go('/auth');
                        }
                      },
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

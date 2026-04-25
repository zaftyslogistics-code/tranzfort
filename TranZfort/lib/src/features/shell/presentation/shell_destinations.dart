import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/feedback_components.dart';
import 'shell_components.dart';
export 'shell_account_screens.dart' show AccountScreen, ProfileScreen, SettingsScreen;
import 'shell_messages_screen.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenWrapperState();
}

class _MessagesScreenWrapperState extends ConsumerState<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    return const ShellMessagesScreen();
  }
}

class AccessRestrictedScreen extends ConsumerStatefulWidget {
  const AccessRestrictedScreen({super.key});

  @override
  ConsumerState<AccessRestrictedScreen> createState() => _AccessRestrictedScreenState();
}

class _AccessRestrictedScreenState extends ConsumerState<AccessRestrictedScreen> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) {
      return;
    }
    setState(() => _isSigningOut = true);

    final l10n = AppLocalizations.of(context);
    final result = await ref.read(authRepositoryProvider).signOutAndClearLocalState();
    if (!mounted) {
      return;
    }

    ref.invalidate(authStateProvider);
    ref.invalidate(currentAuthStateProvider);
    ref.invalidate(profileCompletenessProvider);

    AppSnackbar.show(
      context: context,
      message: result.isFailure
          ? l10n.accountSignOutFailureMessage
          : l10n.shellAccessRestrictedTitle,
      variant: result.isFailure ? AppSnackbarVariant.error : AppSnackbarVariant.info,
    );

    context.go(AppRoutes.authPath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(currentAuthStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block_outlined, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  l10n.shellAccessRestrictedTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  authState.isDeactivated
                      ? l10n.shellAccessRestrictedDeactivatedSubtitle
                      : l10n.shellAccessRestrictedBannedSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                PrimaryButton.icon(
                  onPressed: _isSigningOut ? null : _signOut,
                  icon: _isSigningOut
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.logout),
                  label: l10n.commonSignOutAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppRouteErrorScreen extends StatelessWidget {
  final String attemptedPath;

  const AppRouteErrorScreen({super.key, required this.attemptedPath});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StandaloneStateScreen(
      icon: Icons.route_outlined,
      title: l10n.shellRouteNotFoundTitle,
      subtitle: attemptedPath,
    );
  }
}


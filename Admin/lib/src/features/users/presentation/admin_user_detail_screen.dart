import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/repositories/admin_user_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_user_management_providers.dart';

part 'admin_user_detail_sections.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminUserDetailProvider(widget.userId));
    final actionState = ref.watch(adminUserActionProvider);

    return detailAsync.when(
      data: (detail) {
        if (detail == null) {
          return const Center(child: Text('User not found.'));
        }

        return _AdminUserDetailContent(
          detail: detail,
          actionState: actionState,
          reasonController: _reasonController,
          onOpenDocumentPreview: _openDocumentPreview,
          onToggleBan: _toggleBan,
          onOpenPath: (path) => context.go(path),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36, color: AdminColors.error),
              const SizedBox(height: 12),
              const Text('Unable to load user details right now.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(adminUserDetailProvider(widget.userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBan({
    required AdminUserListItem profile,
  }) async {
    final reason = _reasonController.text.trim();
    final targetBanState = !profile.isBanned;
    if (targetBanState && reason.length < 10) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Enter at least 10 characters so the ban reason is properly recorded.')),
        );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(targetBanState ? 'Confirm ban' : 'Confirm unban'),
          content: Text(
            targetBanState
                ? 'Ban this account now? The user will lose access on the next app open and the ban reason will be recorded.'
                : 'Restore this account now? This removes the ban flag and clears the current ban reason.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(targetBanState ? 'Confirm ban' : 'Confirm unban'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    bool ok;
    try {
      ok = await ref.read(adminUserActionProvider.notifier).setBanStatus(
            userId: profile.id,
            isBanned: targetBanState,
            reason: reason.isEmpty ? null : reason,
          );
    } catch (_) {
      ok = false;
    }
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? (targetBanState ? 'User account banned successfully.' : 'User account unbanned successfully.')
                : 'Could not update this user account right now. Try again shortly.',
          ),
        ),
      );
    if (ok) {
      _reasonController.clear();
      ref.invalidate(adminUserDetailProvider(widget.userId));
      ref.invalidate(adminUsersProvider);
    }
  }

  Future<void> _openDocumentPreview(VerificationDocument document) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          document.label,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(document.path, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.black,
                        child: InteractiveViewer(
                          child: Image.network(
                            document.signedUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Unable to preview this document right now.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

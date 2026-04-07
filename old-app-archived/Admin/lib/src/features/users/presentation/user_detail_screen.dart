import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_access_repository.dart';
import '../../../core/theme/admin_design_tokens.dart';
import '../../../core/utils/ist_time.dart';
import '../../auth/providers/admin_auth_provider.dart';
import '../../../core/repositories/admin_user_management_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../shared/widgets/error_retry.dart';
import '../providers/user_detail_provider.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(userDetailProvider(widget.userId));
    final actionState = ref.watch(userActionProvider);
    final role = ref.watch(currentAdminRoleProvider);
    final canMutateUser = adminHasAccess(role, {
      AdminRole.superAdmin,
      AdminRole.opsAdmin,
    });

    return Scaffold(
      appBar: AppBar(title: const Text('User details')),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('User not found.'));
          }

          final profile = detail.profile;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AdminDesignTokens.pagePadding,
              AdminDesignTokens.cardPadding,
              AdminDesignTokens.pagePadding,
              AdminDesignTokens.pagePadding,
            ),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AdminColors.brandTealLightMuted,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 32,
                          color: AdminColors.primary,
                        ),
                      ),
                      const SizedBox(width: AdminDesignTokens.gapSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.fullName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AdminDesignTokens.gapXs),
                            Wrap(
                              spacing: AdminDesignTokens.gapSm,
                              children: [
                                _StatusPill(
                                  text: profile.role.toUpperCase(),
                                  color: _roleColor(profile.role),
                                ),
                                _StatusPill(
                                  text: profile.verificationStatus.toUpperCase(),
                                  color: AdminColors.brandOrange,
                                ),
                                if (profile.isBanned)
                                  _StatusPill(
                                    text: 'BANNED',
                                    color: AdminColors.error,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Role-specific information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      ...detail.roleMetadata.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 140,
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AdminColors.textSecondary,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value.isEmpty ? '-' : entry.value,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verification documents',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      ...detail.documents.map(
                        (d) => _DocumentTile(document: d),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent activity',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      if (detail.recentItems.isEmpty)
                        const Text('No recent activity found.')
                      else
                        ...detail.recentItems.map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.title),
                            subtitle: Text(item.status),
                            trailing: Text(
                              item.createdAt == null
                                  ? '-'
                                  : _timeAgo(item.createdAt!),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              if (canMutateUser)
                Card(
                  color: profile.isBanned ? AdminColors.successTint : AdminColors.errorTint,
                  child: Padding(
                    padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.isBanned ? 'Unban account' : 'Ban account',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: profile.isBanned
                                    ? Colors.green.shade700
                                    : AdminColors.error,
                              ),
                        ),
                        const SizedBox(height: AdminDesignTokens.sectionGap),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: profile.isBanned
                                  ? Colors.green.shade700
                                  : AdminColors.error,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: actionState.isLoading
                                ? null
                                : () => _toggleBan(profile),
                            child: actionState.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    profile.isBanned
                                        ? 'Unban account'
                                        : 'Ban account',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                    child: const Text(
                      'Read-only mode: Support agents can review the user profile and documents only.',
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorRetry(
          title: 'Unable to load user details',
          subtitle: 'Please check your connection and try again.',
          onRetry: () => ref.invalidate(userDetailProvider(widget.userId)),
        ),
      ),
    );
  }

  Future<void> _toggleBan(AdminUserListItem profile) async {
    final reason = _reasonController.text.trim();
    final banTarget = !profile.isBanned;

    if (banTarget && reason.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 10 characters for the ban reason.'),
        ),
      );
      return;
    }

    final ok = await ref
        .read(userActionProvider.notifier)
        .setBanStatus(
          userId: profile.id,
          banned: banTarget,
          reason: reason.isEmpty ? null : reason,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (banTarget
                    ? 'User account banned successfully.'
                    : 'User account unbanned successfully.')
              : 'Could not update user account status. Please try again.',
        ),
      ),
    );
    if (ok) {
      _reasonController.clear();
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = IstTime.age(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _DocumentTile extends StatelessWidget {
  final VerificationDocument document;

  const _DocumentTile({required this.document});

  @override
  Widget build(BuildContext context) {
    final hasUrl = document.url.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(document.label),
        subtitle: Text(
          hasUrl ? 'Tap to view the uploaded document' : 'No document uploaded',
        ),
        trailing: hasUrl ? const Icon(Icons.open_in_new) : null,
        onTap: hasUrl ? () => _openImage(context, document.url) : null,
      ),
    );
  }

  void _openImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: 700,
          height: 560,
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('Unable to open document preview.'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'supplier':
      return AdminColors.brandTeal;
    case 'trucker':
      return AdminColors.brandOrange;
    case 'admin':
      return AdminColors.primary;
    default:
      return AdminColors.textSecondary;
  }
}

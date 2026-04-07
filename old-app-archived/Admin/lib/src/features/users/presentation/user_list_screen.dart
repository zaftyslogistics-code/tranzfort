import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/admin_user_management_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../shared/widgets/admin_brand_header.dart';
import '../../../core/theme/admin_design_tokens.dart';
import '../../../shared/widgets/admin_navigation_drawer.dart';
import '../../../shared/widgets/error_retry.dart';
import '../providers/user_list_provider.dart';

class UserListScreen extends ConsumerStatefulWidget {
  const UserListScreen({super.key});

  @override
  ConsumerState<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends ConsumerState<UserListScreen> {
  final _searchController = TextEditingController();
  UserFilter _filter = UserFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = UserListQuery(
      filter: _filter,
      search: _searchController.text,
    );
    final usersAsync = ref.watch(userListProvider(query));

    return Scaffold(
      drawer: const AdminNavigationDrawer(currentRoute: '/users'),
      appBar: AppBar(title: const Text('User management')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AdminDesignTokens.pagePadding,
          AdminDesignTokens.cardPadding,
          AdminDesignTokens.pagePadding,
          AdminDesignTokens.pagePadding,
        ),
        children: [
          const AdminBrandHeader(
            title: 'User management',
            subtitle:
                'Search, review, and manage user access with ban and unban actions',
            icon: Icons.manage_accounts_outlined,
          ),
          const SizedBox(height: AdminDesignTokens.sectionGap),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, mobile, or email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search',
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AdminDesignTokens.gapSm),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'All users',
                selected: _filter == UserFilter.all,
                onTap: () => setState(() => _filter = UserFilter.all),
              ),
              _FilterChip(
                label: 'Suppliers only',
                selected: _filter == UserFilter.supplier,
                onTap: () => setState(() => _filter = UserFilter.supplier),
              ),
              _FilterChip(
                label: 'Truckers only',
                selected: _filter == UserFilter.trucker,
                onTap: () => setState(() => _filter = UserFilter.trucker),
              ),
              _FilterChip(
                label: 'Banned users',
                selected: _filter == UserFilter.banned,
                onTap: () => setState(() => _filter = UserFilter.banned),
              ),
            ],
          ),
          const SizedBox(height: 12),
          usersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return _EmptyFilterState(
                  onClear: () => setState(() {
                    _filter = UserFilter.all;
                    _searchController.clear();
                  }),
                );
              }

              return Column(
                children: users.asMap().entries.map((entry) {
                  final index = entry.key;
                  final u = entry.value;
                  final bgColor = index.isEven ? null : AdminColors.scaffoldBg;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AdminDesignTokens.gapSm),
                    child: Card(
                      color: bgColor,
                      child: ListTile(
                            title: Text(u.fullName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('${u.role} • ${u.mobile}'),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: AdminDesignTokens.gapSm,
                                  children: [
                                    _MetaChip(
                                      label: u.isBanned ? 'Banned' : 'Active',
                                      color: u.isBanned
                                          ? AdminColors.error
                                          : AdminColors.primary,
                                    ),
                                    _MetaChip(
                                      label: u.role.toUpperCase(),
                                      color: _roleColor(u.role),
                                    ),
                                    _MetaChip(
                                      label: u.verificationStatus.toUpperCase(),
                                      color: AdminColors.brandOrange,
                                    ),
                                    _MetaChip(
                                      label: 'Loads/Trips: ${u.loadsCount}',
                                      color: AdminColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/user/${u.id}'),
                          ),
                        ),
                      );
                    }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => ErrorRetry(
              title: 'Unable to load user list',
              subtitle: 'Please check your connection and try again.',
              onRetry: () => ref.invalidate(userListProvider(query)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  final VoidCallback onClear;

  const _EmptyFilterState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: AdminColors.textTertiary),
            const SizedBox(height: AdminDesignTokens.gapSm),
            const Text('No users match the current search or filters.'),
            const SizedBox(height: AdminDesignTokens.gapSm),
            OutlinedButton(
              onPressed: onClear,
              child: const Text('Clear filters and search'),
            ),
          ],
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

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

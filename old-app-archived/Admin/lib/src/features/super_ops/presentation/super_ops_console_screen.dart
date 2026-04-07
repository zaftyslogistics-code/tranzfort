import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/admin_access_repository.dart';
import '../../../core/repositories/splitted/super_ops_models.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../core/theme/admin_design_tokens.dart';
import '../../../core/utils/ist_time.dart';
import '../../../shared/widgets/admin_brand_header.dart';
import '../../../shared/widgets/admin_navigation_drawer.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../auth/providers/admin_auth_provider.dart';
import '../providers/super_ops_queue_provider.dart';

class SuperOpsConsoleScreen extends ConsumerStatefulWidget {
  const SuperOpsConsoleScreen({super.key});

  @override
  ConsumerState<SuperOpsConsoleScreen> createState() =>
      _SuperOpsConsoleScreenState();
}

class _SuperOpsConsoleScreenState extends ConsumerState<SuperOpsConsoleScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countsAsync = ref.watch(superOpsQueueCountsProvider);
    final role = ref.watch(currentAdminRoleProvider);
    final isSuperAdmin = adminHasAccess(role, {AdminRole.superAdmin});

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        drawer: const AdminNavigationDrawer(currentRoute: '/super-ops'),
        appBar: AppBar(
          title: const Text('Super Ops Console'),
          actions: [
            if (isSuperAdmin)
              IconButton(
                onPressed: () => context.push('/super-ops/post-on-behalf'),
                icon: const Icon(Icons.post_add_outlined),
                tooltip: 'Post On Behalf',
              ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(
                child: countsAsync.maybeWhen(
                  data: (c) => _tabLabel('Requests', c.requests),
                  orElse: () => const Text('Requests'),
                ),
              ),
              Tab(
                child: countsAsync.maybeWhen(
                  data: (c) => _tabLabel('Dispatch', c.dispatch),
                  orElse: () => const Text('Dispatch'),
                ),
              ),
              Tab(
                child: countsAsync.maybeWhen(
                  data: (c) => _tabLabel('POD Review', c.podReview),
                  orElse: () => const Text('POD Review'),
                ),
              ),
              Tab(
                child: countsAsync.maybeWhen(
                  data: (c) => _tabLabel('Completed', c.completed),
                  orElse: () => const Text('Completed'),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                children: [
                  const AdminBrandHeader(
                    title: 'Super Load Operations',
                    subtitle:
                        'Control request intake, dispatch force-assignment, POD review, and completion',
                    icon: Icons.star_outline,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Search by route, supplier, material, or load ID',
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
                      helperText: 'Type to filter the Super Ops queue',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _SuperOpsTabList(
                    tab: SuperOpsTab.requests,
                    search: _searchController.text,
                  ),
                  _SuperOpsTabList(
                    tab: SuperOpsTab.dispatch,
                    search: _searchController.text,
                  ),
                  _SuperOpsTabList(
                    tab: SuperOpsTab.podReview,
                    search: _searchController.text,
                  ),
                  _SuperOpsTabList(
                    tab: SuperOpsTab.completed,
                    search: _searchController.text,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuperOpsTabList extends ConsumerWidget {
  final SuperOpsTab tab;
  final String search;

  const _SuperOpsTabList({required this.tab, required this.search});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = SuperOpsQueueQuery(tab: tab, search: search);
    final queueAsync = ref.watch(superOpsQueueProvider(query));

    return queueAsync.when(
      data: (loads) {
        if (loads.isEmpty) {
          return const Center(
            child: Text('No Super Ops loads match this queue or the current search.'),
          );
        }

        return ListView.separated(
          addAutomaticKeepAlives: false,
          padding: const EdgeInsets.fromLTRB(
            AdminDesignTokens.pagePadding,
            AdminDesignTokens.gapSm,
            AdminDesignTokens.pagePadding,
            AdminDesignTokens.pagePadding,
          ),
          itemCount: loads.length,
          separatorBuilder: (context, index) => const SizedBox(height: AdminDesignTokens.gapSm),
          itemBuilder: (context, index) {
            final item = loads[index];
            final remaining = item.trucksNeeded - item.trucksBooked;
            final statusColor = _statusColor(tab);

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: statusColor, width: 1.8),
              ),
              child: ListTile(
                title: Text(item.routeLabel),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${item.material} • ${item.weightTonnes.toStringAsFixed(1)}T',
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Pill(
                          text: '₹${item.price.toStringAsFixed(0)}',
                          color: AdminColors.primary,
                        ),
                        _Pill(
                          text: 'Needed: ${item.trucksNeeded}',
                          color: AdminColors.brandOrange,
                        ),
                        _Pill(
                          text: 'Booked: ${item.trucksBooked}',
                          color: AdminColors.textSecondary,
                        ),
                        _Pill(
                          text: 'Remaining: ${remaining < 0 ? 0 : remaining}',
                          color: remaining <= 0 ? Colors.green : AdminColors.error,
                          backgroundColor: remaining <= 0 ? Colors.green.withValues(alpha: 0.12) : null,
                        ),
                        _Pill(
                          text: 'Supplier: ${item.supplierName}',
                          color: AdminColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pickup: ${_formatDate(item.pickupDate)} • Age: ${_age(item.createdAt)} • Super: ${item.superStatus}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right, semanticLabel: 'Open load details'),
                onTap: () => context.push('/super-ops/load/${item.id}'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorRetry(
        title: 'Unable to load Super Ops queue',
        subtitle: 'Please check your connection and try again.',
        onRetry: () => ref.invalidate(superOpsQueueProvider(query)),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color? backgroundColor;

  const _Pill({required this.text, required this.color, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
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

String _formatDate(DateTime? dateTime) {
  if (dateTime == null) return '-';
  return IstTime.formatDate(dateTime, 'dd MMM yyyy');
}

String _age(DateTime? createdAt) {
  if (createdAt == null) return '-';
  final diff = IstTime.age(createdAt);
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m';
  return 'just now';
}

Widget _tabLabel(String title, int count) {
  return RichText(
    text: TextSpan(
      style: const TextStyle(color: Colors.white),
      children: [
        TextSpan(text: '$title '),
        TextSpan(
          text: '($count)',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

Color _statusColor(SuperOpsTab tab) {
  switch (tab) {
    case SuperOpsTab.requests:
      return AdminColors.primary;
    case SuperOpsTab.dispatch:
      return AdminColors.brandOrange;
    case SuperOpsTab.podReview:
      return AdminColors.brandTeal;
    case SuperOpsTab.completed:
      return Colors.green;
  }
}

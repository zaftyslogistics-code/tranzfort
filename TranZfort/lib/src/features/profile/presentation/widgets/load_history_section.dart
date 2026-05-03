import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/public_profile_models.dart';
import '../../data/public_profile_repository.dart';

/// Load history section with 3+5 pagination pattern.
class LoadHistorySection extends ConsumerStatefulWidget {
  final String userId;
  final String? statusFilter;
  final String title;

  const LoadHistorySection({
    super.key,
    required this.userId,
    required this.title,
    this.statusFilter,
  });

  @override
  ConsumerState<LoadHistorySection> createState() => _LoadHistorySectionState();
}

class _LoadHistorySectionState extends ConsumerState<LoadHistorySection> {
  final List<PublicLoadPreview> _loads = [];
  int _offset = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  static const int _initialLimit = 3;
  static const int _batchSize = 5;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void didUpdateWidget(LoadHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.statusFilter != widget.statusFilter) {
      _loads.clear();
      _offset = 0;
      _hasMore = true;
      _error = null;
      _loadInitial();
    }
  }

  Future<void> _loadInitial() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(publicProfileRepositoryProvider).getUserPublicLoads(
      userId: widget.userId,
      limit: _initialLimit,
      offset: 0,
      statusFilter: widget.statusFilter,
    );

    result.when(
      success: (loads) {
        setState(() {
          _loads.addAll(loads);
          _offset = loads.length;
          _hasMore = loads.length == _initialLimit;
          _isLoading = false;
        });
      },
      failure: (failure) {
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    final result = await ref.read(publicProfileRepositoryProvider).getUserPublicLoads(
      userId: widget.userId,
      limit: _batchSize,
      offset: _offset,
      statusFilter: widget.statusFilter,
    );

    result.when(
      success: (loads) {
        setState(() {
          _loads.addAll(loads);
          _offset += loads.length;
          _hasMore = loads.length == _batchSize;
          _isLoading = false;
        });
      },
      failure: (failure) {
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_error != null)
          _buildErrorState(context)
        else if (_loads.isEmpty && !_isLoading)
          _buildEmptyState(context)
        else
          _buildLoadList(context),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.loadHistoryFailedToLoad,
            style: TextStyle(color: colorScheme.error),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadInitial,
            child: Text(l10n.commonRetryAction),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.loadHistoryNoLoads,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadList(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _loads.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final load = _loads[index];
            return _LoadItemTile(load: load);
          },
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else if (_hasMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.expand_more),
              label: Text(l10n.commonLoadMoreAction),
            ),
          ),
      ],
    );
  }
}

/// Individual load item tile.
class _LoadItemTile extends StatelessWidget {
  final PublicLoadPreview load;

  const _LoadItemTile({required this.load});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Expanded(
            child: Text(
              load.routeLabel,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _buildStatusChip(context),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${load.material} • ${load.weightTonnes}T',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${load.priceAmount.toStringAsFixed(0)} ${load.priceType}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
      onTap: () {
        // Navigate to load detail (implementation depends on routing)
      },
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final (color, label) = switch (load.status) {
      'active' => (Colors.green, l10n.loadHistoryStatusValue('active')),
      'completed' => (colorScheme.primary, l10n.loadHistoryStatusValue('completed')),
      'assigned_partial' => (Colors.orange, l10n.loadHistoryStatusValue('assigned_partial')),
      'assigned_full' => (Colors.blue, l10n.loadHistoryStatusValue('assigned_full')),
      _ => (colorScheme.onSurfaceVariant, load.status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

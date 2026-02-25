import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/rich_load_card.dart';

class FindLoadsScreen extends ConsumerStatefulWidget {
  const FindLoadsScreen({super.key});

  @override
  ConsumerState<FindLoadsScreen> createState() => _FindLoadsScreenState();
}

class _FindLoadsScreenState extends ConsumerState<FindLoadsScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();

  String _material = '';
  String _truckType = '';
  String _sortBy = 'newest';

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 220) {
      ref.read(findLoadsProvider.notifier).loadMore();
    }
  }

  Future<void> _search() {
    return ref
        .read(findLoadsProvider.notifier)
        .search(
          LoadFilters(
            originCity: _originController.text.trim(),
            destinationCity: _destinationController.text.trim(),
            material: _material,
            truckType: _truckType,
            sortBy: _sortBy,
          ),
        );
  }

  Future<void> _handleBookLoad(Map<String, dynamic> load) async {
    final trucks = await ref.read(verifiedTrucksProvider.future);

    if (!mounted) {
      return;
    }

    if (trucks.isEmpty) {
      final shouldAddTruck = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Verified truck required'),
            content: const Text(
              'You need a verified truck to book loads. Add a truck now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Add Truck'),
              ),
            ],
          );
        },
      );

      if (shouldAddTruck == true && mounted) {
        context.push('/my-fleet/add');
      }
      return;
    }

    String? selectedTruckId;
    if (trucks.length == 1) {
      selectedTruckId = await _confirmTruckSelection(load: load, truck: trucks.first);
    } else {
      selectedTruckId = await _selectTruckForBooking(load, trucks);
    }

    if (selectedTruckId == null || !mounted) {
      return;
    }

    final success = await ref
        .read(loadActionProvider.notifier)
        .bookLoadWithTruck(parentLoadId: load['id'].toString(), truckId: selectedTruckId);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Load booked! Waiting for supplier approval.'
              : 'Booking failed. Please try again.',
        ),
      ),
    );
  }

  Future<String?> _confirmTruckSelection({
    required Map<String, dynamic> load,
    required Map<String, dynamic> truck,
  }) async {
    final material = (load['material'] ?? 'this').toString();
    final origin = (load['origin_city'] ?? '').toString();
    final destination = (load['dest_city'] ?? '').toString();
    final truckNumber = (truck['truck_number'] ?? 'Selected Truck').toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Booking'),
          content: Text(
            'Book $material load from $origin to $destination with $truckNumber?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return confirm == true ? truck['id']?.toString() : null;
  }

  Future<String?> _selectTruckForBooking(
    Map<String, dynamic> load,
    List<Map<String, dynamic>> trucks,
  ) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final requiredType = (load['required_truck_type'] ?? '').toString();
        final requiredTyres =
            ((load['required_tyres'] as List?) ?? const []).map((e) => '$e').toSet();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a truck for this load',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...trucks.map((truck) {
                  final truckType = (truck['body_type'] ?? '').toString();
                  final truckTyres = (truck['tyres'] ?? '').toString();
                  final typeMatches = requiredType.isEmpty || requiredType == truckType;
                  final tyreMatches =
                      requiredTyres.isEmpty || requiredTyres.contains(truckTyres);
                  final isMatch = typeMatches && tyreMatches;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text((truck['truck_number'] ?? 'Truck').toString()),
                    subtitle: Text(
                      '${truckType.isEmpty ? 'Unknown type' : truckType} · ${truckTyres.isEmpty ? '-' : truckTyres} tyres',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isMatch
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isMatch ? 'MATCH' : 'MISMATCH',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop(truck['id']?.toString());
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(findLoadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Loads'),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bot-chat'),
        backgroundColor: AppColors.secondaryAmber,
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _originController,
                        decoration: const InputDecoration(
                          labelText: 'From',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _destinationController,
                        decoration: const InputDecoration(
                          labelText: 'To',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _material,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Material',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Any')),
                          DropdownMenuItem(value: 'Coal', child: Text('Coal')),
                          DropdownMenuItem(
                            value: 'Steel',
                            child: Text('Steel'),
                          ),
                          DropdownMenuItem(
                            value: 'Cement',
                            child: Text('Cement'),
                          ),
                          DropdownMenuItem(value: 'Sand', child: Text('Sand')),
                        ],
                        onChanged: (value) =>
                            setState(() => _material = value ?? ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _truckType,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Truck',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Any')),
                          DropdownMenuItem(value: 'open', child: Text('Open')),
                          DropdownMenuItem(
                            value: 'container',
                            child: Text('Container'),
                          ),
                          DropdownMenuItem(
                            value: 'trailer',
                            child: Text('Trailer'),
                          ),
                          DropdownMenuItem(
                            value: 'tanker',
                            child: Text('Tanker'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _truckType = value ?? ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _sortBy,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Sort',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text('Newest'),
                          ),
                          DropdownMenuItem(
                            value: 'price_high',
                            child: Text('Price High-Low'),
                          ),
                          DropdownMenuItem(
                            value: 'price_low',
                            child: Text('Price Low-High'),
                          ),
                          DropdownMenuItem(
                            value: 'pickup_date',
                            child: Text('Pickup Date'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _sortBy = value ?? 'newest'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _search,
                        child: const Text('Search'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _originController.clear();
                          _destinationController.clear();
                          setState(() {
                            _material = '';
                            _truckType = '';
                            _sortBy = 'newest';
                          });
                          ref.read(findLoadsProvider.notifier).resetFilters();
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isSearching
                ? const Center(child: CircularProgressIndicator())
                : state.results.isEmpty
                ? const EmptyStateView(
                    icon: Icons.local_shipping_outlined,
                    title: 'No loads found',
                    subtitle: 'Try changing your filters or check back later.',
                  )
                : RefreshIndicator(
                    onRefresh: _search,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemBuilder: (context, index) {
                        if (index == state.results.length) {
                          return state.isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final load = state.results[index];
                        return RichLoadCard(
                          load: load,
                          onTap: () =>
                              context.push('/load-detail/${load['id']}'),
                          onChat: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chat flow in Sprint 7'),
                              ),
                            );
                          },
                          onBook: () async {
                            await _handleBookLoad(load);
                          },
                        );
                      },
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 12),
                      itemCount: state.results.length + 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

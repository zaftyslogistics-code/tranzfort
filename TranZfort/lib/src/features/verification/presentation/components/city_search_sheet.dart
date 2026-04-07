import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

// Uses existing TruckerCitySuggestion and service pattern
class CitySearchSheet extends ConsumerStatefulWidget {
  final void Function(TruckerCitySuggestion) onCitySelected;

  const CitySearchSheet({
    super.key,
    required this.onCitySelected,
  });

  @override
  ConsumerState<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends ConsumerState<CitySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<TruckerCitySuggestion> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Auto-focus and show keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);

    final service = ref.read(citySearchServiceProvider);
    final results = await service.searchCities(query);

    if (mounted) {
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Title
          Text(
            l10n.verificationWizardSearchCityTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Search field
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.verificationWizardSearchCityHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _suggestions = []);
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Current location option
          ListTile(
            leading: const Icon(Icons.my_location, color: AppColors.primary),
            title: Text(l10n.verificationWizardUseCurrentLocation),
            onTap: () {
              Navigator.pop(context);
              // Return null to signal using GPS
              // Caller handles GPS capture
            },
          ),
          const Divider(),
          
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _suggestions.isEmpty && _searchController.text.length >= 2
                    ? _EmptyResults(query: _searchController.text)
                    : _SuggestionsList(
                        suggestions: _suggestions,
                        onSelected: widget.onCitySelected,
                      ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;

  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context).verificationWizardNoCitiesFound(query),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context).verificationWizardTryDifferentSearch,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  final List<TruckerCitySuggestion> suggestions;
  final void Function(TruckerCitySuggestion) onSelected;

  const _SuggestionsList({
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (_, index) {
        final city = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.location_city_outlined),
          title: Text(city.city),
          subtitle: Text(city.state),
          trailing: city.population != null
              ? Text(
                  _formatPopulation(city.population!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                )
              : null,
          onTap: () => onSelected(city),
        );
      },
    );
  }

  String _formatPopulation(int pop) {
    if (pop >= 1000000) {
      return '${(pop / 1000000).toStringAsFixed(1)}M';
    } else if (pop >= 1000) {
      return '${(pop / 1000).toStringAsFixed(0)}K';
    }
    return pop.toString();
  }
}

// Simple city search service using existing data
final citySearchServiceProvider = Provider<CitySearchService>((ref) {
  return AssetCitySearchService();
});

abstract class CitySearchService {
  Future<List<TruckerCitySuggestion>> searchCities(String query);
}

class TruckerCitySuggestion {
  final String city;
  final String state;
  final double? lat;
  final double? lng;
  final int? population;

  const TruckerCitySuggestion({
    required this.city,
    required this.state,
    this.lat,
    this.lng,
    this.population,
  });
}

class AssetCitySearchService implements CitySearchService {
  List<Map<String, dynamic>>? _cachedCities;

  @override
  Future<List<TruckerCitySuggestion>> searchCities(String query) async {
    final cities = await _loadCities();
    final normalizedQuery = query.toLowerCase().trim();

    // Score and filter cities
    final scored = cities.map((city) {
      final name = (city['name'] ?? city['city'] ?? '').toString().toLowerCase();
      final state = (city['state'] ?? '').toString().toLowerCase();
      
      int score = 0;
      // Exact match gets highest score
      if (name == normalizedQuery) score += 100;
      // Starts with query gets high score
      else if (name.startsWith(normalizedQuery)) score += 50;
      // Contains query gets medium score
      else if (name.contains(normalizedQuery)) score += 25;
      // State match gets bonus
      if (state.contains(normalizedQuery)) score += 10;
      
      return _ScoredCity(city, score);
    }).where((sc) => sc.score > 0).toList();

    // Sort by score (descending) then population
    scored.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      
      final popA = a.city['population'] as int? ?? 0;
      final popB = b.city['population'] as int? ?? 0;
      return popB.compareTo(popA);
    });

    return scored.take(15).map((sc) => _toSuggestion(sc.city)).toList();
  }

  Future<List<Map<String, dynamic>>> _loadCities() async {
    if (_cachedCities != null) return _cachedCities!;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/indian_cities.json',
      );
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        _cachedCities = decoded.whereType<Map<String, dynamic>>().toList();
      } else {
        _cachedCities = [];
      }
    } catch (e) {
      _cachedCities = [];
    }

    return _cachedCities!;
  }

  TruckerCitySuggestion _toSuggestion(Map<String, dynamic> city) {
    return TruckerCitySuggestion(
      city: (city['name'] ?? city['city'] ?? '').toString(),
      state: (city['state'] ?? '').toString(),
      lat: _readDouble(city['lat']),
      lng: _readDouble(city['lng']),
      population: city['population'] as int?,
    );
  }

  double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class _ScoredCity {
  final Map<String, dynamic> city;
  final int score;

  _ScoredCity(this.city, this.score);
}

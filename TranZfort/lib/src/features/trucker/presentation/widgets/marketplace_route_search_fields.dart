import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/form_inputs.dart';
import '../../data/trucker_city_search_service.dart';
import 'city_suggestion_list.dart';

class MarketplaceRouteSearchFields extends ConsumerStatefulWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;

  const MarketplaceRouteSearchFields({
    super.key,
    required this.originController,
    required this.destinationController,
  });

  @override
  ConsumerState<MarketplaceRouteSearchFields> createState() => _MarketplaceRouteSearchFieldsState();
}

class _MarketplaceRouteSearchFieldsState extends ConsumerState<MarketplaceRouteSearchFields> {
  List<TruckerCitySuggestion> _originSuggestions = const <TruckerCitySuggestion>[];
  List<TruckerCitySuggestion> _destinationSuggestions = const <TruckerCitySuggestion>[];

  Future<void> _searchOrigin(String value) async {
    if (value.trim().length < 2) {
      setState(() => _originSuggestions = const <TruckerCitySuggestion>[]);
      return;
    }

    final suggestions = await ref.read(truckerCitySearchServiceProvider).searchCities(value);
    if (!mounted) {
      return;
    }
    setState(() => _originSuggestions = suggestions);
  }

  Future<void> _searchDestination(String value) async {
    if (value.trim().length < 2) {
      setState(() => _destinationSuggestions = const <TruckerCitySuggestion>[]);
      return;
    }

    final suggestions = await ref.read(truckerCitySearchServiceProvider).searchCities(value);
    if (!mounted) {
      return;
    }
    setState(() => _destinationSuggestions = suggestions);
  }

  void _clearOriginSuggestions() {
    setState(() => _originSuggestions = const <TruckerCitySuggestion>[]);
  }

  void _clearDestinationSuggestions() {
    setState(() => _destinationSuggestions = const <TruckerCitySuggestion>[]);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchField(
                controller: widget.originController,
                hintText: l10n.truckerFindLoadsOriginHint,
                onDarkSurface: true,
                onChanged: _searchOrigin,
                onClear: () {
                  widget.originController.clear();
                  _searchOrigin('');
                  _clearOriginSuggestions();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppSearchField(
                controller: widget.destinationController,
                hintText: l10n.truckerFindLoadsDestinationHint,
                onDarkSurface: true,
                onChanged: _searchDestination,
                onClear: () {
                  widget.destinationController.clear();
                  _searchDestination('');
                  _clearDestinationSuggestions();
                },
              ),
            ),
          ],
        ),
        if (_originSuggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          CitySuggestionList(
            suggestions: _originSuggestions,
            onSelected: (suggestion) {
              widget.originController.text = suggestion.city;
              _clearOriginSuggestions();
            },
          ),
        ],
        if (_destinationSuggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          CitySuggestionList(
            suggestions: _destinationSuggestions,
            onSelected: (suggestion) {
              widget.destinationController.text = suggestion.city;
              _clearDestinationSuggestions();
            },
          ),
        ],
      ],
    );
  }
}

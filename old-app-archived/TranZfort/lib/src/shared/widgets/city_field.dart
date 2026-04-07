import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/city_search_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/marketplace/providers/marketplace_providers.dart';

class CityField extends ConsumerStatefulWidget {
  final String label;
  final TextEditingController controller;
  final String searchKey;
  final ValueChanged<CitySuggestion> onSelected;

  const CityField({
    super.key,
    required this.label,
    required this.controller,
    required this.searchKey,
    required this.onSelected,
  });

  @override
  ConsumerState<CityField> createState() => _CityFieldState();
}

class _CityFieldState extends ConsumerState<CityField> {
  final FocusNode _focusNode = FocusNode();
  List<CitySuggestion> _suggestions = const [];
  bool _isLoading = false;
  int _searchRequestId = 0;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      if (!mounted) return;
      setState(() {
        _suggestions = const [];
        _isLoading = false;
      });
      return;
    }

    final requestId = ++_searchRequestId;
    setState(() {
      _isLoading = true;
    });

    final result = await ref.read(citySearchServiceProvider).search(trimmed);
    if (!mounted || requestId != _searchRequestId) {
      return;
    }

    setState(() {
      _suggestions = result.suggestions;
      _isLoading = false;
    });
  }

  Future<void> _select(CitySuggestion city) async {
    final resolved = await ref.read(citySearchServiceProvider).resolveSelection(city);
    if (!mounted) return;

    widget.controller.value = TextEditingValue(
      text: resolved.displayName,
      selection: TextSelection.collapsed(offset: resolved.displayName.length),
    );

    setState(() {
      _suggestions = const [];
      _isLoading = false;
    });

    widget.onSelected(resolved);
    _focusNode.unfocus();
  }

  Future<void> _submit(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final localSuggestions = _suggestions;
    CitySuggestion? selected;

    for (final item in localSuggestions) {
      if (item.city.toLowerCase() == trimmed.toLowerCase() ||
          item.displayName.toLowerCase() == trimmed.toLowerCase()) {
        selected = item;
        break;
      }
    }

    if (selected == null) {
      final result = await ref.read(citySearchServiceProvider).search(trimmed);
      if (result.suggestions.isNotEmpty) {
        selected = result.suggestions.first;
      }
    }

    await _select(selected ?? CitySuggestion(city: trimmed, state: 'Unknown'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Icon(Icons.location_city_outlined),
                  ),
          ),
          onChanged: _search,
          onTap: () {
            final currentValue = widget.controller.text.trim();
            if (currentValue.length >= 2 && _suggestions.isEmpty && !_isLoading) {
              _search(currentValue);
            }
          },
          onSubmitted: _submit,
        ),
        if (_suggestions.isNotEmpty && _focusNode.hasFocus) ...[
          const SizedBox(height: AppSpacing.xs),
          Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < _suggestions.length; index++) ...[
                      ListTile(
                        dense: true,
                        title: Text(_suggestions[index].city),
                        subtitle: Text(_suggestions[index].state),
                        onTap: () => _select(_suggestions[index]),
                      ),
                      if (index < _suggestions.length - 1)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

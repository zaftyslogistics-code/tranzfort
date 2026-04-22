import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/presentation/shell_components.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../data/supplier_profile_repository.dart';
import '../data/supplier_location_services.dart';
import '../providers/my_loads_provider.dart';
import '../providers/post_load_provider.dart';
import '../providers/supplier_providers.dart';

class PostLoadScreen extends ConsumerStatefulWidget {
  const PostLoadScreen({super.key});

  @override
  ConsumerState<PostLoadScreen> createState() => _PostLoadScreenState();
}

class _PostLoadScreenState extends ConsumerState<PostLoadScreen> {
  late final TextEditingController _originCityController;
  late final TextEditingController _originLocationController;
  late final TextEditingController _destinationCityController;
  late final TextEditingController _destinationLocationController;
  late final TextEditingController _weightController;
  late final TextEditingController _trucksController;
  late final TextEditingController _priceController;

  // Track initial values for unsaved changes detection
  late final String _initialOriginCity;
  late final String _initialOriginLocation;
  late final String _initialDestinationCity;
  late final String _initialDestinationLocation;
  late final String _initialWeight;
  late final String _initialTrucks;
  late final String _initialPrice;
  late final String _initialMaterial;
  late final String _initialCustomMaterial;
  late final String _initialBodyType;
  late final Set<String> _initialTyres;
  late final String _initialPriceType;
  late final double _initialAdvancePercentage;
  late final DateTime? _initialPickupDate;

  @override
  void initState() {
    super.initState();
    final state = ref.read(postLoadProvider);
    _originCityController = TextEditingController(text: state.originCity);
    _originLocationController = TextEditingController(text: state.originLocation);
    _destinationCityController = TextEditingController(text: state.destinationCity);
    _destinationLocationController = TextEditingController(text: state.destinationLocation);
    _weightController = TextEditingController(text: state.weightTonnes);
    _trucksController = TextEditingController(text: state.trucksNeeded);
    _priceController = TextEditingController(text: state.priceAmount);

    // Store initial values
    _initialOriginCity = state.originCity;
    _initialOriginLocation = state.originLocation;
    _initialDestinationCity = state.destinationCity;
    _initialDestinationLocation = state.destinationLocation;
    _initialWeight = state.weightTonnes;
    _initialTrucks = state.trucksNeeded;
    _initialPrice = state.priceAmount;
    _initialMaterial = state.material;
    _initialCustomMaterial = state.customMaterial;
    _initialBodyType = state.bodyType;
    _initialTyres = Set.from(state.selectedTyres);
    _initialPriceType = state.priceType;
    _initialAdvancePercentage = state.advancePercentage;
    _initialPickupDate = state.pickupDate;
  }

  bool _hasUnsavedChanges() {
    final state = ref.read(postLoadProvider);
    return _originCityController.text != _initialOriginCity ||
        _originLocationController.text != _initialOriginLocation ||
        _destinationCityController.text != _initialDestinationCity ||
        _destinationLocationController.text != _initialDestinationLocation ||
        _weightController.text != _initialWeight ||
        _trucksController.text != _initialTrucks ||
        _priceController.text != _initialPrice ||
        state.material != _initialMaterial ||
        state.customMaterial != _initialCustomMaterial ||
        state.bodyType != _initialBodyType ||
        state.selectedTyres.length != _initialTyres.length ||
        state.priceType != _initialPriceType ||
        state.advancePercentage != _initialAdvancePercentage ||
        state.pickupDate != _initialPickupDate;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges()) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved load details. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _originCityController.dispose();
    _originLocationController.dispose();
    _destinationCityController.dispose();
    _destinationLocationController.dispose();
    _weightController.dispose();
    _trucksController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(postLoadProvider);
    final supplierProfileAsync = ref.watch(supplierProfileProvider);
    final supplierProfile = supplierProfileAsync.valueOrNull;
    final profileFailure = supplierAsyncFailure(supplierProfileAsync);
    final postingGatingMessage = _postingGatingMessage(supplierProfileAsync, l10n);
    final postingBlocked = postingGatingMessage != null;
    final profileUnavailable = !supplierProfileAsync.isLoading && !supplierProfileAsync.hasError && supplierProfile == null;

    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (_hasUnsavedChanges()) {
          final navigator = Navigator.of(context);
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            // Navigate back - form state will be re-initialized on next visit
            navigator.pop();
          }
        }
      },
      child: DetailPageScaffold(
        title: l10n.supplierPostLoadHeroTitle,
        children: [
        HeroActionCard(
          title: l10n.supplierPostLoadHeroTitle == l10n.supplierPostLoadTitle
              ? l10n.supplierPostLoadHeroSubtitle
              : l10n.supplierPostLoadHeroTitle,
          subtitle: l10n.supplierPostLoadHeroSubtitle,
          child: Text(
            l10n.supplierPostLoadHeroHelper,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (postingBlocked)
          WarningBlock(
            title: l10n.supplierPostLoadPostingBlockedTitle,
            message: postingGatingMessage,
            action: profileUnavailable || profileFailure != null
                ? OutlineButton(
                    label: l10n.navSupport,
                    onPressed: () => context.push(AppRoutes.supportPath),
                  )
                : supplierProfile != null && !supplierProfile.canAccessWorkspace
                ? OutlineButton(
                    label: l10n.supplierPostLoadOpenVerificationAction,
                    onPressed: () => context.go(AppRoutes.supplierVerificationPath),
                  )
                : null,
          ),
        DetailSectionCard(
          title: l10n.supplierPostLoadRouteTimingTitle,
          children: [
            AppTextField(
              controller: _originCityController,
              label: l10n.supplierPostLoadOriginCityLabel,
              hintText: l10n.supplierPostLoadSearchCityHint,
              errorText: state.fieldErrors['origin_city'],
              onChanged: (value) => ref.read(postLoadProvider.notifier).searchOriginCity(value),
            ),
            if (state.isSearchingOrigin) const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
            _SuggestionList(
              suggestions: state.originSuggestions,
              onSelected: (suggestion) async {
                final resolved = await ref.read(postLoadProvider.notifier).selectOriginSuggestion(suggestion);
                _originCityController.text = resolved.city;
                if (_originLocationController.text.trim().isEmpty) {
                  _originLocationController.text = resolved.label;
                  ref.read(postLoadProvider.notifier).setOriginLocation(resolved.label);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _originLocationController,
              label: l10n.supplierPostLoadOriginExactLocationLabel,
              hintText: l10n.supplierPostLoadOriginExactLocationHint,
              errorText: state.fieldErrors['origin_label'],
              onChanged: ref.read(postLoadProvider.notifier).setOriginLocation,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _destinationCityController,
              label: l10n.supplierPostLoadDestinationCityLabel,
              hintText: l10n.supplierPostLoadSearchCityHint,
              errorText: state.fieldErrors['destination_city'],
              onChanged: (value) => ref.read(postLoadProvider.notifier).searchDestinationCity(value),
            ),
            if (state.isSearchingDestination) const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
            _SuggestionList(
              suggestions: state.destinationSuggestions,
              onSelected: (suggestion) async {
                final resolved = await ref.read(postLoadProvider.notifier).selectDestinationSuggestion(suggestion);
                _destinationCityController.text = resolved.city;
                if (_destinationLocationController.text.trim().isEmpty) {
                  _destinationLocationController.text = resolved.label;
                  ref.read(postLoadProvider.notifier).setDestinationLocation(resolved.label);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _destinationLocationController,
              label: l10n.supplierPostLoadDestinationExactLocationLabel,
              hintText: l10n.supplierPostLoadDestinationExactLocationHint,
              errorText: state.fieldErrors['destination_label'],
              onChanged: ref.read(postLoadProvider.notifier).setDestinationLocation,
            ),
            const SizedBox(height: AppSpacing.md),
            AppDatePicker(
              label: l10n.supplierPostLoadPickupDateLabel,
              value: state.pickupDate,
              firstDate: DateTime.now(),
              onChanged: ref.read(postLoadProvider.notifier).setPickupDate,
            ),
            if (state.fieldErrors['pickup_date'] case final pickupError?) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(pickupError, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
        if (state.isResolvingRoute)
          DetailSectionCard(
            title: l10n.supplierPostLoadRoutePreviewTitle,
            children: const [LoadingShimmer(height: 88, itemCount: 1)],
          )
        else if (state.routePreview != null)
          DetailSectionCard(
            title: l10n.supplierPostLoadRoutePreviewTitle,
            children: [
              Text(
                l10n.supplierPostLoadDistanceLabel(state.routePreview!.distanceKm.toStringAsFixed(1)),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.supplierPostLoadDriveTimeLabel(state.routePreview!.durationMinutes),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          )
        else if (state.selectedOrigin != null && state.selectedDestination != null)
          WarningBlock(
            title: l10n.supplierPostLoadRoutePreviewUnavailableTitle,
            message: l10n.supplierPostLoadRoutePreviewUnavailableMessage,
          ),
        DetailSectionCard(
          title: l10n.supplierPostLoadCargoDetailsTitle,
          children: [
            AppDropdown<String>(
              label: l10n.supplierPostLoadMaterialLabel,
              value: state.material,
              items: postLoadMaterials
                  .map((material) => DropdownMenuItem<String>(value: material, child: Text(material)))
                  .toList(growable: false),
              onChanged: ref.read(postLoadProvider.notifier).setMaterial,
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.material == 'Other') ...[
              AppTextField(
                label: 'Specify Material',
                hintText: 'e.g., Fruits, Iron Ore, Bricks',
                errorText: state.fieldErrors['custom_material'],
                onChanged: ref.read(postLoadProvider.notifier).setCustomMaterial,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              controller: _weightController,
              label: l10n.supplierPostLoadWeightLabel,
              hintText: l10n.supplierPostLoadWeightHint,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              errorText: state.fieldErrors['weight_tonnes'],
              onChanged: ref.read(postLoadProvider.notifier).setWeightTonnes,
            ),
          ],
        ),
        DetailSectionCard(
          title: l10n.supplierPostLoadVehicleRequirementsTitle,
          children: [
            AppDropdown<String>(
              label: l10n.supplierPostLoadTruckBodyTypeLabel,
              value: state.bodyType,
              items: postLoadBodyTypes
                  .map(
                    (bodyType) => DropdownMenuItem<String>(
                      value: bodyType,
                      child: Text(l10n.truckerFleetBodyTypeOption(bodyType)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: ref.read(postLoadProvider.notifier).setBodyType,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.supplierPostLoadTyreRequirementTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilterChip(
                  label: Text(l10n.supplierPostLoadAnyTyresLabel),
                  selected: state.selectedTyres.isEmpty,
                  onSelected: (_) => ref.read(postLoadProvider.notifier).toggleTyre(null),
                ),
                for (final tyre in postLoadTyreOptions)
                  FilterChip(
                    label: Text('$tyre'),
                    selected: state.selectedTyres.contains(tyre),
                    onSelected: (_) => ref.read(postLoadProvider.notifier).toggleTyre(tyre),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.supplierPostLoadTrucksNeededTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final shortcut in postLoadTruckShortcuts)
                  ActionChip(
                    label: Text('$shortcut'),
                    onPressed: () {
                      _trucksController.text = '$shortcut';
                      ref.read(postLoadProvider.notifier).setTrucksNeeded('$shortcut');
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _trucksController,
              label: l10n.supplierPostLoadTrucksNeededLabel,
              hintText: l10n.supplierPostLoadTrucksNeededHint,
              keyboardType: TextInputType.number,
              errorText: state.fieldErrors['trucks_needed'],
              onChanged: ref.read(postLoadProvider.notifier).setTrucksNeeded,
            ),
          ],
        ),
        DetailSectionCard(
          title: l10n.supplierPostLoadPricingScheduleTitle,
          children: [
            AppTextField(
              controller: _priceController,
              label: l10n.supplierPostLoadPriceAmountLabel,
              hintText: l10n.supplierPostLoadPriceAmountHint,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              errorText: state.fieldErrors['price_amount'],
              onChanged: ref.read(postLoadProvider.notifier).setPriceAmount,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.supplierPostLoadPriceTypeTitle, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'fixed', label: Text(l10n.supplierPostLoadPriceTypeFixed)),
                ButtonSegment<String>(value: 'per_ton', label: Text(l10n.supplierPostLoadPriceTypeNegotiable)),
              ],
              selected: <String>{state.priceType},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  ref.read(postLoadProvider.notifier).setPriceType(selection.first);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.supplierPostLoadAdvancePercentageLabel(state.advancePercentage.round()),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Slider(
              value: state.advancePercentage,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${state.advancePercentage.round()}%',
              onChanged: ref.read(postLoadProvider.notifier).setAdvancePercentage,
            ),
            Text(
              l10n.supplierPostLoadAdvanceBalanceLabel(
                _advanceAmount(state).toStringAsFixed(0),
                _balanceAmount(state).toStringAsFixed(0),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        DetailSectionCard(
          title: l10n.supplierPostLoadReviewSummaryTitle,
          children: [
            Text(
              l10n.supplierPostLoadRouteSummary(
                state.originCity.isEmpty ? l10n.supplierPostLoadOriginPending : state.originCity,
                state.destinationCity.isEmpty ? l10n.supplierPostLoadDestinationPending : state.destinationCity,
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.supplierPostLoadCargoSummary(
                state.material,
                state.weightTonnes.isEmpty ? '--' : state.weightTonnes,
                state.trucksNeeded,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.supplierPostLoadPriceSummary(
                state.priceAmount.isEmpty ? '--' : state.priceAmount,
                _localizedPriceTypeLabel(l10n, state.priceType),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.supplierPostLoadPickupSummary(
                _formatPickupDate(context, state.pickupDate),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        if (state.submissionFailure != null)
          WarningBlock(
            title: l10n.supplierPostLoadSubmissionFailedTitle,
            message: l10n.supplierPostLoadSubmissionFailureMessage,
          ),
        GradientButton(
          label: postingBlocked ? l10n.supplierPostLoadCompleteVerificationAction : l10n.supplierPostLoadSubmitAction,
          isLoading: state.isSubmitting,
          onPressed: state.isSubmitting || postingBlocked
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final result = await ref.read(postLoadProvider.notifier).submit(l10n);
                  if (!context.mounted) {
                    return;
                  }

                  if (result.isSuccess) {
                    ref.invalidate(myLoadsProvider);
                    ref.invalidate(supplierRecentLoadsProvider);
                    ref.invalidate(supplierDashboardProvider);
                    messenger.showSnackBar(
                      AppSnackbar.build(
                        context: context,
                        message: l10n.supplierPostLoadCreatedSuccess,
                        variant: AppSnackbarVariant.success,
                      ),
                    );
                    context.go(AppRoutes.myLoadsPath);
                    return;
                  }

                  messenger.showSnackBar(
                    AppSnackbar.build(
                      context: context,
                      message: l10n.supplierPostLoadSubmitFailureMessage,
                      variant: AppSnackbarVariant.error,
                    ),
                  );
                },
        ),
      ],
      ),
    );
  }

  double _advanceAmount(PostLoadState state) {
    final price = double.tryParse(state.priceAmount.trim()) ?? 0;
    final weight = double.tryParse(state.weightTonnes.trim()) ?? 0;
    final totalPrice = state.priceType == 'per_ton' ? price * weight : price;
    return totalPrice * (state.advancePercentage / 100);
  }

  double _balanceAmount(PostLoadState state) {
    final price = double.tryParse(state.priceAmount.trim()) ?? 0;
    final weight = double.tryParse(state.weightTonnes.trim()) ?? 0;
    final totalPrice = state.priceType == 'per_ton' ? price * weight : price;
    return totalPrice - _advanceAmount(state);
  }

  String? _postingGatingMessage(
    AsyncValue<SupplierProfile?> supplierProfileAsync,
    AppLocalizations l10n,
  ) {
    if (supplierProfileAsync.isLoading) {
      return l10n.supplierPostLoadVerificationCheckingMessage;
    }
    final failure = supplierAsyncFailure(supplierProfileAsync);
    if (failure != null) {
      return l10n.supplierPostLoadVerificationUnavailableMessage;
    }
    final supplierProfile = supplierProfileAsync.valueOrNull;
    if (supplierProfile == null) {
      return l10n.supplierPostLoadProfileUnavailableMessage;
    }
    if (!supplierProfile.canAccessWorkspace) {
      if (supplierProfile.isVerificationApproved && !supplierProfile.hasCompanyName) {
        return l10n.supplierCompleteSetupMessage;
      }
      return l10n.supplierPostLoadVerificationRequiredMessage;
    }
    return null;
  }

  String _localizedPriceTypeLabel(AppLocalizations l10n, String value) {
    return switch (value.trim().toLowerCase()) {
      'fixed' => l10n.supplierPostLoadPriceTypeFixed,
      'per_ton' => l10n.supplierPostLoadPriceTypeNegotiable,
      _ => value,
    };
  }

  String _formatPickupDate(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatMediumDate(value);
  }
}

class _SuggestionList extends StatelessWidget {
  final List<PlaceSuggestion> suggestions;
  final Future<void> Function(PlaceSuggestion suggestion) onSelected;

  const _SuggestionList({
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        children: [
          for (final suggestion in suggestions) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(suggestion.city),
              subtitle: Text(
                suggestion.state == null ? suggestion.label : l10n.supplierPostLoadSuggestionSubtitle(suggestion.label, suggestion.source),
              ),
              onTap: () => onSelected(suggestion),
            ),
            if (suggestion != suggestions.last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

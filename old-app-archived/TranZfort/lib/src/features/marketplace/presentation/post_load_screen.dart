import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/services/city_search_service.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/utils/coordinate_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/city_field.dart';
import '../../../shared/widgets/tts_focus_field.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../../shared/widgets/screen_scroll_container.dart';
import '../utils/load_pricing.dart';
import '../providers/marketplace_providers.dart';

class PostLoadScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialDraft;

  const PostLoadScreen({super.key, this.initialDraft});

  @override
  ConsumerState<PostLoadScreen> createState() => _PostLoadScreenState();
}

class _VerificationGateCard extends StatelessWidget {
  final bool isPending;
  final VoidCallback onCompleteVerification;

  const _VerificationGateCard({
    required this.isPending,
    required this.onCompleteVerification,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isPending ? AppColors.infoTint : AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isPending ? AppColors.info : AppColors.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPending
                ? l10n.verificationPendingReview
                : l10n.verificationRequired,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isPending
                ? l10n.verificationPendingMessage
                : l10n.verificationRequiredMessage,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (!isPending) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: 220,
              child: OutlineButton(
                label: l10n.completeVerification,
                onPressed: onCompleteVerification,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuperLoadReadinessCard extends StatelessWidget {
  final bool requiresVerification;
  final VoidCallback onOpenVerification;
  final VoidCallback onOpenPayoutProfile;

  const _SuperLoadReadinessCard({
    required this.requiresVerification,
    required this.onOpenVerification,
    required this.onOpenPayoutProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandOrangeLight,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: AppColors.brandOrangeDark.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_outlined,
            color: AppColors.brandOrangeDark,
            size: AppSpacing.iconMd,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.postLoadSuperLoadReadinessSubtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onOpenPayoutProfile,
            child: Text(l10n.settingsPayoutProfileTitle),
          ),
          if (requiresVerification)
            TextButton(
              onPressed: onOpenVerification,
              child: Text(l10n.completeVerification),
            ),
        ],
      ),
    );
  }
}

class _PostLoadScreenState extends ConsumerState<PostLoadScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _weightController = TextEditingController(text: '25');
  final _priceController = TextEditingController(text: '62500');
  final _customTrucksController = TextEditingController(text: '1');

  static const _materials = <String>[
    'Coal',
    'Steel',
    'Cement',
    'Iron Ore',
    'Sand',
    'Grain',
    'Fertilizer',
    'Timber',
    'Other',
  ];

  static const _truckTypes = <String?>[
    null,
    'open',
    'container',
    'trailer',
    'tanker',
    'refrigerated',
  ];

  static const _tyres = <int>[6, 10, 12, 14, 16, 18, 22];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyInitialDraft();
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _customTrucksController.dispose();
    super.dispose();
  }

  Future<void> _applyInitialDraft() async {
    final draft = widget.initialDraft;
    if (draft == null || draft.isEmpty) {
      return;
    }

    final notifier = ref.read(postLoadProvider.notifier);

    final originCity = (draft['origin_city'] ?? '').toString().trim();
    final originState = (draft['origin_state'] ?? '').toString().trim();
    final destCity = (draft['dest_city'] ?? '').toString().trim();
    final destState = (draft['dest_state'] ?? '').toString().trim();
    final material = (draft['material'] ?? '').toString().trim();
    final truckType = (draft['required_truck_type'] ?? '').toString().trim();
    final priceType = (draft['price_type'] ?? '').toString().trim();

    if (originCity.isNotEmpty) {
      _originController.text = [originCity, originState]
          .where((part) => part.isNotEmpty)
          .join(', ');
      await _resolveAndSetCity(
        city: originCity,
        state: originState,
        onResolved: notifier.setOriginSuggestion,
      );
    }

    if (destCity.isNotEmpty) {
      _destinationController.text = [destCity, destState]
          .where((part) => part.isNotEmpty)
          .join(', ');
      await _resolveAndSetCity(
        city: destCity,
        state: destState,
        onResolved: notifier.setDestinationSuggestion,
      );
    }

    if (material.isNotEmpty) {
      notifier.setMaterial(material);
    }

    final weight = CoordinateUtils.parseDouble(draft['weight_tonnes']);
    if (weight != null && weight > 0) {
      _weightController.text = weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1);
      notifier.setWeight(weight);
    }

    if (truckType.isNotEmpty) {
      notifier.setTruckType(truckType);
    }

    for (final tyre in _normalizeTyres(draft['required_tyres'])) {
      notifier.toggleTyre(tyre);
    }

    final price = CoordinateUtils.parseDouble(draft['price']);
    if (price != null && price > 0) {
      _priceController.text = price.toStringAsFixed(0);
      notifier.setPrice(price);
    }

    if (priceType.isNotEmpty) {
      notifier.setPriceType(priceType);
    }

    final advance = (draft['advance_percentage'] as num?)?.toInt();
    if (advance != null) {
      notifier.setAdvance(advance);
    }

    final trucksNeeded = (draft['trucks_needed'] as num?)?.toInt();
    if (trucksNeeded != null && trucksNeeded >= 1) {
      _customTrucksController.text = '$trucksNeeded';
      notifier.setTrucksNeeded(trucksNeeded);
    }

    final pickupDateRaw = (draft['pickup_date'] ?? '').toString();
    final pickupDate = DateTime.tryParse(pickupDateRaw);
    if (pickupDate != null) {
      notifier.setPickupDate(pickupDate);
    }
  }

  Future<void> _resolveAndSetCity({
    required String city,
    required String state,
    required void Function(CitySuggestion) onResolved,
  }) async {
    if (city.isEmpty) {
      return;
    }

    final service = ref.read(citySearchServiceProvider);
    final query = [city, state].where((part) => part.isNotEmpty).join(' ');
    final result = await service.search(query);

    CitySuggestion selected;
    try {
      selected = result.suggestions.firstWhere(
        (item) =>
            item.city.toLowerCase() == city.toLowerCase() &&
            (state.isEmpty || item.state.toLowerCase() == state.toLowerCase()),
      );
    } catch (_) {
      selected = result.suggestions.isNotEmpty
          ? result.suggestions.first
          : CitySuggestion(city: city, state: state);
    }

    final resolved = await service.resolveSelection(selected);
    onResolved(resolved);
  }

  List<int> _normalizeTyres(dynamic rawTyres) {
    if (rawTyres is! List) {
      return const [];
    }
    final values = rawTyres
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  String? _selectedMaterialValue(String material) {
    final trimmed = material.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return _materials.contains(trimmed) ? trimmed : null;
  }

  String? _selectedTruckTypeValue(String? truckType) {
    if (truckType == null) {
      return null;
    }
    return _truckTypes.contains(truckType) ? truckType : null;
  }

  String _priceInputLabel(AppLocalizations l10n, String priceType) {
    if (LoadPricing.isPerTon(priceType)) {
      return '${l10n.postLoadPriceTypeNegotiable} (₹)';
    }
    return l10n.postLoadPriceTotalLabel;
  }

  Widget _buildStepProgress() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = index <= ref.read(postLoadProvider).currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.neutralLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  String _stepLabel(int step, AppLocalizations l10n) {
    return switch (step) {
      0 => l10n.postLoadStepRouteTitle,
      1 => l10n.postLoadStepCargoTitle,
      2 => l10n.postLoadStepVehicleTitle,
      3 => l10n.postLoadStepPriceScaleTitle,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(postLoadProvider);
    final notifier = ref.read(postLoadProvider.notifier);
    final profile = ref.watch(userProfileProvider).value;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    final role = (profile?['user_role_type'] ?? '').toString();
    final verificationStatus = (profile?['verification_status'] ?? '')
        .toString()
        .toLowerCase();
    final isSupplier = role == 'supplier';
    final isVerified = verificationStatus == 'verified';
    final isPending = verificationStatus == 'pending';
    final showVerificationGate = isSupplier && !isVerified;
    final showTopChrome = !showVerificationGate && !isKeyboardOpen;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(l10n.postLoadTitle)),
      body: ScreenScrollContainer(
        scrollable: false,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPaddingH,
          AppSpacing.screenPaddingV,
          AppSpacing.screenPaddingH,
          0,
        ),
        child: Column(
          children: [
            TtsAnnounce(
              text: showVerificationGate
                  ? (isPending
                        ? l10n.verificationPendingMessage
                        : l10n.verificationRequiredMessage)
                  : switch (state.currentStep) {
                      0 => l10n.postLoadStepTtsRoute,
                      1 => l10n.postLoadStepTtsCargo,
                      2 => l10n.postLoadStepTtsSchedule,
                      3 => l10n.postLoadStepTtsPricing,
                      _ => l10n.createLoadQuickSteps,
                    },
            ),
            if (showTopChrome) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.createLoadQuickSteps,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.createLoadSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (isSupplier && showTopChrome) ...[
              _SuperLoadReadinessCard(
                requiresVerification: !isVerified,
                onOpenVerification: () => context.push('/verification/supplier'),
                onOpenPayoutProfile: () => context.push('/payout-profile'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (showVerificationGate) ...[
              _VerificationGateCard(
                isPending: isPending,
                onCompleteVerification: () =>
                    context.push('/verification/supplier'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Expanded(
              child: showVerificationGate
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        _buildStepProgress(),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.postLoadStepSummary(
                            state.currentStep + 1,
                            4,
                            _stepLabel(state.currentStep, l10n),
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Expanded(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
                            ),
                            child: Stepper(
                              margin: EdgeInsets.zero,
                              type: StepperType.horizontal,
                              elevation: 0,
                              currentStep: state.currentStep,
                        onStepContinue: () async {
                          if (state.currentStep == 0) {
                            await notifier.resolveOriginInput(
                              _originController.text,
                            );
                            await notifier.resolveDestinationInput(
                              _destinationController.text,
                            );
                          }

                          if (state.currentStep == 3) {
                            notifier.setPrice(
                              double.tryParse(_priceController.text.trim()) ?? 0,
                            );
                            notifier.setTrucksNeeded(
                              int.tryParse(_customTrucksController.text.trim()) ??
                                  1,
                            );
                            final success = await notifier.submitLoad();
                            if (!context.mounted) return;
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.loadPostedSuccess)),
                              );
                              unawaited(
                                ref
                                    .read(ttsServiceProvider)
                                    .speak(l10n.postLoadTtsSuccess),
                              );
                              context.go('/my-loads');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.loadPostFailure)),
                              );
                              unawaited(
                                ref
                                    .read(ttsServiceProvider)
                                    .speak(l10n.postLoadTtsFailure),
                              );
                            }
                            return;
                          }

                          if (state.currentStep == 1) {
                            notifier.setWeight(
                              double.tryParse(_weightController.text.trim()) ??
                                  0,
                            );
                          }
                          if (state.currentStep == 3) {
                            notifier.setPrice(
                              double.tryParse(_priceController.text.trim()) ??
                                  0,
                            );
                            notifier.setTrucksNeeded(
                              int.tryParse(
                                    _customTrucksController.text.trim(),
                                  ) ??
                                  1,
                            );
                          }
                          notifier.nextStep();
                        },
                        onStepCancel: notifier.previousStep,
                        controlsBuilder: (context, details) {
                          return Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                label: state.currentStep == 3
                                    ? l10n.postLoadSubmitAction
                                    : l10n.nextAction,
                                isLoading: state.isSubmitting,
                                onPressed: details.onStepContinue,
                              ),
                              ),
                              if (state.currentStep > 0) ...[
                                const SizedBox(width: AppSpacing.md),
                                SizedBox(
                                  width: 104,
                                  child: OutlineButton(
                                    label: l10n.backAction,
                                    onPressed: details.onStepCancel,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                        steps: [
                          Step(
                            isActive: state.currentStep >= 0,
                            title: const SizedBox.shrink(),
                            content: _buildStepCard(
                              context,
                              child: Column(
                                children: [
                                  CityField(
                                    label: l10n.postLoadOriginCityLabel,
                                    controller: _originController,
                                    searchKey: 'origin',
                                    onSelected: (city) {
                                      _originController.text = city.displayName;
                                      notifier.setOriginSuggestion(city);
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  CityField(
                                    label: l10n.postLoadDestinationCityLabel,
                                    controller: _destinationController,
                                    searchKey: 'destination',
                                    onSelected: (city) {
                                      _destinationController.text =
                                          city.displayName;
                                      notifier.setDestinationSuggestion(city);
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  if (state.distanceKm != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(
                                        AppSpacing.md,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.buttonRadius,
                                        ),
                                        color: AppColors.brandTealLight
                                            .withValues(alpha: 0.50),
                                        border: Border.all(
                                          color: AppColors.neutralLight,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            l10n.postLoadApproxRouteInfo(
                                              state.distanceKm!
                                                  .toStringAsFixed(0),
                                              state.durationHours
                                                      ?.toStringAsFixed(1) ??
                                                  '-',
                                            ),
                                          ),
                                          if (state.tollEstimate != null) ...[
                                            const SizedBox(
                                              height: AppSpacing.xs,
                                            ),
                                            Text(
                                              '${l10n.loadDetailTripCostTolls}: ₹${state.tollEstimate!.toStringAsFixed(0)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppColors.neutral,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  else
                                    Text(
                                      l10n.postLoadDistanceUnavailableFallback,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.neutral),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Step(
                            isActive: state.currentStep >= 1,
                            title: const SizedBox.shrink(),
                            content: _buildStepCard(
                              context,
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedMaterialValue(
                                      state.material,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.postLoadMaterialLabel,
                                      filled: true,
                                      fillColor: AppColors.inputBg,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                                        borderSide: const BorderSide(color: AppColors.borderDefault),
                                      ),
                                    ),
                                    items: _materials
                                        .map(
                                          (material) => DropdownMenuItem(
                                            value: material,
                                            child: Text(material),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        notifier.setMaterial(value);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TtsFocusField(
                                    labelToSpeak: l10n.postLoadWeightPerTruckLabel,
                                    child: TextFormField(
                                      controller: _weightController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: InputDecoration(
                                        labelText: l10n.postLoadWeightPerTruckLabel,
                                      ),
                                      onChanged: (value) {
                                        notifier.setWeight(
                                          double.tryParse(value.trim()) ?? 0,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Step(
                            isActive: state.currentStep >= 2,
                            title: const SizedBox.shrink(),
                            content: _buildStepCard(
                              context,
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String?>(
                                    initialValue: _selectedTruckTypeValue(
                                      state.requiredTruckType,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: l10n.postLoadTruckBodyTypeLabel,
                                      filled: true,
                                      fillColor: AppColors.inputBg,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                                        borderSide: const BorderSide(color: AppColors.borderDefault),
                                      ),
                                    ),
                                    items: _truckTypes
                                        .map(
                                          (type) => DropdownMenuItem<String?>(
                                            value: type,
                                            child: Text(
                                              _truckTypeLabel(type, l10n),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      notifier.setTruckType(value);
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Wrap(
                                      spacing: AppSpacing.sm,
                                      children: _tyres
                                          .map(
                                            (tyre) => FilterChip(
                                              label: Text('$tyre'),
                                              selected: state.requiredTyres
                                                  .contains(tyre),
                                              onSelected: (_) =>
                                                  notifier.toggleTyre(tyre),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Step(
                            isActive: state.currentStep >= 3,
                            title: const SizedBox.shrink(),
                            content: _buildStepCard(
                              context,
                              child: Column(
                                children: [
                                  TtsFocusField(
                                    labelToSpeak: _priceInputLabel(
                                      l10n,
                                      state.priceType,
                                    ),
                                    child: TextFormField(
                                      controller: _priceController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: InputDecoration(
                                        labelText: _priceInputLabel(
                                          l10n,
                                          state.priceType,
                                        ),
                                      ),
                                      onChanged: (value) => notifier.setPrice(
                                        double.tryParse(value.trim()) ?? 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  SegmentedButton<String>(
                                    segments: [
                                      ButtonSegment(
                                        value: 'fixed',
                                        label: Text(l10n.postLoadPriceTypeFixed),
                                      ),
                                      ButtonSegment(
                                        value: LoadPricing.perTon,
                                        label: Text(
                                          l10n.postLoadPriceTypeNegotiable,
                                        ),
                                      ),
                                    ],
                                    selected: {state.priceType},
                                    onSelectionChanged: (value) {
                                      notifier.setPriceType(value.first);
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.postLoadAdvanceLabel(
                                          state.advancePercentage,
                                        ),
                                      ),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 4,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                        ),
                                        child: Slider(
                                          value: state.advancePercentage.toDouble(),
                                          min: 0,
                                          max: 100,
                                          divisions: 20,
                                          onChanged: (value) =>
                                              notifier.setAdvance(value.round()),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                                      side: const BorderSide(color: AppColors.borderDefault),
                                    ),
                                    tileColor: AppColors.inputBg,
                                    title: Text(l10n.postLoadPickupDateLabel),
                                    subtitle: Text(
                                      '${state.pickupDate.day}/${state.pickupDate.month}/${state.pickupDate.year}',
                                    ),
                                    trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
                                    onTap: () async {
                                      final selected = await showDatePicker(
                                        context: context,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365),
                                        ),
                                        initialDate: state.pickupDate,
                                      );
                                      if (selected != null) {
                                        notifier.setPickupDate(selected);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TtsFocusField(
                                    labelToSpeak: l10n.postLoadTrucksNeededLabel,
                                    child: TextFormField(
                                      controller: _customTrucksController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: l10n.postLoadTrucksNeededLabel,
                                      ),
                                      onChanged: (value) =>
                                          notifier.setTrucksNeeded(
                                            int.tryParse(value.trim()) ?? 1,
                                          ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: child,
    );
  }

  String _truckTypeLabel(String? type, AppLocalizations l10n) {
    switch (type) {
      case null:
        return l10n.postLoadTruckTypeAny;
      case 'open':
        return l10n.postLoadTruckTypeOpen;
      case 'container':
        return l10n.postLoadTruckTypeContainer;
      case 'trailer':
        return l10n.postLoadTruckTypeTrailer;
      case 'tanker':
        return l10n.postLoadTruckTypeTanker;
      case 'refrigerated':
        return l10n.postLoadTruckTypeRefrigerated;
      default:
        return type;
    }
  }
}


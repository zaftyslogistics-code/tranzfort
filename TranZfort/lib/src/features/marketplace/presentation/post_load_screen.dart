import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/city_search_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/marketplace_providers.dart';

class PostLoadScreen extends ConsumerStatefulWidget {
  const PostLoadScreen({super.key});

  @override
  ConsumerState<PostLoadScreen> createState() => _PostLoadScreenState();
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
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _customTrucksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postLoadProvider);
    final notifier = ref.read(postLoadProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Post Load')),
      body: Stepper(
        currentStep: state.currentStep,
        onStepContinue: () async {
          if (state.currentStep == 3) {
            final success = await notifier.submitLoad();
            if (!context.mounted) return;
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Load posted successfully')),
              );
              context.go('/my-loads');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not post load. Please review fields.'),
                ),
              );
            }
            return;
          }

          if (state.currentStep == 1) {
            notifier.setWeight(
              double.tryParse(_weightController.text.trim()) ?? 0,
            );
          }
          if (state.currentStep == 3) {
            notifier.setPrice(
              double.tryParse(_priceController.text.trim()) ?? 0,
            );
            notifier.setTrucksNeeded(
              int.tryParse(_customTrucksController.text.trim()) ?? 1,
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
                  label: state.currentStep == 3 ? 'Post Load' : 'Next',
                  isLoading: state.isSubmitting,
                  onPressed: details.onStepContinue,
                ),
              ),
              if (state.currentStep > 0) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
              ],
            ],
          );
        },
        steps: [
          Step(
            isActive: state.currentStep >= 0,
            title: const Text('Route'),
            content: Column(
              children: [
                _CityField(
                  label: 'Origin City',
                  controller: _originController,
                  searchKey: 'origin',
                  onSelected: (city) {
                    _originController.text = city.displayName;
                    notifier.setOrigin(city);
                  },
                ),
                const SizedBox(height: 12),
                _CityField(
                  label: 'Destination City',
                  controller: _destinationController,
                  searchKey: 'destination',
                  onSelected: (city) {
                    _destinationController.text = city.displayName;
                    notifier.setDestination(city);
                  },
                ),
                const SizedBox(height: 12),
                if (state.distanceKm != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.background,
                      border: Border.all(color: AppColors.neutralLight),
                    ),
                    child: Text(
                      'Approx route: ${state.distanceKm!.toStringAsFixed(0)} km · ${state.durationHours?.toStringAsFixed(1) ?? '-'}h',
                    ),
                  )
                else
                  const Text(
                    'Distance unavailable (offline fallback in use)',
                    style: TextStyle(color: AppColors.neutral),
                  ),
              ],
            ),
          ),
          Step(
            isActive: state.currentStep >= 1,
            title: const Text('Cargo'),
            content: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: state.material,
                  decoration: const InputDecoration(
                    labelText: 'Material',
                    border: OutlineInputBorder(),
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
                    if (value != null) notifier.setMaterial(value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Weight per Truck (Tonnes)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    notifier.setWeight(double.tryParse(value.trim()) ?? 0);
                  },
                ),
              ],
            ),
          ),
          Step(
            isActive: state.currentStep >= 2,
            title: const Text('Vehicle'),
            content: Column(
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: state.requiredTruckType,
                  decoration: const InputDecoration(
                    labelText: 'Truck Body Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _truckTypes
                      .map(
                        (type) => DropdownMenuItem<String?>(
                          value: type,
                          child: Text(type ?? 'Any'),
                        ),
                      )
                      .toList(),
                  onChanged: notifier.setTruckType,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tyres
                      .map(
                        (tyre) => FilterChip(
                          label: Text('$tyre'),
                          selected: state.requiredTyres.contains(tyre),
                          onSelected: (_) => notifier.toggleTyre(tyre),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          Step(
            isActive: state.currentStep >= 3,
            title: const Text('Price & Scale'),
            content: Column(
              children: [
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Total Price (₹)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      notifier.setPrice(double.tryParse(value.trim()) ?? 0),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'fixed', label: Text('Fixed')),
                    ButtonSegment(
                      value: 'negotiable',
                      label: Text('Negotiable'),
                    ),
                  ],
                  selected: {state.priceType},
                  onSelectionChanged: (value) {
                    notifier.setPriceType(value.first);
                  },
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Advance: ${state.advancePercentage}%'),
                    Slider(
                      value: state.advancePercentage.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: (value) => notifier.setAdvance(value.round()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pickup Date'),
                  subtitle: Text(
                    '${state.pickupDate.day}/${state.pickupDate.month}/${state.pickupDate.year}',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: state.pickupDate,
                      );
                      if (selected != null) {
                        notifier.setPickupDate(selected);
                      }
                    },
                    child: const Text('Change'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customTrucksController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'How many trucks needed?',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      notifier.setTrucksNeeded(int.tryParse(value.trim()) ?? 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CityField extends ConsumerWidget {
  final String label;
  final TextEditingController controller;
  final String searchKey;
  final ValueChanged<CitySuggestion> onSelected;

  const _CityField({
    required this.label,
    required this.controller,
    required this.searchKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(citySearchProvider(searchKey));
    final notifier = ref.read(citySearchProvider(searchKey).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: state.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: notifier.search,
        ),
        if (state.suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.neutralLight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final city = state.suggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(city.displayName),
                  onTap: () {
                    onSelected(city);
                    notifier.clear();
                  },
                );
              },
              separatorBuilder:
                  (context, index) => const Divider(height: 1),
              itemCount: state.suggestions.length,
            ),
          ),
      ],
    );
  }
}

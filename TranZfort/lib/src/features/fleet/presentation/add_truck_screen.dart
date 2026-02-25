import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/image_picker_util.dart';
import '../providers/fleet_providers.dart';

class AddTruckScreen extends ConsumerStatefulWidget {
  const AddTruckScreen({super.key});

  @override
  ConsumerState<AddTruckScreen> createState() => _AddTruckScreenState();
}

class _AddTruckScreenState extends ConsumerState<AddTruckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _truckNumberController = TextEditingController();
  final _tyresController = TextEditingController(text: '6');
  final _capacityController = TextEditingController(text: '10');

  String? _selectedBodyType;
  String? _selectedModelId;
  File? _rcPhoto;

  static const _bodyTypes = <String>[
    'open',
    'container',
    'trailer',
    'tanker',
    'refrigerated',
  ];

  @override
  void dispose() {
    _truckNumberController.dispose();
    _tyresController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickRcPhoto() async {
    final file = await ImagePickerUtil.pickAndCompressImage(
      context: context,
      source: ImageSource.gallery,
    );
    if (file != null && mounted) {
      setState(() => _rcPhoto = file);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBodyType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select body type')));
      return;
    }

    await ref
        .read(addTruckProvider.notifier)
        .addTruck(
          truckNumber: _truckNumberController.text.trim(),
          bodyType: _selectedBodyType!,
          tyres: int.tryParse(_tyresController.text.trim()) ?? 6,
          capacityTonnes: double.tryParse(_capacityController.text.trim()) ?? 0,
          truckModelId: _selectedModelId,
          rcPhotoFile: _rcPhoto,
        );

    final state = ref.read(addTruckProvider);
    if (mounted) {
      if (state.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add truck. Please try again.')));
      } else {
        ref.invalidate(fleetProvider);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final addState = ref.watch(addTruckProvider);
    final modelsAsync = ref.watch(truckCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Truck')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _truckNumberController,
                decoration: const InputDecoration(
                  labelText: 'Truck Number',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Truck number is required'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedBodyType,
                items: _bodyTypes
                    .map(
                      (e) => DropdownMenuItem<String>(value: e, child: Text(e)),
                    )
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Body Type',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _selectedBodyType = v),
              ),
              const SizedBox(height: 12),
              modelsAsync.when(
                data: (models) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedModelId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Not in list / manual entry'),
                      ),
                      ...models.map(
                        (m) => DropdownMenuItem<String?>(
                          value: m['id']?.toString(),
                          child: Text('${m['make']} ${m['model']}'),
                        ),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Truck Model (optional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _selectedModelId = v),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => const Text(
                  'Failed to load truck catalog. Please try again.',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tyresController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tyres',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final tyres = int.tryParse(v ?? '');
                        if (tyres == null || tyres < 4 || tyres > 22) {
                          return '4-22';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacity (T)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final cap = double.tryParse(v ?? '');
                        if (cap == null || cap <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('RC Photo'),
                subtitle: Text(_rcPhoto == null ? 'Not selected' : 'Selected'),
                trailing: OutlinedButton.icon(
                  onPressed: _pickRcPhoto,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_rcPhoto == null ? 'Upload' : 'Retake'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: addState.isLoading ? null : _submit,
                  child: addState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Truck'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

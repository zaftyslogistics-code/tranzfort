import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/splitted/super_ops_models.dart';
import '../../../shared/widgets/admin_brand_header.dart';
import '../../../shared/widgets/error_retry.dart';
import '../providers/super_ops_detail_provider.dart';

class SuperOpsPostOnBehalfScreen extends ConsumerStatefulWidget {
  const SuperOpsPostOnBehalfScreen({super.key});

  @override
  ConsumerState<SuperOpsPostOnBehalfScreen> createState() =>
      _SuperOpsPostOnBehalfScreenState();
}

class _SuperOpsPostOnBehalfScreenState
    extends ConsumerState<SuperOpsPostOnBehalfScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _supplierId;
  final _originCity = TextEditingController();
  final _originState = TextEditingController();
  final _destCity = TextEditingController();
  final _destState = TextEditingController();
  final _material = TextEditingController();
  final _weight = TextEditingController();
  final _truckType = TextEditingController();
  final _trucksNeeded = TextEditingController(text: '1');
  final _price = TextEditingController();
  final _advance = TextEditingController(text: '80');
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _originCity.dispose();
    _originState.dispose();
    _destCity.dispose();
    _destState.dispose();
    _material.dispose();
    _weight.dispose();
    _truckType.dispose();
    _trucksNeeded.dispose();
    _price.dispose();
    _advance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(superOpsSuppliersProvider);
    final actionState = ref.watch(superOpsActionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Post Super load on behalf')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          const AdminBrandHeader(
            title: 'Admin-assisted posting',
            subtitle:
                'Create a supplier super-load request from phone-call or assisted operations flow',
            icon: Icons.post_add,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    suppliersAsync.when(
                      data: (suppliers) => DropdownButtonFormField<String>(
                        initialValue: _supplierId,
                        decoration: const InputDecoration(
                          labelText: 'Supplier account',
                        ),
                        items: suppliers
                            .map(
                              (s) => DropdownMenuItem<String>(
                                value: s.supplierId,
                                child: Text(
                                  '${s.supplierName.ifEmpty('Unknown')} • ${s.companyName.ifEmpty('No company')}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _supplierId = value),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Select a supplier account'
                            : null,
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(8),
                        child: LinearProgressIndicator(),
                      ),
                      error: (error, stack) => ErrorRetry(
                        title: 'Unable to load suppliers',
                        subtitle: 'Please check your connection and try again.',
                        onRetry: () => ref.invalidate(superOpsSuppliersProvider),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Field(controller: _originCity, label: 'Origin City'),
                    _Field(controller: _originState, label: 'Origin State'),
                    _Field(controller: _destCity, label: 'Destination City'),
                    _Field(controller: _destState, label: 'Destination State'),
                    _Field(controller: _material, label: 'Material'),
                    _Field(
                      controller: _weight,
                      label: 'Weight (tonnes)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _Field(
                      controller: _truckType,
                      label:
                          'Required Truck Type (open/container/trailer/tanker/refrigerated)',
                    ),
                    _Field(
                      controller: _trucksNeeded,
                      label: 'Trucks Needed',
                      keyboardType: TextInputType.number,
                    ),
                    _Field(
                      controller: _price,
                      label: 'Price (INR)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _Field(
                      controller: _advance,
                      label: 'Advance %',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pickup date'),
                      subtitle: Text(
                        _pickupDate.toIso8601String().split('T').first,
                      ),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: _pickupDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 1),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (selected != null) {
                          setState(() => _pickupDate = selected);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: actionState.isLoading ? null : _submit,
                        child: const Text('Post Super load'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final supplierId = _supplierId;
    if (supplierId == null || supplierId.isEmpty) {
      _showSnack(false, 'Please select a supplier account.');
      return;
    }

    final payload = SuperOpsPostLoadPayload(
      supplierId: supplierId,
      originCity: _originCity.text.trim(),
      originState: _originState.text.trim(),
      destCity: _destCity.text.trim(),
      destState: _destState.text.trim(),
      material: _material.text.trim(),
      weightTonnes: double.tryParse(_weight.text.trim()) ?? 0,
      requiredTruckType: _truckType.text.trim().toLowerCase(),
      trucksNeeded: int.tryParse(_trucksNeeded.text.trim()) ?? 1,
      price: double.tryParse(_price.text.trim()) ?? 0,
      priceType: 'fixed',
      advancePercentage: int.tryParse(_advance.text.trim()) ?? 80,
      pickupDate: _pickupDate,
    );

    final ok = await ref
        .read(superOpsActionProvider.notifier)
        .postOnBehalf(payload);
    if (!mounted) return;

    _showSnack(
      ok,
      ok
          ? 'Super load posted on behalf successfully.'
          : 'Could not post super load on behalf.',
    );
    if (ok) Navigator.of(context).pop();
  }

  void _showSnack(bool ok, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? 'This field is required' : null,
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

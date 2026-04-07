import 'package:supabase_flutter/supabase_flutter.dart';

class TruckModelService {
  TruckModelService(this._supabase);

  final SupabaseClient _supabase;
  List<Map<String, dynamic>>? _cache;

  Future<List<Map<String, dynamic>>> getTruckModels({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache != null) {
      return _cache!;
    }

    final data = await _supabase
        .from('truck_models')
        .select('id, make, model, body_type, payload_kg, axles, gvw_kg')
        .order('make')
        .order('model');

    _cache = List<Map<String, dynamic>>.from(data);
    return _cache!;
  }

  void clearCache() {
    _cache = null;
  }
}

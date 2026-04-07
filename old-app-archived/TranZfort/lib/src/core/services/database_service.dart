import 'package:supabase_flutter/supabase_flutter.dart';
import '../error/app_failure.dart';
import '../error/result.dart';

class DatabaseService {
  final SupabaseClient _supabase;

  DatabaseService(this._supabase);

  Future<Result<List<Map<String, dynamic>>>> get(
    String table, {
    String? filterColumn,
    dynamic filterValue,
  }) async {
    try {
      var query = _supabase.from(table).select();
      if (filterColumn != null && filterValue != null) {
        query = query.eq(filterColumn, filterValue);
      }
      final response = await query;
      return Success(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> getSingle(
    String table, {
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .eq(filterColumn, filterValue)
          .single();
      return Success(response);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from(table)
          .insert(data)
          .select()
          .single();
      return Success(response);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<Map<String, dynamic>>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return Success(response);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> delete(String table, String id) async {
    try {
      await _supabase.from(table).delete().eq('id', id);
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }
}

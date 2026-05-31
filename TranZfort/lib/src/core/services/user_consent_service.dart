import 'package:supabase_flutter/supabase_flutter.dart';

/// Records rows in [user_consents] via [record_user_consent] RPC.
class UserConsentService {
  final SupabaseClient? _client;

  const UserConsentService(this._client);

  Future<void> record({
    required String consentType,
    required String sourceContext,
    String consentVersion = 'v1',
  }) async {
    final client = _client;
    if (client == null) {
      return;
    }

    await client.rpc(
      'record_user_consent',
      params: <String, dynamic>{
        'p_consent_type': consentType,
        'p_consent_version': consentVersion,
        'p_source_context': sourceContext,
      },
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import 'map_readers.dart';

/// Merges avatar storage paths from [profiles] into a public-profile map.
///
/// [get_public_profile] may omit [profile_photo_document_path] even though many
/// users only have a photo stored there.
Future<Map<String, dynamic>?> mergeProfileAvatarFields({
  required SupabaseClient client,
  required String userId,
  Map<String, dynamic>? profile,
}) async {
  final avatarRow = await client
      .from('profiles')
      .select('avatar_url, profile_photo_document_path')
      .eq('id', userId)
      .maybeSingle();

  if (profile == null && avatarRow == null) {
    return null;
  }

  return <String, dynamic>{
    ...?profile,
    'avatar_url': nullableString(profile?['avatar_url']) ?? nullableString(avatarRow?['avatar_url']),
    'profile_photo_document_path': nullableString(avatarRow?['profile_photo_document_path']),
  };
}

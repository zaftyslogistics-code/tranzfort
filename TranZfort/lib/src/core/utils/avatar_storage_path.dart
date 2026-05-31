/// Resolves which profile photo storage path to use for [UserAvatar].
///
/// After P0-7/P0-8, `profiles.avatar_url` may still hold a stale public/signed HTTP
/// URL while `profile_photo_document_path` holds the canonical private-bucket path.
class AvatarStoragePath {
  AvatarStoragePath._();

  /// Prefer a private storage path over legacy HTTP URLs in `avatar_url`.
  static String? pick({
    String? avatarUrl,
    String? profilePhotoPath,
  }) {
    final photo = _trim(profilePhotoPath);
    final avatar = _trim(avatarUrl);

    if (photo != null && isStoragePath(photo)) {
      return photo;
    }
    if (avatar != null && isStoragePath(avatar)) {
      return avatar;
    }
    if (photo != null) {
      return photo;
    }
    return null;
  }

  /// HTTP URL to load directly when no storage path is available (e.g. legacy public URLs).
  static String? legacyHttpUrl({
    String? avatarUrl,
    String? profilePhotoPath,
  }) {
    if (pick(avatarUrl: avatarUrl, profilePhotoPath: profilePhotoPath) != null) {
      return null;
    }
    final avatar = _trim(avatarUrl);
    if (avatar != null &&
        (avatar.startsWith('http://') || avatar.startsWith('https://'))) {
      return avatar;
    }
    return null;
  }

  /// Storage path first, then legacy HTTP — for models that expose a single avatar field.
  static String? resolveDisplaySource({
    String? avatarUrl,
    String? profilePhotoPath,
  }) {
    return pick(avatarUrl: avatarUrl, profilePhotoPath: profilePhotoPath) ??
        legacyHttpUrl(avatarUrl: avatarUrl, profilePhotoPath: profilePhotoPath);
  }

  static bool isStoragePath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return false;
    }
    return trimmed.contains('/');
  }

  static String initialsFor({
    required String displayName,
    String? userId,
    String fallback = '?',
  }) {
    final name = displayName.trim();
    if (name.isNotEmpty) {
      return name.substring(0, 1).toUpperCase();
    }
    final id = userId?.trim();
    if (id != null && id.isNotEmpty) {
      return id.substring(0, 1).toUpperCase();
    }
    return fallback;
  }

  /// Path variants for signing (legacy rows used a `profiles/` prefix).
  static List<String> storagePathCandidates(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final candidates = <String>{trimmed};
    if (trimmed.startsWith('profiles/')) {
      candidates.add(trimmed.substring('profiles/'.length));
    } else if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      candidates.add('profiles/$trimmed');
    }
    return candidates.toList(growable: false);
  }

  static String? _trim(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

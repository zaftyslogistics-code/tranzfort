import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/utils/avatar_storage_path.dart';

void main() {
  test('pick prefers profile_photo_document_path over stale http avatar_url', () {
    final path = AvatarStoragePath.pick(
      avatarUrl: 'https://example.supabase.co/storage/v1/object/public/old.jpg',
      profilePhotoPath: 'user-1/profile_photo/profile_photo.jpg',
    );
    expect(path, 'user-1/profile_photo/profile_photo.jpg');
  });

  test('pick uses storage path from avatar_url when photo path absent', () {
    final path = AvatarStoragePath.pick(
      avatarUrl: 'user-2/profile_photo/profile_photo.jpg',
    );
    expect(path, 'user-2/profile_photo/profile_photo.jpg');
  });

  test('isStoragePath rejects http urls', () {
    expect(AvatarStoragePath.isStoragePath('https://cdn.example/a.jpg'), isFalse);
  });

  test('storagePathCandidates strips and adds profiles prefix', () {
    expect(
      AvatarStoragePath.storagePathCandidates('profiles/user-1/profile_photo/profile_photo.jpg'),
      contains('user-1/profile_photo/profile_photo.jpg'),
    );
    expect(
      AvatarStoragePath.storagePathCandidates('user-1/profile_photo/profile_photo.jpg'),
      contains('profiles/user-1/profile_photo/profile_photo.jpg'),
    );
  });

  test('resolveDisplaySource returns storage path before legacy http', () {
    final resolved = AvatarStoragePath.resolveDisplaySource(
      avatarUrl: 'https://cdn.example/stale.jpg',
      profilePhotoPath: 'user-1/profile_photo/profile_photo.jpg',
    );
    expect(resolved, 'user-1/profile_photo/profile_photo.jpg');
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/providers/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../core/error/result.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(ref.watch(supabaseClientProvider));
});

final supplierVerificationProvider =
    StateNotifierProvider<SupplierVerificationNotifier, AsyncValue<void>>((
      ref,
    ) {
      return SupplierVerificationNotifier(
        ref.watch(storageServiceProvider),
        ref.watch(databaseServiceProvider),
        ref.watch(authSessionProvider).value?.session?.user,
      );
    });

final truckerVerificationProvider =
    StateNotifierProvider<TruckerVerificationNotifier, AsyncValue<void>>((ref) {
      return TruckerVerificationNotifier(
        ref.watch(storageServiceProvider),
        ref.watch(databaseServiceProvider),
        ref.watch(authSessionProvider).value?.session?.user,
      );
    });

abstract class BaseVerificationNotifier
    extends StateNotifier<AsyncValue<void>> {
  final StorageService storageService;
  final DatabaseService databaseService;
  final User? user;

  BaseVerificationNotifier(this.storageService, this.databaseService, this.user)
    : super(const AsyncValue.data(null));

  Future<String> uploadOrThrow(
    String bucket,
    String userId,
    File file,
    String prefix,
  ) async {
    final result = await storageService.uploadFile(
      bucketName: bucket,
      folderPath: userId,
      file: file,
      fileNamePrefix: prefix,
    );

    switch (result) {
      case Success(data: final url):
        return url;
      case Failure(debugMessage: final msg):
        throw Exception('Upload failed for $prefix: $msg');
    }
  }

  Future<void> updateProfileDocs({
    required String userId,
    required String aadhaarNumber,
    required String aadhaarFrontUrl,
    required String aadhaarBackUrl,
    required String panNumber,
    required String panPhotoUrl,
    required String avatarUrl,
  }) async {
    final profileResult = await databaseService.update('profiles', userId, {
      'aadhaar_number': aadhaarNumber,
      'aadhaar_last4': aadhaarNumber.substring(aadhaarNumber.length - 4),
      'aadhaar_front_photo_url': aadhaarFrontUrl,
      'aadhaar_back_photo_url': aadhaarBackUrl,
      'pan_number': panNumber,
      'pan_photo_url': panPhotoUrl,
      'avatar_url': avatarUrl,
      'verification_status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    });

    switch (profileResult) {
      case Success():
        break;
      case Failure(debugMessage: final msg):
        throw Exception(msg ?? 'Failed to update profile');
    }
  }

  Future<Map<String, dynamic>> loadExistingData() async {
    if (user == null) return const <String, dynamic>{};

    final profileResult = await databaseService.getSingle(
      'profiles',
      filterColumn: 'id',
      filterValue: user!.id,
    );
    final supplierResult = await databaseService.getSingle(
      'suppliers',
      filterColumn: 'id',
      filterValue: user!.id,
    );

    return {
      'profile': switch (profileResult) {
        Success(data: final data) => data,
        Failure() => <String, dynamic>{},
      },
      'supplier': switch (supplierResult) {
        Success(data: final data) => data,
        Failure() => <String, dynamic>{},
      },
    };
  }
}

class SupplierVerificationNotifier extends BaseVerificationNotifier {
  SupplierVerificationNotifier(
    super.storageService,
    super.databaseService,
    super.user,
  );

  Future<void> submitVerification({
    required String companyName,
    required String aadhaarNumber,
    File? profilePhoto,
    File? aadhaarFront,
    File? aadhaarBack,
    required String panNumber,
    File? panPhoto,
    required String tanNumber,
    File? tanPhoto,
    required String gstNumber,
    File? gstPhoto,
    required String businessLicenceNumber,
    File? businessLicenceDoc,
  }) async {
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final userId = user!.id;
      final bucket = 'verification-docs';

      final existing = await loadExistingData();
      final existingProfile =
          existing['profile'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final existingSupplier =
          existing['supplier'] as Map<String, dynamic>? ??
          const <String, dynamic>{};

      String? aadhaarFrontUrl = existingProfile['aadhaar_front_photo_url']
          ?.toString();
      String? aadhaarBackUrl = existingProfile['aadhaar_back_photo_url']
          ?.toString();
      String? panPhotoUrl = existingProfile['pan_photo_url']?.toString();
      String? avatarUrl = existingProfile['avatar_url']?.toString();
      String? gstPhotoUrl = existingSupplier['gst_photo_url']?.toString();
      String? tanPhotoUrl = existingSupplier['tan_photo_url']?.toString();
      String? businessLicenceUrl = existingSupplier['business_licence_doc_url']?.toString();

      // Upload files
      if (profilePhoto != null) {
        avatarUrl = await uploadOrThrow(
          bucket,
          userId,
          profilePhoto,
          'profile_avatar',
        );
      }
      if (aadhaarFront != null) {
        aadhaarFrontUrl = await uploadOrThrow(
          bucket,
          userId,
          aadhaarFront,
          'aadhaar_front',
        );
      }
      if (aadhaarBack != null) {
        aadhaarBackUrl = await uploadOrThrow(
          bucket,
          userId,
          aadhaarBack,
          'aadhaar_back',
        );
      }
      if (panPhoto != null) {
        panPhotoUrl = await uploadOrThrow(bucket, userId, panPhoto, 'pan');
      }
      if (tanPhoto != null) {
        tanPhotoUrl = await uploadOrThrow(bucket, userId, tanPhoto, 'tan');
      }
      if (gstPhoto != null) {
        gstPhotoUrl = await uploadOrThrow(bucket, userId, gstPhoto, 'gst');
      }
      if (businessLicenceDoc != null) {
        businessLicenceUrl = await uploadOrThrow(
          bucket,
          userId,
          businessLicenceDoc,
          'business_licence',
        );
      }

      // Validate mandatory documents: Aadhaar and either PAN or TAN
      if (aadhaarFrontUrl == null || aadhaarBackUrl == null) {
        throw Exception('Aadhaar documents are required');
      }
      if (panPhotoUrl == null && tanPhotoUrl == null) {
        throw Exception('Either PAN or TAN is required');
      }
      if (businessLicenceUrl == null) {
        throw Exception('Business license document is required');
      }

      // Update profile with Aadhaar and PAN (if provided)
      await updateProfileDocs(
        userId: userId,
        aadhaarNumber: aadhaarNumber,
        aadhaarFrontUrl: aadhaarFrontUrl,
        aadhaarBackUrl: aadhaarBackUrl,
        panNumber: panNumber.isNotEmpty ? panNumber : '',
        panPhotoUrl: panPhotoUrl ?? '',
        avatarUrl: avatarUrl ?? '',
      );

      // Update Suppliers Table
      final Map<String, dynamic> supplierData = {
        'company_name': companyName,
        'business_licence_number': businessLicenceNumber,
        'business_licence_doc_url': businessLicenceUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add TAN if provided (alternative to PAN)
      if (tanNumber.isNotEmpty) {
        supplierData['tan_number'] = tanNumber;
      }
      if (tanPhotoUrl != null) {
        supplierData['tan_photo_url'] = tanPhotoUrl;
      }

      // Add GST if provided (optional)
      if (gstNumber.isNotEmpty) {
        supplierData['gst_number'] = gstNumber;
      }
      if (gstPhotoUrl != null) {
        supplierData['gst_photo_url'] = gstPhotoUrl;
      }

      final supplierResult = await databaseService.update(
        'suppliers',
        userId,
        supplierData,
      );

      switch (supplierResult) {
        case Success():
          break;
        case Failure(debugMessage: final msg):
          throw Exception(msg ?? 'Failed to update supplier details');
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class TruckerVerificationNotifier extends BaseVerificationNotifier {
  TruckerVerificationNotifier(
    super.storageService,
    super.databaseService,
    super.user,
  );

  Future<bool> hasAtLeastOneCompleteTruck() async {
    if (user == null) return false;

    final trucksResult = await databaseService.get(
      'trucks',
      filterColumn: 'owner_id',
      filterValue: user!.id,
    );

    return switch (trucksResult) {
      Success(data: final trucks) => trucks.any((truck) {
        final number = (truck['truck_number'] ?? '').toString().trim();
        final bodyType = (truck['body_type'] ?? '').toString().trim();
        final tyres = truck['tyres'];
        final capacity = truck['capacity_tonnes'];
        final rcUrl = (truck['rc_photo_url'] ?? '').toString().trim();

        final hasTyres = tyres is num ? tyres > 0 : false;
        final hasCapacity = capacity is num ? capacity > 0 : false;

        return number.isNotEmpty &&
            bodyType.isNotEmpty &&
            hasTyres &&
            hasCapacity &&
            rcUrl.isNotEmpty;
      }),
      Failure() => false,
    };
  }

  Future<void> submitVerification({
    required String aadhaarNumber,
    File? profilePhoto,
    File? aadhaarFront,
    File? aadhaarBack,
    required String panNumber,
    File? panPhoto,
    required String dlNumber,
    DateTime? dlExpiryDate,
    File? dlFrontPhoto,
    File? dlBackPhoto,
  }) async {
    if (user == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return;
    }

    final hasCompleteTruck = await hasAtLeastOneCompleteTruck();
    if (!hasCompleteTruck) {
      state = AsyncValue.error(
        'At least one complete truck with RC photo is required.',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final userId = user!.id;
      final bucket = 'verification-docs';

      final existing = await loadExistingData();
      final existingProfile =
          existing['profile'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final existingTrucker =
          existing['trucker'] as Map<String, dynamic>? ??
          const <String, dynamic>{};

      String? aadhaarFrontUrl = existingProfile['aadhaar_front_photo_url']
          ?.toString();
      String? aadhaarBackUrl = existingProfile['aadhaar_back_photo_url']
          ?.toString();
      String? panPhotoUrl = existingProfile['pan_photo_url']?.toString();
      String? avatarUrl = existingProfile['avatar_url']?.toString();
      String? dlFrontUrl = existingTrucker['dl_front_photo_url']?.toString();
      String? dlBackUrl = existingTrucker['dl_back_photo_url']?.toString();

      // Upload files
      if (profilePhoto != null) {
        avatarUrl = await uploadOrThrow(
          bucket,
          userId,
          profilePhoto,
          'profile_avatar',
        );
      }
      if (aadhaarFront != null) {
        aadhaarFrontUrl = await uploadOrThrow(
          bucket,
          userId,
          aadhaarFront,
          'aadhaar_front',
        );
      }
      if (aadhaarBack != null) {
        aadhaarBackUrl = await uploadOrThrow(
          bucket,
          userId,
          aadhaarBack,
          'aadhaar_back',
        );
      }
      if (panPhoto != null) {
        panPhotoUrl = await uploadOrThrow(bucket, userId, panPhoto, 'pan');
      }
      if (dlFrontPhoto != null) {
        dlFrontUrl = await uploadOrThrow(
          bucket,
          userId,
          dlFrontPhoto,
          'dl_front',
        );
      }
      if (dlBackPhoto != null) {
        dlBackUrl = await uploadOrThrow(bucket, userId, dlBackPhoto, 'dl_back');
      }

      if (aadhaarFrontUrl == null ||
          avatarUrl == null ||
          aadhaarBackUrl == null ||
          panPhotoUrl == null ||
          dlFrontUrl == null ||
          dlBackUrl == null) {
        throw Exception('Missing required documents for verification');
      }

      await updateProfileDocs(
        userId: userId,
        aadhaarNumber: aadhaarNumber,
        aadhaarFrontUrl: aadhaarFrontUrl,
        aadhaarBackUrl: aadhaarBackUrl,
        panNumber: panNumber,
        panPhotoUrl: panPhotoUrl,
        avatarUrl: avatarUrl,
      );

      // Update Truckers Table
      final truckerData = {
        'dl_number': dlNumber,
        'dl_expiry_date': dlExpiryDate?.toIso8601String().split('T').first,
        'dl_front_photo_url': dlFrontUrl,
        'dl_back_photo_url': dlBackUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final truckerResult = await databaseService.update(
        'truckers',
        userId,
        truckerData,
      );

      switch (truckerResult) {
        case Success():
          break;
        case Failure(debugMessage: final msg):
          throw Exception(msg ?? 'Failed to update trucker details');
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  Future<Map<String, dynamic>> loadExistingData() async {
    if (user == null) return const <String, dynamic>{};

    final profileResult = await databaseService.getSingle(
      'profiles',
      filterColumn: 'id',
      filterValue: user!.id,
    );
    final truckerResult = await databaseService.getSingle(
      'truckers',
      filterColumn: 'id',
      filterValue: user!.id,
    );

    return {
      'profile': switch (profileResult) {
        Success(data: final data) => data,
        Failure() => <String, dynamic>{},
      },
      'trucker': switch (truckerResult) {
        Success(data: final data) => data,
        Failure() => <String, dynamic>{},
      },
    };
  }
}

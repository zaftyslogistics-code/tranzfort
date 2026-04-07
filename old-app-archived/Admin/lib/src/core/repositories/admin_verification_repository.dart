import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'admin_audit_repository.dart';

final adminVerificationRepositoryProvider =
    Provider<AdminVerificationRepository>(
      (ref) => AdminVerificationRepository(ref),
    );

class AdminVerificationRepository {
  final Ref _ref;
  static const List<String> _profileVerificationQueueStatusesPreferred = <String>[
    'pending',
    'submitted',
    'under_review',
  ];
  static const List<String> _profileVerificationQueueStatusesLegacy = <String>[
    'pending',
  ];
  static const List<String> _truckVerificationQueueStatusesPreferred = <String>[
    'pending',
    'submitted',
    'under_review',
  ];
  static const List<String> _truckVerificationQueueStatusesLegacy = <String>[
    'pending',
  ];

  AdminVerificationRepository(this._ref);

  Future<VerificationQueues> fetchQueues() async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return const VerificationQueues();

    final client = Supabase.instance.client;

    final suppliers = await _loadSupplierOrTruckerQueue(
      client,
      role: 'supplier',
      type: VerificationEntityType.supplier,
    );
    final truckers = await _loadSupplierOrTruckerQueue(
      client,
      role: 'trucker',
      type: VerificationEntityType.trucker,
    );
    final trucks = await _loadTruckQueue(client);

    return VerificationQueues(
      suppliers: suppliers,
      truckers: truckers,
      trucks: trucks,
    );
  }

  Future<VerificationDetail?> fetchDetail({
    required VerificationEntityType type,
    required String id,
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return null;

    final client = Supabase.instance.client;

    try {
      if (type == VerificationEntityType.supplier ||
          type == VerificationEntityType.trucker) {
        final profile = await client
            .from('profiles')
            .select(
              'id,full_name,mobile,email,verification_status,verification_rejection_reason,updated_at,'
              'aadhaar_number,aadhaar_front_photo_url,aadhaar_back_photo_url,pan_number,pan_photo_url',
            )
            .eq('id', id)
            .maybeSingle();
        if (profile == null) return null;

        Map<String, dynamic>? roleData;
        if (type == VerificationEntityType.supplier) {
          roleData = await client
              .from('suppliers')
              .select(
                'company_name,gst_number,gst_photo_url,business_licence_number,business_licence_doc_url',
              )
              .eq('id', id)
              .maybeSingle();
        } else {
          roleData = await client
              .from('truckers')
              .select('dl_number,dl_front_photo_url,dl_back_photo_url')
              .eq('id', id)
              .maybeSingle();
        }

        final docs = <VerificationDocument>[
          VerificationDocument(
            label: 'Aadhaar Front',
            url: _asString(profile['aadhaar_front_photo_url']),
          ),
          VerificationDocument(
            label: 'Aadhaar Back',
            url: _asString(profile['aadhaar_back_photo_url']),
          ),
          VerificationDocument(
            label: 'PAN Card',
            url: _asString(profile['pan_photo_url']),
          ),
        ];

        final metadata = <String, String>{
          'Name': _asString(profile['full_name']),
          'Mobile': _asString(profile['mobile']),
          'Email': _asString(profile['email']),
          'Aadhaar': _asString(profile['aadhaar_number']),
          'PAN': _asString(profile['pan_number']),
        };

        if (type == VerificationEntityType.supplier) {
          docs.add(
            VerificationDocument(
              label: 'GST Document',
              url: _asString(roleData?['gst_photo_url']),
            ),
          );
          docs.add(
            VerificationDocument(
              label: 'Business Licence',
              url: _asString(roleData?['business_licence_doc_url']),
            ),
          );
          metadata['Company'] = _asString(roleData?['company_name']);
          metadata['GST'] = _asString(roleData?['gst_number']);
          metadata['Licence No.'] = _asString(
            roleData?['business_licence_number'],
          );
        } else {
          docs.add(
            VerificationDocument(
              label: 'DL Front',
              url: _asString(roleData?['dl_front_photo_url']),
            ),
          );
          docs.add(
            VerificationDocument(
              label: 'DL Back',
              url: _asString(roleData?['dl_back_photo_url']),
            ),
          );
          metadata['DL Number'] = _asString(roleData?['dl_number']);
        }

        return VerificationDetail(
          id: id,
          type: type,
          title: _asString(profile['full_name']),
          status: _asString(profile['verification_status']),
          rejectionReason: _asString(profile['verification_rejection_reason']),
          metadata: metadata,
          documents: docs,
        );
      }

      final truck = await client
          .from('trucks')
          .select(
            'id,owner_id,truck_number,body_type,tyres,capacity_tonnes,status,rejection_reason,created_at,rc_photo_url',
          )
          .eq('id', id)
          .maybeSingle();
      if (truck == null) return null;

      final ownerId = _asString(truck['owner_id']);
      String ownerName = ownerId;
      if (ownerId.isNotEmpty) {
        final ownerProfile = await client
            .from('profiles')
            .select('full_name,mobile')
            .eq('id', ownerId)
            .maybeSingle();
        ownerName = _asString(ownerProfile?['full_name']);
      }

      return VerificationDetail(
        id: id,
        type: type,
        title: _asString(truck['truck_number']),
        status: _asString(truck['status']),
        rejectionReason: _asString(truck['rejection_reason']),
        metadata: {
          'Truck Number': _asString(truck['truck_number']),
          'Owner': ownerName,
          'Body Type': _asString(truck['body_type']),
          'Tyres': _asString(truck['tyres']),
          'Capacity (tonnes)': _asString(truck['capacity_tonnes']),
        },
        documents: [
          VerificationDocument(
            label: 'RC Document',
            url: _asString(truck['rc_photo_url']),
          ),
        ],
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> approve({
    required VerificationEntityType type,
    required String id,
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      if (type == VerificationEntityType.truck) {
        await client
            .from('trucks')
            .update({
              'status': 'verified',
              'rejection_reason': null,
              'verified_at': now,
              'updated_at': now,
            })
            .eq('id', id);
      } else {
        await client
            .from('profiles')
            .update({
              'verification_status': 'verified',
              'verification_rejection_reason': null,
              'verified_at': now,
              'updated_at': now,
            })
            .eq('id', id);
      }

      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'verify',
            entityType: verificationTypePath(type),
            entityId: id,
            metadata: {'result': 'approved'},
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reject({
    required VerificationEntityType type,
    required String id,
    required String reason,
    List<String> reasonCodes = const [],
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      if (type == VerificationEntityType.truck) {
        await client
            .from('trucks')
            .update({
              'status': 'rejected',
              'rejection_reason': reason,
              'rejection_reason_codes': reasonCodes,
              'updated_at': now,
            })
            .eq('id', id);
      } else {
        await client
            .from('profiles')
            .update({
              'verification_status': 'rejected',
              'verification_rejection_reason': reason,
              'verification_rejection_reason_codes': reasonCodes,
              'updated_at': now,
            })
            .eq('id', id);
      }

      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'verify',
            entityType: verificationTypePath(type),
            entityId: id,
            metadata: {
              'result': 'rejected',
              'reason': reason,
              if (reasonCodes.isNotEmpty) 'reason_codes': reasonCodes,
            },
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<VerificationQueueItem>> _loadSupplierOrTruckerQueue(
    SupabaseClient client, {
    required String role,
    required VerificationEntityType type,
  }) async {
    try {
      final rows = await _queryProfileQueueRows(client, role: role);

      final ids = rows
          .map((row) => _asString(row['id']))
          .where((id) => id.isNotEmpty)
          .toList();

      final roleMetaById = <String, Map<String, dynamic>>{};
      if (ids.isNotEmpty) {
        if (type == VerificationEntityType.supplier) {
          final suppliers = await client
              .from('suppliers')
              .select('id,company_name')
              .inFilter('id', ids);
          for (final row in suppliers) {
            roleMetaById[_asString(row['id'])] = row;
          }
        } else if (type == VerificationEntityType.trucker) {
          final truckers = await client
              .from('truckers')
              .select('id,dl_number')
              .inFilter('id', ids);
          for (final row in truckers) {
            roleMetaById[_asString(row['id'])] = row;
          }
        }
      }

      return rows
          .map(
            (row) {
              final id = _asString(row['id']);
              final meta = roleMetaById[id] ?? const <String, dynamic>{};
              return VerificationQueueItem(
                id: id,
                type: type,
                primaryLabel: _asString(row['full_name']),
                secondaryLabel: _asString(row['mobile']),
                email: _asString(row['email']),
                companyName: _asString(meta['company_name']),
                dlNumber: _asString(meta['dl_number']),
                submittedAt: DateTime.tryParse(_asString(row['updated_at'])),
              );
            },
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<dynamic>> _queryProfileQueueRows(
    SupabaseClient client, {
    required String role,
  }) async {
    try {
      return await client
          .from('profiles')
          .select('id,full_name,mobile,email,updated_at')
          .eq('user_role_type', role)
          .inFilter(
            'verification_status',
            _profileVerificationQueueStatusesPreferred,
          )
          .order('updated_at', ascending: true);
    } on PostgrestException catch (error) {
      if (!_isVerificationStatusEnumMismatch(error)) rethrow;

      return client
          .from('profiles')
          .select('id,full_name,mobile,email,updated_at')
          .eq('user_role_type', role)
          .inFilter(
            'verification_status',
            _profileVerificationQueueStatusesLegacy,
          )
          .order('updated_at', ascending: true);
    }
  }

  bool _isVerificationStatusEnumMismatch(PostgrestException error) {
    return error.code == '22P02' &&
        error.message.toLowerCase().contains('verification_status');
  }

  Future<List<VerificationQueueItem>> _loadTruckQueue(
    SupabaseClient client,
  ) async {
    try {
      final rows = await _queryTruckQueueRows(client);

      final ownerIds = rows
          .map((row) => _asString(row['owner_id']))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final ownerNameById = <String, String>{};
      if (ownerIds.isNotEmpty) {
        final owners = await client
            .from('profiles')
            .select('id,full_name')
            .inFilter('id', ownerIds);
        for (final owner in owners) {
          ownerNameById[_asString(owner['id'])] = _asString(owner['full_name']);
        }
      }

      return rows
          .map(
            (row) {
              final ownerId = _asString(row['owner_id']);
              return VerificationQueueItem(
                id: _asString(row['id']),
                type: VerificationEntityType.truck,
                primaryLabel: _asString(row['truck_number']),
                secondaryLabel:
                    '${_asString(row['body_type'])} | ${_asString(row['tyres'])} tyres',
                ownerName: ownerNameById[ownerId] ?? ownerId,
                bodyType: _asString(row['body_type']),
                tyres: row['tyres'] is num ? (row['tyres'] as num).toInt() : 0,
                submittedAt: DateTime.tryParse(_asString(row['created_at'])),
              );
            },
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<dynamic>> _queryTruckQueueRows(SupabaseClient client) async {
    try {
      return await client
          .from('trucks')
          .select('id,owner_id,truck_number,body_type,tyres,created_at')
          .inFilter('status', _truckVerificationQueueStatusesPreferred)
          .order('created_at', ascending: true);
    } on PostgrestException catch (error) {
      if (!_isTruckStatusEnumMismatch(error)) rethrow;

      return client
          .from('trucks')
          .select('id,owner_id,truck_number,body_type,tyres,created_at')
          .inFilter('status', _truckVerificationQueueStatusesLegacy)
          .order('created_at', ascending: true);
    }
  }

  bool _isTruckStatusEnumMismatch(PostgrestException error) {
    return error.code == '22P02' && error.message.toLowerCase().contains('status');
  }
}

String _asString(dynamic value) => (value ?? '').toString();

enum VerificationEntityType { supplier, trucker, truck }

VerificationEntityType? verificationTypeFromPath(String value) {
  switch (value) {
    case 'supplier':
      return VerificationEntityType.supplier;
    case 'trucker':
      return VerificationEntityType.trucker;
    case 'truck':
      return VerificationEntityType.truck;
    default:
      return null;
  }
}

String verificationTypePath(VerificationEntityType type) {
  switch (type) {
    case VerificationEntityType.supplier:
      return 'supplier';
    case VerificationEntityType.trucker:
      return 'trucker';
    case VerificationEntityType.truck:
      return 'truck';
  }
}

String verificationTypeLabel(VerificationEntityType type) {
  switch (type) {
    case VerificationEntityType.supplier:
      return 'Supplier';
    case VerificationEntityType.trucker:
      return 'Trucker';
    case VerificationEntityType.truck:
      return 'Truck';
  }
}

class VerificationQueueItem {
  final String id;
  final VerificationEntityType type;
  final String primaryLabel;
  final String secondaryLabel;
  final String email;
  final String companyName;
  final String dlNumber;
  final String ownerName;
  final String bodyType;
  final int tyres;
  final DateTime? submittedAt;

  const VerificationQueueItem({
    required this.id,
    required this.type,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.email = '',
    this.companyName = '',
    this.dlNumber = '',
    this.ownerName = '',
    this.bodyType = '',
    this.tyres = 0,
    required this.submittedAt,
  });

  double get slaHoursRemaining {
    if (submittedAt == null) return 0;
    final elapsed =
        DateTime.now().toUtc().difference(submittedAt!).inMinutes / 60;
    return 24 - elapsed;
  }
}

class VerificationQueues {
  final List<VerificationQueueItem> suppliers;
  final List<VerificationQueueItem> truckers;
  final List<VerificationQueueItem> trucks;

  const VerificationQueues({
    this.suppliers = const [],
    this.truckers = const [],
    this.trucks = const [],
  });
}

class VerificationDocument {
  final String label;
  final String url;

  const VerificationDocument({required this.label, required this.url});
}

class VerificationDetail {
  final String id;
  final VerificationEntityType type;
  final String title;
  final String status;
  final String rejectionReason;
  final Map<String, String> metadata;
  final List<VerificationDocument> documents;

  const VerificationDetail({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.rejectionReason,
    required this.metadata,
    required this.documents,
  });
}

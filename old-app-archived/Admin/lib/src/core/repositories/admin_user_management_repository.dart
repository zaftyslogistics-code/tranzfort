import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'admin_audit_repository.dart';

final adminUserManagementRepositoryProvider =
    Provider<AdminUserManagementRepository>(
      (ref) => AdminUserManagementRepository(ref),
    );

class AdminUserManagementRepository {
  final Ref _ref;

  AdminUserManagementRepository(this._ref);

  Future<List<AdminUserListItem>> fetchUsers(UserListQuery query) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return const [];

    final client = Supabase.instance.client;

    try {
      dynamic req = client
          .from('profiles')
          .select(
            'id,full_name,mobile,email,user_role_type,verification_status,is_banned,ban_reason,created_at,last_login_at',
          );

      if (query.filter == UserFilter.supplier) {
        req = req.eq('user_role_type', 'supplier');
      } else if (query.filter == UserFilter.trucker) {
        req = req.eq('user_role_type', 'trucker');
      } else if (query.filter == UserFilter.banned) {
        req = req.eq('is_banned', true);
      }

      final rows = await req.order('created_at', ascending: false);
      final profiles = List<Map<String, dynamic>>.from(rows);
      final q = query.search.trim().toLowerCase();

      final filtered = q.isEmpty
          ? profiles
          : profiles.where((row) {
              final name = _asString(row['full_name']).toLowerCase();
              final mobile = _asString(row['mobile']).toLowerCase();
              final email = _asString(row['email']).toLowerCase();
              return name.contains(q) ||
                  mobile.contains(q) ||
                  email.contains(q);
            }).toList();

      final items = <AdminUserListItem>[];
      for (final row in filtered) {
        final role = _asString(row['user_role_type']);
        final userId = _asString(row['id']);

        final loadsCount = await _safeCount(() {
          if (role == 'supplier') {
            return client.from('loads').select('id').eq('supplier_id', userId);
          }
          if (role == 'trucker') {
            return client.from('trips').select('id').eq('trucker_id', userId);
          }
          return Future.value(<dynamic>[]);
        });

        items.add(
          AdminUserListItem(
            id: userId,
            fullName: _asString(row['full_name']),
            mobile: _asString(row['mobile']),
            email: _asString(row['email']),
            role: role,
            verificationStatus: _asString(row['verification_status']),
            isBanned: row['is_banned'] == true,
            banReason: _asString(row['ban_reason']),
            loadsCount: loadsCount,
          ),
        );
      }

      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<AdminUserDetail?> fetchUserDetail(String userId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return null;

    final client = Supabase.instance.client;

    try {
      final profile = await client
          .from('profiles')
          .select(
            'id,full_name,mobile,email,user_role_type,verification_status,verification_rejection_reason,created_at,last_login_at,is_banned,ban_reason,'
            'aadhaar_front_photo_url,aadhaar_back_photo_url,pan_photo_url',
          )
          .eq('id', userId)
          .maybeSingle();
      if (profile == null) return null;

      final role = _asString(profile['user_role_type']);

      Map<String, dynamic>? roleData;
      if (role == 'supplier') {
        roleData = await client
            .from('suppliers')
            .select(
              'company_name,gst_number,gst_photo_url,business_licence_number,business_licence_doc_url',
            )
            .eq('id', userId)
            .maybeSingle();
      } else if (role == 'trucker') {
        roleData = await client
            .from('truckers')
            .select(
              'dl_number,dl_front_photo_url,dl_back_photo_url,rating,completed_trips,super_trucker_status',
            )
            .eq('id', userId)
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

      if (role == 'supplier') {
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
      } else if (role == 'trucker') {
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
      }

      final recentItems = await _loadRecentItems(client, role, userId);

      return AdminUserDetail(
        profile: AdminUserListItem(
          id: _asString(profile['id']),
          fullName: _asString(profile['full_name']),
          mobile: _asString(profile['mobile']),
          email: _asString(profile['email']),
          role: role,
          verificationStatus: _asString(profile['verification_status']),
          isBanned: profile['is_banned'] == true,
          banReason: _asString(profile['ban_reason']),
          loadsCount: await _safeCount(() {
            if (role == 'supplier') {
              return client
                  .from('loads')
                  .select('id')
                  .eq('supplier_id', userId);
            }
            if (role == 'trucker') {
              return client.from('trips').select('id').eq('trucker_id', userId);
            }
            return Future.value(<dynamic>[]);
          }),
        ),
        roleMetadata: {
          if (role == 'supplier')
            'Company': _asString(roleData?['company_name']),
          if (role == 'supplier') 'GST': _asString(roleData?['gst_number']),
          if (role == 'trucker') 'DL Number': _asString(roleData?['dl_number']),
          if (role == 'trucker')
            'Rating': _asString(roleData?['rating']).isEmpty
                ? '-'
                : _asString(roleData?['rating']),
          if (role == 'trucker')
            'Completed Trips': _asString(roleData?['completed_trips']),
          if (role == 'trucker')
            'Super Trucker': _asString(roleData?['super_trucker_status']),
        },
        documents: docs,
        recentItems: recentItems,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> setBanStatus({
    required String userId,
    required bool banned,
    String? reason,
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;

    try {
      await client
          .from('profiles')
          .update({
            'is_banned': banned,
            'ban_reason': banned ? reason : null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);

      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: banned ? 'ban_user' : 'unban_user',
            entityType: 'profile',
            entityId: userId,
            metadata: {'reason': reason ?? ''},
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<AdminRecentItem>> _loadRecentItems(
    SupabaseClient client,
    String role,
    String userId,
  ) async {
    try {
      if (role == 'supplier') {
        final rows = await client
            .from('loads')
            .select('id,origin_city,dest_city,status,created_at')
            .eq('supplier_id', userId)
            .order('created_at', ascending: false)
            .limit(10);
        return rows
            .map(
              (row) => AdminRecentItem(
                id: _asString(row['id']),
                title:
                    '${_asString(row['origin_city'])} -> ${_asString(row['dest_city'])}',
                status: _asString(row['status']),
                createdAt: DateTime.tryParse(_asString(row['created_at'])),
              ),
            )
            .toList();
      }
      if (role == 'trucker') {
        final rows = await client
            .from('trips')
            .select('id,stage,created_at')
            .eq('trucker_id', userId)
            .order('created_at', ascending: false)
            .limit(10);
        return rows
            .map(
              (row) => AdminRecentItem(
                id: _asString(row['id']),
                title: 'Trip ${_asString(row['id']).substring(0, 8)}',
                status: _asString(row['stage']),
                createdAt: DateTime.tryParse(_asString(row['created_at'])),
              ),
            )
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<int> _safeCount(Future<List<dynamic>> Function() call) async {
    try {
      final rows = await call();
      return rows.length;
    } catch (_) {
      return 0;
    }
  }
}

String _asString(dynamic value) => (value ?? '').toString();

enum UserFilter { all, supplier, trucker, banned }

class UserListQuery {
  final UserFilter filter;
  final String search;

  const UserListQuery({required this.filter, required this.search});

  @override
  bool operator ==(Object other) {
    return other is UserListQuery &&
        other.filter == filter &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(filter, search);
}

class AdminUserListItem {
  final String id;
  final String fullName;
  final String mobile;
  final String email;
  final String role;
  final String verificationStatus;
  final bool isBanned;
  final String banReason;
  final int loadsCount;

  const AdminUserListItem({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.role,
    required this.verificationStatus,
    required this.isBanned,
    required this.banReason,
    required this.loadsCount,
  });
}

class AdminRecentItem {
  final String id;
  final String title;
  final String status;
  final DateTime? createdAt;

  const AdminRecentItem({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
  });
}

class VerificationDocument {
  final String label;
  final String url;

  const VerificationDocument({required this.label, required this.url});
}

class AdminUserDetail {
  final AdminUserListItem profile;
  final Map<String, String> roleMetadata;
  final List<VerificationDocument> documents;
  final List<AdminRecentItem> recentItems;

  const AdminUserDetail({
    required this.profile,
    required this.roleMetadata,
    required this.documents,
    required this.recentItems,
  });
}

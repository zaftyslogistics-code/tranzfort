import 'package:admin/src/core/config/supabase_config.dart';
import 'package:admin/src/core/repositories/admin_access_repository.dart';
import 'package:admin/src/core/repositories/admin_audit_repository.dart';
import 'package:admin/src/core/repositories/admin_management_repository.dart';
import 'package:admin/src/core/repositories/admin_super_ops_repository.dart';
import 'package:admin/src/core/repositories/splitted/super_ops_models.dart';
import 'package:admin/src/core/repositories/admin_support_repository.dart';
import 'package:admin/src/core/repositories/admin_user_management_repository.dart';
import 'package:admin/src/core/repositories/admin_verification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer createUnconfiguredContainer() {
    return ProviderContainer(
      overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
    );
  }

  group('Admin repositories short-circuit safely when Supabase is not configured', () {
    test('admin access + audit repositories no-op without throwing', () async {
      final container = createUnconfiguredContainer();
      addTearDown(container.dispose);

      final access = container.read(adminAccessRepositoryProvider);
      final audit = container.read(adminAuditRepositoryProvider);

      expect(await access.fetchCurrentAdmin(), isNull);
      await expectLater(
        audit.logAction(
          action: 'noop',
          entityType: 'test',
          entityId: 'id-1',
        ),
        completes,
      );
    });

    test('admin management repository returns fallback values', () async {
      final container = createUnconfiguredContainer();
      addTearDown(container.dispose);

      final repository = container.read(adminManagementRepositoryProvider);
      final inviteResult = await repository.inviteAdmin(
        fullName: 'Test Admin',
        email: 'test@example.com',
        role: AdminRole.supportAgent,
      );
      final actionResult = await repository.setAdminActive(
        adminId: 'admin-1',
        isActive: false,
      );

      expect(await repository.fetchAdmins(), isEmpty);
      expect(inviteResult.ok, isFalse);
      expect(inviteResult.message, contains('Supabase is not configured'));
      expect(actionResult.ok, isFalse);
      expect(actionResult.message, contains('Supabase is not configured'));
    });

    test('admin user management repository returns fallback values', () async {
      final container = createUnconfiguredContainer();
      addTearDown(container.dispose);

      final repository = container.read(adminUserManagementRepositoryProvider);

      expect(
        await repository.fetchUsers(
          const UserListQuery(filter: UserFilter.all, search: ''),
        ),
        isEmpty,
      );
      expect(await repository.fetchUserDetail('user-1'), isNull);
      expect(
        await repository.setBanStatus(
          userId: 'user-1',
          banned: true,
          reason: 'policy violation',
        ),
        isFalse,
      );
    });

    test('admin verification repository returns fallback values', () async {
      final container = createUnconfiguredContainer();
      addTearDown(container.dispose);

      final repository = container.read(adminVerificationRepositoryProvider);

      final queues = await repository.fetchQueues();
      expect(queues.suppliers, isEmpty);
      expect(queues.truckers, isEmpty);
      expect(queues.trucks, isEmpty);

      expect(
        await repository.fetchDetail(
          type: VerificationEntityType.supplier,
          id: 'supplier-1',
        ),
        isNull,
      );
      expect(
        await repository.approve(
          type: VerificationEntityType.truck,
          id: 'truck-1',
        ),
        isFalse,
      );
      expect(
        await repository.reject(
          type: VerificationEntityType.trucker,
          id: 'trucker-1',
          reason: 'invalid docs',
        ),
        isFalse,
      );
    });

    test('admin support repository returns fallback values', () async {
      final container = createUnconfiguredContainer();
      addTearDown(container.dispose);

      final repository = container.read(adminSupportRepositoryProvider);

      final counts = await repository.fetchCounts();
      expect(counts.open, 0);
      expect(counts.inProgress, 0);
      expect(counts.resolved, 0);

      expect(
        await repository.fetchQueue(
          const SupportTicketQueueQuery(
            status: SupportTicketStatus.open,
            search: '',
          ),
        ),
        isEmpty,
      );
      expect(await repository.fetchTicketDetail('ticket-1'), isNull);
      expect(await repository.assignToMe('ticket-1'), isFalse);
      expect(
        await repository.changePriority(
          ticketId: 'ticket-1',
          priority: SupportTicketPriority.high,
        ),
        isFalse,
      );
      expect(
        await repository.sendReply(ticketId: 'ticket-1', text: 'hello'),
        isFalse,
      );
      expect(
        await repository.resolveTicket(ticketId: 'ticket-1', notes: 'resolved'),
        isFalse,
      );
    });

    test('admin super ops repository returns fallback values', () async {
      final container = createUnconfiguredContainer();
      addTearDown(container.dispose);

      final repository = container.read(adminSuperOpsRepositoryProvider);

      final counts = await repository.fetchQueueCounts();
      expect(counts.requests, 0);
      expect(counts.dispatch, 0);
      expect(counts.podReview, 0);
      expect(counts.completed, 0);

      expect(
        await repository.fetchQueue(
          const SuperOpsQueueQuery(tab: SuperOpsTab.requests, search: ''),
        ),
        isEmpty,
      );
      expect(await repository.fetchLoadDetail('load-1'), isNull);
      expect(
        await repository.searchDispatchCandidates(
          loadId: 'load-1',
          requiredTruckType: '',
        ),
        isEmpty,
      );
      expect(await repository.acceptRequest('load-1'), isFalse);
      expect(await repository.rejectRequest('load-1'), isFalse);
      expect(
        await repository.forceAssign(
          loadId: 'load-1',
          truckerId: 'trucker-1',
          truckId: 'truck-1',
        ),
        isFalse,
      );
      expect(await repository.confirmPayout('load-1'), isFalse);
      expect(await repository.disputePod('load-1'), isFalse);
      expect(await repository.fetchSuppliers(), isEmpty);
      expect(
        await repository.postLoadOnBehalf(
          SuperOpsPostLoadPayload(
            supplierId: 'supplier-1',
            originCity: 'Mumbai',
            originState: 'MH',
            destCity: 'Pune',
            destState: 'MH',
            material: 'Steel',
            weightTonnes: 12,
            requiredTruckType: 'open_body',
            trucksNeeded: 1,
            price: 15000,
            priceType: 'fixed',
            advancePercentage: 20,
            pickupDate: DateTime(2026, 2, 27),
          ),
        ),
        isFalse,
      );
    });
  });
}

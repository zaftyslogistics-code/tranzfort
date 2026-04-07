import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/utils/coordinate_utils.dart';
import '../../../core/utils/error_logger.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/screen_scroll_container.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../../shared/utils/verification_status_utils.dart';
import '../../chat/providers/chat_providers.dart';
import '../providers/marketplace_providers.dart';
import '../../../core/error/result.dart';
import '../utils/load_pricing.dart';
import '../widgets/rich_load_card.dart';

class LoadDetailScreen extends ConsumerWidget {
  final String loadId;

  const LoadDetailScreen({super.key, required this.loadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(loadDetailProvider(loadId));
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loadDetailTitle)),
      body: detailAsync.when(
        data: (detail) {
          final load = (detail['load'] as Map<String, dynamic>? ?? const {});
          if (load.isEmpty) {
            return Center(child: Text(l10n.loadNotFound));
          }

          final children = (detail['children'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();
          final tripCost =
              (detail['trip_cost'] as Map<String, dynamic>? ?? const {});
          final destination = CoordinateUtils.parseLatLngFromMap(
            load,
            latKey: 'dest_lat',
            lngKey: 'dest_lng',
          );
          final routeMeta = destination == null
              ? null
              : ref.watch(loadRouteMetaProvider(destination)).valueOrNull;
          final weather = destination == null
              ? null
              : ref.watch(loadDestinationWeatherProvider(destination)).valueOrNull;

          final role = (profileAsync.value?['user_role_type'] ?? '').toString();
          final isSupplier = role == 'supplier';
          final supplier = (load['supplier'] as Map<String, dynamic>? ?? const {});
          final supplierProfile =
              (supplier['profiles'] as Map<String, dynamic>? ?? const {});
          final supplierName =
              (supplier['company_name'] ?? supplierProfile['full_name'] ?? '')
                  .toString();
          final supplierMobile =
              (supplierProfile['mobile'] ?? '').toString().trim();
          final headlinePrice = _priceSummary(load);

          return ScreenScrollContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TtsAnnounce(
                  text: l10n.loadDetailScreenTtsContext(
                    (load['origin_city'] ?? l10n.findLoadsAny).toString(),
                    (load['dest_city'] ?? l10n.findLoadsAny).toString(),
                    (load['material'] ?? l10n.findLoadsAnyMaterial).toString(),
                    (load['weight_tonnes'] ?? '-').toString(),
                    headlinePrice,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${load['origin_city']} → ${load['dest_city']}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${load['material']} · ${load['weight_tonnes']}T · $headlinePrice',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                RichLoadCard(
                  load: load,
                  showActions: false,
                  driveTimeMinutes: routeMeta?['driveTimeMinutes'] as int?,
                  tollEstimate: CoordinateUtils.parseDouble(routeMeta?['tollEstimate']),
                  fuelEstimate: CoordinateUtils.parseDouble(routeMeta?['fuelEstimate']),
                  weatherSummary: weather?.summary,
                  weatherTempC: weather?.temperatureC,
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 180,
                    child: OutlineButton(
                      label: l10n.viewRouteMap,
                      onPressed: () => context.push('/route-preview/$loadId'),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _TripCostBreakdown(tripCost: tripCost),
                const SizedBox(height: AppSpacing.md),
                if (isSupplier)
                  _SupplierSection(
                    parentLoadId: (load['parent_load_id'] ?? load['id'])
                        .toString(),
                    children: children,
                  )
                else
                  _TruckerActions(
                    parentLoadId: (load['parent_load_id'] ?? load['id'])
                        .toString(),
                    supplierId: (load['supplier_id'] ?? supplier['id'] ?? '')
                        .toString(),
                    supplierName: supplierName,
                    supplierMobile: supplierMobile,
                  ),
              ],
            ),
          );
        },
        loading: () => SkeletonLoader.list(
          count: 3,
          itemHeight: 128,
        ),
        error: (error, _) => Center(child: Text(l10n.loadDetailLoadError)),
      ),
    );
  }

  String _priceSummary(Map<String, dynamic> load) {
    final price = LoadPricing.priceValue(load['price']);
    if (price == null) {
      return '₹-';
    }
    final formatted = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(price);
    if (LoadPricing.isPerTon(load['price_type'])) {
      return '$formatted/T';
    }
    return formatted;
  }
}

class _TripCostBreakdown extends StatelessWidget {
  final Map<String, dynamic> tripCost;

  const _TripCostBreakdown({required this.tripCost});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (tripCost.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: AppColors.neutralLight),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.cardPadding),
          child: Text(l10n.loadDetailTripCostUnavailable),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.neutralLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.loadDetailTripCostBreakdown,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: IntrinsicColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(l10n.loadDetailTripCostDiesel),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text('₹${(tripCost['diesel'] as num).toStringAsFixed(0)}'),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Text(l10n.loadDetailTripCostTolls),
                    Text('₹${(tripCost['toll'] as num).toStringAsFixed(0)}'),
                  ],
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: IntrinsicColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    Text(
                      l10n.loadDetailTripCostTotal,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary),
                    ),
                    Text(
                      '₹${(tripCost['total'] as num).toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.loadDetailTripCostMileage}: ${(tripCost['mileage'] as num).toStringAsFixed(1)} km/L',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierSection extends ConsumerWidget {
  final String parentLoadId;
  final List<Map<String, dynamic>> children;

  const _SupplierSection({required this.parentLoadId, required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pending = children
        .where((item) => item['status'] == 'pending_approval')
        .toList();
    final inTransit = children
        .where((item) => item['status'] == 'in_transit')
        .toList();
    final podUploaded = children
        .where((item) => item['status'] == 'pod_uploaded')
        .toList();
    final delivered = children
        .where(
          (item) => item['status'] == 'completed' || item['status'] == 'booked',
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.loadDetailPendingApproval,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${pending.length}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...pending.map(
          (booking) => _BookingCard(
            booking: booking,
            onApprove: () async {
              final success = await ref
                  .read(loadDetailActionProvider.notifier)
                  .approveBooking(booking['id'].toString(), parentLoadId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? l10n.loadDetailBookingApproved : l10n.loadDetailApproveFailed),
                ),
              );
            },
            onReject: () async {
              final success = await ref
                  .read(loadDetailActionProvider.notifier)
                  .rejectBooking(booking['id'].toString(), parentLoadId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? l10n.loadDetailBookingRejected : l10n.loadDetailRejectFailed),
                ),
              );
            },
          ),
        ),
        if (pending.isEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.loadDetailNoPendingBookings, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary)),
        ],
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: l10n.loadDetailInTransit,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${inTransit.length}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...inTransit.map(
          (item) => _BookingInfoCard(
            title:
                '${l10n.tripSnapshotTruck}: ${item['booking_truck_snapshot']?['truck_number'] ?? '-'}',
            subtitle: l10n.loadDetailTripInTransit,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: l10n.loadDetailPodUploaded,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${podUploaded.length}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...podUploaded.map(
          (item) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              side: const BorderSide(color: AppColors.neutralLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.tripSnapshotTruck}: ${item['booking_truck_snapshot']?['truck_number'] ?? '-'}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: l10n.loadDetailConfirmDelivery,
                    color: AppColors.success,
                    onPressed: () async {
                      final success = await ref
                          .read(loadDetailActionProvider.notifier)
                          .confirmDelivery(item['id'].toString(), parentLoadId);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? l10n.loadDetailDeliveryConfirmed : l10n.loadDetailDeliveryConfirmFailed),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: l10n.loadDetailDelivered,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${delivered.length}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...delivered.map(
          (item) => _BookingInfoCard(
            title:
                '${l10n.tripSnapshotTruck}: ${item['booking_truck_snapshot']?['truck_number'] ?? '-'}',
            subtitle: '${l10n.loadDetailStatusPrefix}: ${item['status']}',
          ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _BookingCard({
    required this.booking,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final truckSnapshot =
        booking['booking_truck_snapshot'] as Map<String, dynamic>? ?? const {};
    final truckNumber = (truckSnapshot['truck_number'] ?? '-').toString();
    final truckMeta =
        '${truckSnapshot['body_type'] ?? '-'} · ${truckSnapshot['tyres'] ?? '-'} tyres · ${truckSnapshot['capacity_tonnes'] ?? '-'}T';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.neutralLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.neutralLight,
                  radius: 20,
                  child: Icon(Icons.local_shipping, color: AppColors.textSecondary, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(truckNumber, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(truckMeta, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                StatusBadge(
                  label: l10n.profileVerifiedChip,
                  backgroundColor: AppColors.successTint,
                  textColor: AppColors.success,
                  icon: Icons.verified,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: l10n.loadDetailApproveAction,
                    color: AppColors.success,
                    onPressed: onApprove,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlineButton(
                    label: l10n.loadDetailRejectAction,
                    onPressed: onReject,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TruckerActions extends ConsumerWidget {
  final String parentLoadId;
  final String supplierId;
  final String supplierName;
  final String supplierMobile;

  const _TruckerActions({
    required this.parentLoadId,
    required this.supplierId,
    required this.supplierName,
    required this.supplierMobile,
  });

  Future<void> _callSupplier(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final phone = supplierMobile.replaceAll(RegExp(r'\s+'), '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.callSupplierUnavailable)),
      );
      return;
    }

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.callSupplierLaunchFailed)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasSupplierPhone = supplierMobile.trim().isNotEmpty;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.neutralLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.actionsTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (supplierName.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.postedByPrefix} $supplierName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: l10n.chatBookThisLoad,
              color: AppColors.success,
              onPressed: () async {
                final success = await ref
                    .read(loadActionProvider.notifier)
                    .bookLoad(parentLoadId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? l10n.loadBookedAwaitingApproval
                          : l10n.bookingFailedTryAgain,
                    ),
                  ),
                );
                await ref
                    .read(ttsServiceProvider)
                    .speak(success ? l10n.loadBookTtsSuccess : l10n.loadBookTtsFailure);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlineButton(
                    label: l10n.chatWithSupplier,
                    onPressed: () async {
                      ref.invalidate(userProfileProvider);
                      final profile = await ref.read(userProfileProvider.future);
                      final verificationStatus = normalizeVerificationStatus(
                        profile?['verification_status'],
                      );
                      ErrorLogger.logDebug(
                        'Trucker chat initiation requested',
                        context: {
                          'module': 'load_detail_chat',
                          'loadId': parentLoadId,
                          'userId': profile?['id'],
                          'role': profile?['user_role_type'],
                          'rawVerificationStatus': profile?['verification_status'],
                          'normalizedVerificationStatus': verificationStatus,
                          'supplierId': supplierId,
                          'supplierName': supplierName,
                        },
                      );
                      if (verificationStatus != 'verified') {
                        ErrorLogger.logWarning(
                          'Trucker chat blocked by verification gate',
                          context: {
                            'module': 'load_detail_chat',
                            'loadId': parentLoadId,
                            'userId': profile?['id'],
                            'rawVerificationStatus': profile?['verification_status'],
                            'normalizedVerificationStatus': verificationStatus,
                          },
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.completeTruckerVerificationToChat),
                            action: SnackBarAction(
                              label: l10n.verifyAction,
                              onPressed: () {
                                context.push('/verification/trucker');
                              },
                            ),
                          ),
                        );
                        return;
                      }

                      final userId = ref
                          .read(authSessionProvider)
                          .value
                          ?.session
                          ?.user
                          .id;
                      if (userId == null || supplierId.isEmpty) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.couldNotStartChatRetry)),
                        );
                        return;
                      }

                      final result = await ref
                          .read(chatRepositoryProvider)
                          .getOrCreateConversation(
                            loadId: parentLoadId,
                            supplierId: supplierId,
                            truckerId: userId,
                          );

                      if (!context.mounted) return;

                      switch (result) {
                        case Success(data: final conversation):
                          final conversationId = (conversation['id'] ?? '')
                              .toString();
                          ErrorLogger.logDebug(
                            'Trucker chat conversation resolved',
                            context: {
                              'module': 'load_detail_chat',
                              'loadId': parentLoadId,
                              'supplierId': supplierId,
                              'conversationId': conversationId,
                            },
                          );
                          if (conversationId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.couldNotStartChatRetry),
                              ),
                            );
                            return;
                          }
                          context.push('/chat/$conversationId');
                        case Failure(debugMessage: final msg, type: final type):
                          ErrorLogger.logWarning(
                            'Trucker chat conversation failed',
                            context: {
                              'module': 'load_detail_chat',
                              'loadId': parentLoadId,
                              'supplierId': supplierId,
                              'failureType': type,
                              'debugMessage': msg,
                            },
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.couldNotStartChatRetry)),
                          );
                      }
                    },
                  ),
                ),
                if (hasSupplierPhone) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlineButton(
                      label: l10n.callSupplierAction,
                      onPressed: () => _callSupplier(context),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _BookingInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BookingInfoCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.neutralLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.xs,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

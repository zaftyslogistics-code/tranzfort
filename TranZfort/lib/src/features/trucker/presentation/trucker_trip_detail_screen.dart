import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/services/maps_launcher_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../reviews/utils/review_trigger_helper.dart';
import '../../communication/data/chat_repository.dart';
import '../../../features/shell/presentation/shell_components.dart';
import '../../support/providers/support_compose_providers.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/status_components.dart';
import '../data/trucker_profile_repository.dart';
import '../providers/trucker_providers.dart';
import '../data/trucker_trip_repository.dart';
import '../providers/trucker_trip_action_provider.dart';
import '../providers/trucker_trip_detail_provider.dart';
import '../providers/trucker_trip_rating_provider.dart';

part 'trucker_trip_detail_screen_sections.dart';
part 'trucker_trip_detail_screen_rating.dart';
part 'trucker_trip_detail_screen_chat.dart';
part 'trucker_trip_detail_screen_helpers.dart';

class TruckerTripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TruckerTripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(truckerTripDetailProvider(tripId));
    final detail = state.detail;

    return DetailPageScaffold(
      title: l10n.truckerTripDetailTitle,
      children: [
        if (state.isLoading) const LoadingShimmer(height: 120, itemCount: 4),
        if (!state.isLoading && state.failure is NotFoundFailure && detail == null)
          EmptyStateView(
            icon: Icons.alt_route_outlined,
            title: l10n.truckerTripDetailNotFoundTitle,
            subtitle: l10n.truckerTripDetailNotFoundSubtitle,
            actionLabel: l10n.truckerTripDetailBackToTripsAction,
            onAction: () => context.go(AppRoutes.tripsPath),
          ),
        if (!state.isLoading && state.failure != null && detail == null)
          WarningBlock(
            title: l10n.truckerTripDetailLoadFailureTitle,
            message: l10n.truckerTripDetailLoadFailureMessage,
            action: OutlineButton(
              label: l10n.commonRetry,
              onPressed: () => ref.read(truckerTripDetailProvider(tripId).notifier).load(),
            ),
          ),
        if (!state.isLoading && detail != null) _TruckerTripDetailBody(detail: detail),
      ],
    );
  }
 }

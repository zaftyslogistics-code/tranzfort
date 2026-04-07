import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/maps_config.dart';
import '../../../../core/repositories/load_repository.dart';
import '../../../../core/services/google_routes_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/osrm_service.dart';
import '../../../../core/services/trip_costing_service.dart';
import '../../../auth/providers/auth_providers.dart';

// Re-export commonly used auth providers for convenience
export '../../../auth/providers/auth_providers.dart' show 
    authSessionProvider, 
    userProfileProvider,
    userRoleProvider,
    supabaseClientProvider;

// Shared providers used across multiple marketplace provider files

final mapsConfigProvider = Provider<MapsConfig>((ref) {
  return MapsConfig.fromEnvironment();
});

final loadRepositoryProvider = Provider<LoadRepository>((ref) {
  return LoadRepository(ref.watch(supabaseClientProvider));
});

final marketplaceLocationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

final googleRoutesServiceProvider = Provider<GoogleRoutesService>((ref) {
  return GoogleRoutesService(ref.watch(mapsConfigProvider), OsrmService());
});

final osrmServiceProvider = Provider<OsrmService>((ref) {
  return OsrmService();
});

final tripCostingServiceProvider = Provider<TripCostingService>((ref) {
  return TripCostingService();
});

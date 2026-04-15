part of 'app_router.dart';

String? Function(BuildContext, GoRouterState) _createRedirectHandler(Ref ref) {
  return (context, state) {
    final path = state.uri.path;
    final isPublicProfileRoute = path.startsWith('/profile/');
    final isPublicRoute = path == AppRoutes.splashPath ||
        path == AppRoutes.authPath ||
        path == AppRoutes.authPasswordPath ||
        isPublicProfileRoute;
    final authStateAsync = ref.read(authStateProvider);
    final authState = ref.read(currentAuthStateProvider);
    final hasSession = authState.hasSession;
    final isBannedRoute = path == AppRoutes.bannedPath;
    final isDeleteAccountRoute = path == AppRoutes.deleteAccountPath;
    final isOnboardingRoute = path == AppRoutes.onboardingPath ||
        path == AppRoutes.onboardingRolePath ||
        path == AppRoutes.onboardingProfilePath;
    final isSupplier = authState.role == AppUserRole.supplier;
    final isRestrictedAccount = authState.isBanned;

    if (hasSession && !authState.isResolved) {
      if (authStateAsync.isLoading) {
        if (path == AppRoutes.splashPath || isPublicRoute || isOnboardingRoute || isBannedRoute) {
          return null;
        }
        return AppRoutes.splashPath;
      }
      return null;
    }

    if (!hasSession && !isPublicRoute) {
      return AppRoutes.authPath;
    }

    if (!hasSession && path == AppRoutes.splashPath) {
      return AppRoutes.authPath;
    }

    if (!hasSession) {
      return null;
    }

    if (path == AppRoutes.onboardingPath) {
      if (hasSession && !authState.isResolved) {
        return null;
      }

      final profile = authState.profile;
      final hasKnownRole = (profile?.hasRole ?? false) || authState.role != AppUserRole.unknown;
      if (!hasKnownRole) {
        return AppRoutes.onboardingRolePath;
      }

      if (!authState.isProfileComplete) {
        return AppRoutes.onboardingProfilePath;
      }

      return isSupplier ? AppRoutes.supplierDashboardPath : AppRoutes.truckerDashboardPath;
    }

    if (authState.isDeactivated && !isDeleteAccountRoute) {
      return AppRoutes.deleteAccountPath;
    }

    if (isRestrictedAccount && !isBannedRoute) {
      return AppRoutes.bannedPath;
    }

    if (!isRestrictedAccount && isBannedRoute) {
      return authState.role == AppUserRole.supplier
          ? AppRoutes.supplierDashboardPath
          : AppRoutes.truckerDashboardPath;
    }

    if (!authState.isProfileComplete && !isOnboardingRoute && !isPublicRoute) {
      return AppRoutes.onboardingPath;
    }

    if (authState.isProfileComplete && isOnboardingRoute) {
      return authState.role == AppUserRole.supplier
          ? AppRoutes.supplierDashboardPath
          : AppRoutes.truckerDashboardPath;
    }

    if (path == AppRoutes.authPath) {
      if (isRestrictedAccount) {
        return AppRoutes.bannedPath;
      }

      if (authState.isDeactivated) {
        return AppRoutes.deleteAccountPath;
      }

      if (!authState.isProfileComplete) {
        return AppRoutes.onboardingPath;
      }

      return isSupplier ? AppRoutes.supplierDashboardPath : AppRoutes.truckerDashboardPath;
    }

    if (isSupplier) {
      if (path == AppRoutes.dashboardPath) {
        return AppRoutes.supplierDashboardPath;
      }

      if (path == AppRoutes.findLoadsPath) {
        return AppRoutes.myLoadsPath;
      }

      if (path == AppRoutes.tripsPath) {
        return AppRoutes.supplierTripsPath;
      }

      if (path == AppRoutes.fleetPath) {
        return AppRoutes.supplierDashboardPath;
      }
    } else {
      if (path == AppRoutes.dashboardPath) {
        return AppRoutes.truckerDashboardPath;
      }

      if (path == AppRoutes.supplierDashboardPath) {
        return AppRoutes.truckerDashboardPath;
      }

      if (path == AppRoutes.truckerDashboardPath) {
        return null;
      }

      if (path == AppRoutes.myLoadsPath) {
        return AppRoutes.findLoadsPath;
      }

      if (path == AppRoutes.supplierTripsPath) {
        return AppRoutes.tripsPath;
      }
    }

    return null;
  };
}

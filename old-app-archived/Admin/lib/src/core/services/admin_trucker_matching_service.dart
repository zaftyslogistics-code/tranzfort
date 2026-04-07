import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/splitted/super_ops_models.dart';

final adminTruckerMatchingServiceProvider =
    Provider<AdminTruckerMatchingService>((ref) {
      return const AdminTruckerMatchingService();
    });

class AdminTruckerMatchingService {
  const AdminTruckerMatchingService();

  List<DispatchTruckerCandidate> rankByProximity({
    required List<DispatchTruckerCandidate> candidates,
    required double? originLat,
    required double? originLng,
  }) {
    if (originLat == null || originLng == null) {
      final fallback = [...candidates];
      fallback.sort(_fallbackCompare);
      return fallback;
    }

    final ranked = candidates.map((candidate) {
      final lat = candidate.lastKnownLat;
      final lng = candidate.lastKnownLng;
      final distance = (lat == null || lng == null)
          ? null
          : _haversineKm(originLat, originLng, lat, lng);
      return candidate.copyWith(distanceKm: distance);
    }).toList(growable: false);

    ranked.sort((a, b) {
      final aDistance = a.distanceKm;
      final bDistance = b.distanceKm;
      if (aDistance != null && bDistance != null) {
        final cmp = aDistance.compareTo(bDistance);
        if (cmp != 0) return cmp;
      } else if (aDistance != null) {
        return -1;
      } else if (bDistance != null) {
        return 1;
      }
      return _fallbackCompare(a, b);
    });

    return ranked;
  }

  int _fallbackCompare(DispatchTruckerCandidate a, DispatchTruckerCandidate b) {
    final ratingCmp = b.rating.compareTo(a.rating);
    if (ratingCmp != 0) return ratingCmp;
    return b.completedTrips.compareTo(a.completedTrips);
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        _sinHalfSquared(dLat) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            _sinHalfSquared(dLon);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * 0.017453292519943295;

  double _sinHalfSquared(double angle) {
    final value = math.sin(angle / 2);
    return value * value;
  }
}

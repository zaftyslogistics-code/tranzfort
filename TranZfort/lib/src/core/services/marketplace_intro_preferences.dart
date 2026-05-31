import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MarketplaceIntroSurface {
  truckerFindLoads,
  supplierPostLoad,
}

class MarketplaceIntroPreferences {
  static const String _truckerFindLoadsKey = 'marketplace_intro_seen_trucker_find_loads';
  static const String _supplierPostLoadKey = 'marketplace_intro_seen_supplier_post_load';

  Future<bool> shouldShow(MarketplaceIntroSurface surface) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(surface);
    return !(prefs.getBool(key) ?? false);
  }

  Future<void> markSeen(MarketplaceIntroSurface surface) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(surface), true);
  }

  String _keyFor(MarketplaceIntroSurface surface) {
    return switch (surface) {
      MarketplaceIntroSurface.truckerFindLoads => _truckerFindLoadsKey,
      MarketplaceIntroSurface.supplierPostLoad => _supplierPostLoadKey,
    };
  }
}

final marketplaceIntroPreferencesProvider = Provider<MarketplaceIntroPreferences>(
  (ref) => MarketplaceIntroPreferences(),
);

final marketplaceIntroVisibleProvider = FutureProvider.family<bool, MarketplaceIntroSurface>(
  (ref, surface) => ref.read(marketplaceIntroPreferencesProvider).shouldShow(surface),
);

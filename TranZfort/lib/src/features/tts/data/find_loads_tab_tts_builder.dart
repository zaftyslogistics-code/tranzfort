import '../../../l10n/tts_localizations.dart';
import '../../trucker/providers/find_loads_provider.dart';

/// Spoken intro when the trucker opens the Find Loads tab.
class FindLoadsTabTtsBuilder {
  const FindLoadsTabTtsBuilder();

  String build({
    required FindLoadsState state,
    required TtsLocalizations tts,
  }) {
    final count = state.totalCount ?? state.loads.length;
    if (state.filters.hasActiveFilters || state.selectedTab == FindLoadsTab.superLoads) {
      return tts.ttsFindLoadsFilteredIntro('$count');
    }
    return tts.ttsFindLoadsIntro('$count');
  }
}

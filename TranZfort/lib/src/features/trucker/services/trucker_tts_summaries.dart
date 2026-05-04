import '../../../core/services/tts_screen_summary_model.dart';

/// TTS summaries for trucker screens.
/// Provides Hindi and English summaries for key trucker workflow screens.
class TruckerTtsSummaries {
  TruckerTtsSummaries._();

  static const String _marketplaceScreenId = 'trucker_marketplace';
  static const String _loadDetailScreenId = 'trucker_load_detail';
  static const String _tripDetailScreenId = 'trucker_trip_detail';
  static const String _fleetScreenId = 'trucker_fleet';

  /// Get TTS summary for the given screen ID and language code.
  static TtsScreenSummary? getSummary(String screenId, String languageCode) {
    return _summaries['$screenId:$languageCode'];
  }

  static final Map<String, TtsScreenSummary> _summaries = {
    // Marketplace Screen
    '$_marketplaceScreenId:hi-IN': const TtsScreenSummary(
      screenId: _marketplaceScreenId,
      summaryText: 'बाज़ार की लोड देखें',
      priority: TtsSummaryPriority.normal,
      languageCode: 'hi-IN',
    ),
    '$_marketplaceScreenId:en-GB': const TtsScreenSummary(
      screenId: _marketplaceScreenId,
      summaryText: 'Browse available loads',
      priority: TtsSummaryPriority.normal,
      languageCode: 'en-GB',
    ),

    // Load Detail Screen
    '$_loadDetailScreenId:hi-IN': const TtsScreenSummary(
      screenId: _loadDetailScreenId,
      summaryText: 'लोड विवरण देखें',
      priority: TtsSummaryPriority.high,
      languageCode: 'hi-IN',
    ),
    '$_loadDetailScreenId:en-GB': const TtsScreenSummary(
      screenId: _loadDetailScreenId,
      summaryText: 'View load details',
      priority: TtsSummaryPriority.high,
      languageCode: 'en-GB',
    ),

    // Trip Detail Screen
    '$_tripDetailScreenId:hi-IN': const TtsScreenSummary(
      screenId: _tripDetailScreenId,
      summaryText: 'यात्रा विवरण देखें',
      priority: TtsSummaryPriority.high,
      languageCode: 'hi-IN',
    ),
    '$_tripDetailScreenId:en-GB': const TtsScreenSummary(
      screenId: _tripDetailScreenId,
      summaryText: 'View trip details',
      priority: TtsSummaryPriority.high,
      languageCode: 'en-GB',
    ),

    // Fleet Screen
    '$_fleetScreenId:hi-IN': const TtsScreenSummary(
      screenId: _fleetScreenId,
      summaryText: 'अपने ट्रक प्रबंधित करें',
      priority: TtsSummaryPriority.normal,
      languageCode: 'hi-IN',
    ),
    '$_fleetScreenId:en-GB': const TtsScreenSummary(
      screenId: _fleetScreenId,
      summaryText: 'Manage your trucks',
      priority: TtsSummaryPriority.normal,
      languageCode: 'en-GB',
    ),
  };
}

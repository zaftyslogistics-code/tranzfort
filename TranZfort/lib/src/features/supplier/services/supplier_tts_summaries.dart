import '../../../core/services/tts_screen_summary_model.dart';

/// TTS summaries for supplier screens.
/// Provides Hindi and English summaries for key supplier workflow screens.
class SupplierTtsSummaries {
  SupplierTtsSummaries._();

  static const String _dashboardScreenId = 'supplier_dashboard';
  static const String _postLoadScreenId = 'supplier_post_load';
  static const String _loadDetailScreenId = 'supplier_load_detail';
  static const String _tripDetailScreenId = 'supplier_trip_detail';

  /// Get TTS summary for the given screen ID and language code.
  static TtsScreenSummary? getSummary(String screenId, String languageCode) {
    return _summaries['$screenId:$languageCode'];
  }

  static final Map<String, TtsScreenSummary> _summaries = {
    // Dashboard Screen
    '$_dashboardScreenId:hi-IN': const TtsScreenSummary(
      screenId: _dashboardScreenId,
      summaryText: 'डैशबोर्ड देखें',
      priority: TtsSummaryPriority.normal,
      languageCode: 'hi-IN',
    ),
    '$_dashboardScreenId:en-GB': const TtsScreenSummary(
      screenId: _dashboardScreenId,
      summaryText: 'View dashboard',
      priority: TtsSummaryPriority.normal,
      languageCode: 'en-GB',
    ),

    // Post Load Screen
    '$_postLoadScreenId:hi-IN': const TtsScreenSummary(
      screenId: _postLoadScreenId,
      summaryText: 'नई लोड पोस्ट करें',
      priority: TtsSummaryPriority.high,
      languageCode: 'hi-IN',
    ),
    '$_postLoadScreenId:en-GB': const TtsScreenSummary(
      screenId: _postLoadScreenId,
      summaryText: 'Post new load',
      priority: TtsSummaryPriority.high,
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
  };
}

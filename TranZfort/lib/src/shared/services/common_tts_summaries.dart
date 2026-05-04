import '../../core/services/tts_screen_summary_model.dart';

/// TTS summaries for common/shared screens.
/// Provides Hindi and English summaries for screens used by both truckers and suppliers.
class CommonTtsSummaries {
  CommonTtsSummaries._();

  static const String _notificationsScreenId = 'notifications';
  static const String _chatScreenId = 'chat';
  static const String _profileScreenId = 'profile';
  static const String _settingsScreenId = 'settings';

  /// Get TTS summary for the given screen ID and language code.
  static TtsScreenSummary? getSummary(String screenId, String languageCode) {
    return _summaries['$screenId:$languageCode'];
  }

  static final Map<String, TtsScreenSummary> _summaries = {
    // Notifications Screen
    '$_notificationsScreenId:hi-IN': const TtsScreenSummary(
      screenId: _notificationsScreenId,
      summaryText: 'सूचनाएं',
      priority: TtsSummaryPriority.normal,
      languageCode: 'hi-IN',
    ),
    '$_notificationsScreenId:en-GB': const TtsScreenSummary(
      screenId: _notificationsScreenId,
      summaryText: 'Notifications',
      priority: TtsSummaryPriority.normal,
      languageCode: 'en-GB',
    ),

    // Chat Screen
    '$_chatScreenId:hi-IN': const TtsScreenSummary(
      screenId: _chatScreenId,
      summaryText: 'चैट',
      priority: TtsSummaryPriority.high,
      languageCode: 'hi-IN',
    ),
    '$_chatScreenId:en-GB': const TtsScreenSummary(
      screenId: _chatScreenId,
      summaryText: 'Chat',
      priority: TtsSummaryPriority.high,
      languageCode: 'en-GB',
    ),

    // Profile Screen
    '$_profileScreenId:hi-IN': const TtsScreenSummary(
      screenId: _profileScreenId,
      summaryText: 'आपकी प्रोफाइल',
      priority: TtsSummaryPriority.normal,
      languageCode: 'hi-IN',
    ),
    '$_profileScreenId:en-GB': const TtsScreenSummary(
      screenId: _profileScreenId,
      summaryText: 'Your profile',
      priority: TtsSummaryPriority.normal,
      languageCode: 'en-GB',
    ),

    // Settings Screen
    '$_settingsScreenId:hi-IN': const TtsScreenSummary(
      screenId: _settingsScreenId,
      summaryText: 'सेटिंग्स',
      priority: TtsSummaryPriority.normal,
      languageCode: 'hi-IN',
    ),
    '$_settingsScreenId:en-GB': const TtsScreenSummary(
      screenId: _settingsScreenId,
      summaryText: 'Settings',
      priority: TtsSummaryPriority.normal,
      languageCode: 'en-GB',
    ),
  };
}

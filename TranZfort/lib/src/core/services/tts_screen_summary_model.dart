/// TTS screen summary model for role-specific screen summaries.
/// Used to provide context-aware voice feedback when users navigate to different screens.
class TtsScreenSummary {
  final String screenId;
  final String summaryText;
  final TtsSummaryPriority priority;
  final String languageCode;

  const TtsScreenSummary({
    required this.screenId,
    required this.summaryText,
    required this.priority,
    required this.languageCode,
  });

  factory TtsScreenSummary.fromJson(Map<String, dynamic> json) {
    return TtsScreenSummary(
      screenId: json['screenId'] as String,
      summaryText: json['summaryText'] as String,
      priority: TtsSummaryPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TtsSummaryPriority.normal,
      ),
      languageCode: json['languageCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screenId': screenId,
      'summaryText': summaryText,
      'priority': priority.name,
      'languageCode': languageCode,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TtsScreenSummary &&
        other.screenId == screenId &&
        other.summaryText == summaryText &&
        other.priority == priority &&
        other.languageCode == languageCode;
  }

  @override
  int get hashCode =>
      screenId.hashCode ^
      summaryText.hashCode ^
      priority.hashCode ^
      languageCode.hashCode;
}

enum TtsSummaryPriority {
  low,
  normal,
  high,
  urgent,
}

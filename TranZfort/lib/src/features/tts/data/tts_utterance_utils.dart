/// Joins non-empty [parts] and caps length for TTS engines (~500 chars).
String joinTtsClauses(Iterable<String> parts, {int maxLength = 500}) {
  final joined = parts
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (joined.length <= maxLength) {
    return joined;
  }
  final truncated = joined.substring(0, maxLength);
  final lastSpace = truncated.lastIndexOf(' ');
  return (lastSpace > 0 ? truncated.substring(0, lastSpace) : truncated).trimRight();
}

/// Keeps at most [maxSentences] sentence-like chunks for auto screen summaries.
String limitTtsSentences(String message, {int maxSentences = 2}) {
  final trimmed = message.trim();
  if (trimmed.isEmpty || maxSentences < 1) {
    return '';
  }
  final parts = trimmed.split(RegExp(r'(?<=[.!?])\s+')).where((p) => p.trim().isNotEmpty).toList();
  if (parts.isEmpty) {
    return trimmed;
  }
  return parts.take(maxSentences).join(' ').trim();
}

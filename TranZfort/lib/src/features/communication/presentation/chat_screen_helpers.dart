part of 'chat_screen.dart';

String? _payloadString(Map<String, dynamic>? payload, List<String> keys) {
  if (payload == null) {
    return null;
  }
  for (final key in keys) {
    final raw = (payload[key] ?? '').toString().trim();
    if (raw.isNotEmpty) {
      return raw;
    }
  }
  return null;
}

int? _payloadInt(Map<String, dynamic>? payload, List<String> keys) {
  final raw = _payloadString(payload, keys);
  if (raw == null) {
    return null;
  }
  return int.tryParse(raw);
}

double? _payloadDouble(Map<String, dynamic>? payload, List<String> keys) {
  if (payload == null) {
    return null;
  }
  for (final key in keys) {
    final raw = payload[key];
    if (raw is num) {
      return raw.toDouble();
    }
    final parsed = double.tryParse((raw ?? '').toString().trim());
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

String _formatCurrencyCompact(double value) {
  return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value);
}

String _formatTonnesCompact(double value) {
  final formatted = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '${formatted}T';
}

Uri? _externalUri(String? raw) {
  final trimmed = (raw ?? '').trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
    return null;
  }
  return uri;
}

Uri? _externalUriFromPayload(Map<String, dynamic>? payload, List<String> keys) {
  return _externalUri(_payloadString(payload, keys));
}

Uri? _locationUri(Map<String, dynamic>? payload) {
  if (payload == null) {
    return null;
  }
  final lat = _payloadString(payload, const ['lat', 'latitude']);
  final lng = _payloadString(payload, const ['lng', 'longitude']);
  if (lat == null || lng == null) {
    return null;
  }
  return Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
}

String? _fileNameFromPath(String? path) {
  final trimmed = (path ?? '').trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final segments = trimmed.split('/');
  return segments.isEmpty ? null : segments.last;
}

String _formatDuration(int seconds) {
  final minutes = (seconds ~/ 60).toString();
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}

String _otherPartyName(ConversationPreview? conversation, AppUserRole role, String fallbackLabel) {
  if (conversation == null) {
    return fallbackLabel;
  }
  return role == AppUserRole.supplier ? conversation.truckerName : conversation.supplierName;
}

String? _otherPartyMobile(ConversationPreview? conversation, AppUserRole role) {
  if (conversation == null) {
    return null;
  }
  return role == AppUserRole.supplier ? conversation.truckerMobile : conversation.supplierMobile;
}

String? _otherPartyAvatarUrl(ConversationPreview? conversation, AppUserRole role) {
  if (conversation == null) {
    return null;
  }
  return role == AppUserRole.supplier ? conversation.truckerAvatarUrl : conversation.supplierAvatarUrl;
}

String? _otherPartyId(ConversationPreview? conversation, AppUserRole role) {
  if (conversation == null) {
    return null;
  }
  return role == AppUserRole.supplier ? conversation.truckerId : conversation.supplierId;
}

Uri? _callUri(String? mobile) {
  final normalized = (mobile ?? '').trim();
  if (normalized.isEmpty) {
    return null;
  }
  return Uri(scheme: 'tel', path: normalized);
}

String _formatTimestamp(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

import 'dart:convert';
import 'dart:io';

/// Auto-categorize identical EN/HI keys into 'pass' or 'translate'.
void main() {
  final toolDir = Directory('TranZfort/tool');
  final input = File(p.join(toolDir.path, 'identical_keys.csv'));
  final output = File(p.join(toolDir.path, 'identical_keys_triage.csv'));

  final lines = input.readAsLinesSync(encoding: utf8);
  final rows = lines.map((l) {
    // Simple CSV split (handles quoted fields with commas)
    final result = <String>[];
    var inQuotes = false;
    final current = StringBuffer();
    for (var i = 0; i < l.length; i++) {
      final ch = l[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < l.length && l[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString());
    return result;
  }).toList();

  // Header: key, value, category
  final header = rows.first;
  final outLines = <String>[['key', 'value', 'category', 'reason'].join(',')];

  // Known passthrough patterns
  final brandNames = <String>{
    'TranZfort', 'Google', 'Google Places', 'Google Maps',
  };

  final technicalTerms = <String>{
    'km', 'KG', 'T', 'GPS', 'OTP', 'PDF', 'PNG', 'JPG', 'JPEG',
    'Aadhaar', 'PAN', 'GST', 'UPI', 'NEFT', 'RTGS', 'DL',
    'POD', 'LR', 'RC',
  };

  // Email / URL / ID patterns
  final idPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  final urlPattern = RegExp(r'^https?://');
  final loadTripIdPattern = RegExp(r'^(load|trip)-\d+$');
  final truckNumberPattern = RegExp(r'^[A-Z]{2}\d{2}[A-Z]{2}\d{4}$');

  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.length < 2) continue;
    final key = row[0].toString().trim();
    final value = row[1].toString().trim();

    String category;
    String reason;

    // 1. Brand names (exact match)
    if (brandNames.contains(value)) {
      category = 'pass';
      reason = 'brand_name';
    }
    // 2. Pure numbers
    else if (RegExp(r'^\d+$').hasMatch(value)) {
      category = 'pass';
      reason = 'numeric_hint';
    }
    // 3. Email / URL / ID patterns
    else if (idPattern.hasMatch(value) ||
        urlPattern.hasMatch(value) ||
        loadTripIdPattern.hasMatch(value) ||
        truckNumberPattern.hasMatch(value)) {
      category = 'pass';
      reason = 'sample_id';
    }
    // 4. Technical abbreviations (exact match or single word uppercase)
    else if (technicalTerms.contains(value) ||
        (value.length <= 5 && value == value.toUpperCase() && RegExp(r'^[A-Z]+$').hasMatch(value))) {
      category = 'pass';
      reason = 'technical_abbreviation';
    }
    // 5. Keys that are clearly format strings with mostly placeholders
    else if (_isMostlyPlaceholders(value)) {
      category = 'pass';
      reason = 'format_string';
    }
    // 6. English language name
    else if (value == 'English' || value == 'Hindi' || value == 'English') {
      category = 'pass';
      reason = 'language_name';
    }
    // 7. Single word that appears to be a proper noun / status
    else if (value.split(' ').length == 1 &&
        (key.toLowerCase().contains('status') ||
         key.toLowerCase().contains('state') ||
         key.toLowerCase().contains('label'))) {
      category = 'pass';
      reason = 'status_value';
    }
    // Default: needs translation
    else {
      category = 'translate';
      reason = 'untranslated';
    }

    outLines.add('"$key","${value.replaceAll('"', '""')}",$category,$reason');
  }

  output.writeAsStringSync(outLines.join('\n') + '\n', encoding: utf8);

  // Stats
  final translateCount = outLines.where((l) => l.contains(',translate,')).length;
  final passCount = outLines.length - 1 - translateCount; // -1 for header

  print('Triage complete:');
  print('  Total identical keys: ${outLines.length - 1}');
  print('  Pass (keep as-is): $passCount');
  print('  Translate (hand to translator): $translateCount');
  print('');
  print('Output: ${output.path}');
}

bool _isMostlyPlaceholders(String value) {
  // Count non-placeholder text vs placeholder text
  final placeholderPattern = RegExp(r'\{[^{}]+\}');
  final placeholders = placeholderPattern.allMatches(value);
  if (placeholders.isEmpty) return false;

  final placeholderChars = placeholders.fold<int>(0, (sum, m) => sum + m.group(0)!.length);
  // If placeholders make up >40% of the string, consider it mostly structure
  return placeholderChars / value.length > 0.4;
}

class p {
  static String join(String a, String b) => '$a${Platform.pathSeparator}$b';
}

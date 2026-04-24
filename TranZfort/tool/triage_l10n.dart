import 'dart:convert';
import 'dart:io';

/// Triage HI == EN keys in ARB files.
/// Outputs CSVs for translator handoff.
void main() {
  final repoRoot = Directory.current.path;
  final arbDir = Directory(p.join(repoRoot, 'TranZfort', 'lib', 'l10n'));
  final outDir = Directory(p.join(repoRoot, 'TranZfort', 'tool'));

  final enPath = File(p.join(arbDir.path, 'app_en.arb'));
  final hiPath = File(p.join(arbDir.path, 'app_hi.arb'));

  final enJson = jsonDecode(enPath.readAsStringSync()) as Map<String, dynamic>;
  final hiJson = jsonDecode(hiPath.readAsStringSync()) as Map<String, dynamic>;

  // Known intentional passthrough keys (brand names, technical terms, etc.)
  final passthroughPatterns = <String>{
    // Brand / product names
    'appTitle',
    'TranZfort',
    // Email placeholders
    'exampleEmail',
    'supportEmail',
    // Technical / universal terms commonly kept in English
    'km', 'KG', 'T', 'GPS', 'OTP', 'PDF', 'PNG', 'JPG', 'JPEG',
    'Aadhaar', 'PAN', 'GST', 'UPI', 'NEFT', 'RTGS',
    // Status values that are often proper nouns in app code
    'active', 'completed', 'pending', 'verified', 'rejected',
    'Google', 'Google Places', 'Offline database',
    // URL / technical
    'https', 'http', 'www',
  };

  final identical = <Map<String, String>>[];
  final missingInHi = <Map<String, String>>[];
  final translated = <Map<String, String>>[];
  final orphanHi = <Map<String, String>>[];

  for (final key in enJson.keys.where((k) => !k.startsWith('@') && !k.startsWith('_')).toList()..sort()) {
    final enVal = enJson[key]?.toString() ?? '';
    if (hiJson.containsKey(key)) {
      final hiVal = hiJson[key]?.toString() ?? '';
      if (enVal == hiVal) {
        identical.add({
          'key': key,
          'value': enVal,
          'category': '', // manual: 'pass' or 'translate'
        });
      } else {
        translated.add({
          'key': key,
          'en': enVal,
          'hi': hiVal,
        });
      }
    } else {
      missingInHi.add({
        'key': key,
        'value': enVal,
      });
    }
  }

  for (final key in hiJson.keys.where((k) => !k.startsWith('@') && !k.startsWith('_')).toList()..sort()) {
    if (!enJson.containsKey(key)) {
      orphanHi.add({
        'key': key,
        'value': hiJson[key]?.toString() ?? '',
      });
    }
  }

  // Write CSVs
  void writeCsv(String name, List<Map<String, String>> rows) {
    if (rows.isEmpty) return;
    final buf = StringBuffer();
    final keys = rows.first.keys.toList();
    buf.writeln(keys.join(','));
    for (final row in rows) {
      buf.writeln(keys.map((k) => '"${row[k]?.replaceAll('"', '""') ?? ''}"').join(','));
    }
    File(p.join(outDir.path, name)).writeAsStringSync(buf.toString(), encoding: utf8);
  }

  writeCsv('identical_keys.csv', identical);
  writeCsv('missing_hi.csv', missingInHi);
  writeCsv('orphan_hi.csv', orphanHi);
  writeCsv('translated.csv', translated);

  // Summary
  final summary = '''
Localization Triage Summary
===========================
Generated: ${DateTime.now().toIso8601String()}

Total EN keys: ${enJson.keys.where((k) => !k.startsWith('@') && !k.startsWith('_')).length}
Total HI keys: ${hiJson.keys.where((k) => !k.startsWith('@') && !k.startsWith('_')).length}
Identical EN/HI values (need triage): ${identical.length}
Translated (different values): ${translated.length}
Missing in HI: ${missingInHi.length}
Orphan HI keys: ${orphanHi.length}

Files written to ${outDir.path}:
- identical_keys.csv    : keys where HI == EN (needs manual triage)
- missing_hi.csv        : keys present in EN but missing in HI
- orphan_hi.csv         : keys present in HI but not in EN
- translated.csv        : keys already translated (for reference)

Next step: Review identical_keys.csv and mark category column as:
  'pass'    = brand names, emails, technical terms (keep as-is)
  'translate' = genuine untranslated strings (hand to translator)
'''.trim();

  File(p.join(outDir.path, 'l10n_triage_summary.txt'))
      .writeAsStringSync(summary, encoding: utf8);

  print(summary);
}

class p {
  static String join(String part1, String part2, [String? part3, String? part4]) {
    final parts = [part1, part2, if (part3 != null) part3, if (part4 != null) part4];
    return parts.join(Platform.pathSeparator);
  }
}

import 'dart:convert';
import 'dart:io';

/// Strip @metadata description fields on mechanical keys (no placeholders).
/// Keep descriptions where placeholders exist (they document parameter usage).
void main() {
  final arbPath = 'TranZfort/lib/l10n/app_en.arb';
  final arbFile = File(arbPath);
  final content = arbFile.readAsStringSync(encoding: utf8);
  final json = jsonDecode(content) as Map<String, dynamic>;

  int stripped = 0;
  int kept = 0;
  final strippedKeys = <String>[];
  final keptKeys = <String>[];

  for (final key in json.keys.toList()) {
    if (key.startsWith('@') && !key.startsWith('@_')) {
      final value = json[key];
      if (value is! Map<String, dynamic>) continue; // skip String section markers
      final meta = value;
      final hasPlaceholders = meta.containsKey('placeholders');
      final hasDescription = meta.containsKey('description');

      if (hasDescription && !hasPlaceholders) {
        // Strip the description - key is mechanical (no params)
        meta.remove('description');
        stripped++;
        strippedKeys.add(key);
      } else {
        kept++;
        keptKeys.add(key);
      }

      // If metadata is now empty, remove the whole @key
      if (meta.isEmpty) {
        json.remove(key);
      }
    }
  }

  // Write back with pretty formatting (2-space indent)
  const encoder = JsonEncoder.withIndent('  ');
  final output = encoder.convert(json);
  arbFile.writeAsStringSync(output + '\n', encoding: utf8);

  print('Metadata description stripping complete:');
  print('  Stripped: $stripped keys');
  print('  Kept: $kept keys (have placeholders or no description)');
  print('');
  print('First 10 stripped:');
  for (final k in strippedKeys.take(10)) {
    print('  - $k');
  }
  print('');
  print('First 10 kept:');
  for (final k in keptKeys.take(10)) {
    print('  - $k');
  }
}

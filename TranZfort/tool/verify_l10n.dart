import 'dart:convert';
import 'dart:io';

void main() {
  final repoRoot = Directory.current.path;
  final libDir = Directory(_join(repoRoot, 'lib'));
  final toolDir = Directory(_join(repoRoot, 'tool'));
  final enFile = File(_join(repoRoot, 'lib', 'l10n', 'app_en.arb'));
  final hiFile = File(_join(repoRoot, 'lib', 'l10n', 'app_hi.arb'));
  final allowlistFile = File(_join(repoRoot, 'tool', 'l10n_allowlist.txt'));

  if (!enFile.existsSync() || !hiFile.existsSync()) {
    stderr.writeln('Missing ARB files. Expected lib/l10n/app_en.arb and lib/l10n/app_hi.arb.');
    exitCode = 1;
    return;
  }

  final enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final hiJson = jsonDecode(hiFile.readAsStringSync()) as Map<String, dynamic>;
  final enKeys = enJson.keys.where(_isRealArbKey).toList()..sort();
  final hiKeys = hiJson.keys.where(_isRealArbKey).toSet();
  final allowlist = allowlistFile.existsSync()
      ? allowlistFile
          .readAsLinesSync()
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .toSet()
      : <String>{};

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
  final uiFiles = dartFiles.where(_isUiDartFile).toList();

  final missingInHi = <String>[];
  final identicalOutsideAllowlist = <String>[];
  final unusedEnKeys = <String>[];
  final hardcodedFindings = <String>[];

  final fileContents = <String, String>{
    for (final file in dartFiles) file.path: file.readAsStringSync(),
  };

  for (final key in enKeys) {
    final enValue = (enJson[key] ?? '').toString();
    if (!hiKeys.contains(key)) {
      missingInHi.add(key);
      continue;
    }

    final hiValue = (hiJson[key] ?? '').toString();
    if (enValue == hiValue && !allowlist.contains(key)) {
      identicalOutsideAllowlist.add(key);
    }

    if (!_isMetadataOnlyKey(key, enJson) && !_hasReferenceInLib(key, fileContents.values)) {
      unusedEnKeys.add(key);
    }
  }

  final hardcodedPatterns = <RegExp>[
    RegExp(r'''Text\(\s*['"][A-Z][^'"]{2,}['"]''', multiLine: true),
    RegExp(r'''tooltip\s*:\s*['"][A-Z][^'"]{2,}['"]''', multiLine: true),
    RegExp(r'''label\s*:\s*['"][A-Z][^'"]{2,}['"]''', multiLine: true),
    RegExp(r'''title\s*:\s*['"][A-Z][^'"]{2,}['"]''', multiLine: true),
    RegExp(r'''subtitle\s*:\s*['"][A-Z][^'"]{2,}['"]''', multiLine: true),
  ];

  final hardcodedAllowlistPatterns = <RegExp>[
    RegExp(r'app_localizations'),
    RegExp(r'generated_plugin_registrant'),
    RegExp(r'build\\'),
    RegExp(r'\.g\.dart$'),
  ];

  final hardcodedStringsAllowlistFile = File(_join(repoRoot, 'tool', 'hardcoded_strings_allowlist.txt'));
  final hardcodedStringsAllowlist = hardcodedStringsAllowlistFile.existsSync()
      ? hardcodedStringsAllowlistFile
          .readAsLinesSync()
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .toSet()
      : <String>{};

  for (final file in uiFiles) {
    final entry = MapEntry(file.path, fileContents[file.path] ?? '');
    final normalizedPath = entry.key.replaceAll('/', '\\').toLowerCase();
    if (hardcodedAllowlistPatterns.any((pattern) => pattern.hasMatch(normalizedPath))) {
      continue;
    }

    for (final pattern in hardcodedPatterns) {
      final matches = pattern.allMatches(entry.value).take(5);
      for (final match in matches) {
        final snippet = match.group(0)?.replaceAll('\n', ' ') ?? '';
        // Skip if the matched snippet contains any allowlisted string literal
        final isAllowed = hardcodedStringsAllowlist.any((allowed) => snippet.contains("'$allowed'") || snippet.contains('"$allowed"'));
        if (!isAllowed) {
          hardcodedFindings.add('${entry.key}: $snippet');
        }
      }
    }
  }

  var hasFailure = false;

  void report(String title, List<String> items) {
    if (items.isEmpty) return;
    hasFailure = true;
    stderr.writeln('\n$title (${items.length})');
    for (final item in items.take(50)) {
      stderr.writeln('- $item');
    }
    if (items.length > 50) {
      stderr.writeln('- ... ${items.length - 50} more');
    }
  }

  report('Missing HI keys', missingInHi);
  report('Identical EN/HI values outside allowlist', identicalOutsideAllowlist);
  report('Unused EN localization keys', unusedEnKeys);
  report('Possible hardcoded UI strings', hardcodedFindings);

  if (hasFailure) {
    stderr.writeln('\nLocalization verification failed.');
    exitCode = 1;
    return;
  }

  stdout.writeln('Localization verification passed.');
  stdout.writeln('EN keys checked: ${enKeys.length}');
  stdout.writeln('Allowlisted identical keys: ${allowlist.length}');
}

bool _isRealArbKey(String key) => !key.startsWith('@') && !key.startsWith('_');

bool _isMetadataOnlyKey(String key, Map<String, dynamic> enJson) {
  final metadata = enJson['@$key'];
  if (metadata is Map<String, dynamic>) {
    final placeholders = metadata['placeholders'];
    return placeholders != null && placeholders is Map<String, dynamic> && placeholders.isNotEmpty;
  }
  return false;
}

bool _hasReferenceInLib(String key, Iterable<String> contents) {
  final needle = '.${key}';
  final altNeedle = "'$key'";
  final altNeedleDouble = '"$key"';
  for (final content in contents) {
    if (content.contains(needle) || content.contains(altNeedle) || content.contains(altNeedleDouble)) {
      return true;
    }
  }
  return false;
}

bool _isUiDartFile(File file) {
  final normalizedPath = file.path.replaceAll('/', '\\').toLowerCase();
  return normalizedPath.contains('\\presentation\\') ||
      normalizedPath.contains('\\widgets\\') ||
      normalizedPath.endsWith('_screen.dart') ||
      normalizedPath.endsWith('_sections.dart');
}

String _join(String part1, String part2, [String? part3, String? part4]) {
  final parts = [part1, part2, if (part3 != null) part3, if (part4 != null) part4];
  return parts.join(Platform.pathSeparator);
}

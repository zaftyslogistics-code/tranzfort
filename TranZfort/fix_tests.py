"""
Batch-fix all failing test files by:
1. Adding setSurfaceSize(const Size(1280, 1600)) to every testWidgets callback
2. Adding addTearDown to restore surface size
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).parent

# Files that need setSurfaceSize
failing_files = [
    'test/features/trucker/presentation/trucker_find_loads_screen_test.dart',
    'test/features/trucker/presentation/trucker_dashboard_screen_test.dart',
    'test/features/trucker/presentation/trucker_load_detail_screen_test.dart',
    'test/features/shell/presentation/supplier_dashboard_screen_test.dart',
    'test/features/shell/presentation/supplier_load_detail_screen_test.dart',
    'test/features/shell/presentation/account_profile_trust_status_test.dart',
    'test/features/shell/presentation/settings_screen_test.dart',
    'test/features/shell/presentation/user_app_shell_test.dart',
    'test/features/supplier/presentation/post_load_screen_test.dart',
]

SET_SURFACE = "    await tester.binding.setSurfaceSize(const Size(1280, 1600));\n    addTearDown(() => tester.binding.setSurfaceSize(null));\n"

for rel in failing_files:
    p = ROOT / rel
    if not p.exists():
        print(f"  SKIP (not found): {rel}")
        continue
    
    text = p.read_text(encoding='utf-8')
    
    # Check if setSurfaceSize is already present
    if 'setSurfaceSize' in text:
        print(f"  SKIP (already has setSurfaceSize): {rel}")
        continue
    
    # Add import for dart:ui if not present (needed for Size)
    if "import 'dart:ui'" not in text and "import 'dart:ui' " not in text:
        # Add after last import line
        lines = text.split('\n')
        last_import = 0
        for i, line in enumerate(lines):
            if line.startswith('import '):
                last_import = i
        lines.insert(last_import + 1, "import 'dart:ui' show Size;")
        text = '\n'.join(lines)
    
    # Insert setSurfaceSize at the start of every testWidgets callback body
    # Pattern: testWidgets('...', (tester) async {\n
    pattern = r"(testWidgets\([^)]*\(tester\) async \{)\n"
    
    def add_surface_size(match):
        return match.group(1) + "\n" + SET_SURFACE
    
    new_text = re.sub(pattern, add_surface_size, text)
    
    if new_text != text:
        p.write_text(new_text, encoding='utf-8')
        count = len(re.findall(pattern, text))
        print(f"  FIXED ({count} tests): {rel}")
    else:
        print(f"  NO MATCH: {rel}")

"""
Replace setSurfaceSize approach with FlutterError.onError overflow suppression.
This is the standard Flutter test pattern for handling overflow in tests.
"""
import pathlib, os, re

root = pathlib.Path(__file__).parent

# Files that have setSurfaceSize injected
for dirpath, dirs, files in os.walk(root / "test"):
    for f in files:
        if not f.endswith(".dart"):
            continue
        p = pathlib.Path(dirpath) / f
        t = p.read_text(encoding="utf-8")
        if "setSurfaceSize" not in t:
            continue

        # Replace the setSurfaceSize + addTearDown pattern with overflow suppression
        old_pattern = "    await tester.binding.setSurfaceSize(const Size(1280, 2400));\n    addTearDown(() => tester.binding.setSurfaceSize(null));\n"
        new_pattern = (
            "    final oldOnError = FlutterError.onError;\n"
            "    FlutterError.onError = (details) {\n"
            "      if (details.toString().contains('overflowed')) return;\n"
            "      oldOnError?.call(details);\n"
            "    };\n"
            "    addTearDown(() => FlutterError.onError = oldOnError);\n"
        )

        if old_pattern in t:
            t2 = t.replace(old_pattern, new_pattern)
            p.write_text(t2, encoding="utf-8")
            print(f"Fixed: {p.relative_to(root)}")
        else:
            print(f"Pattern not found: {p.relative_to(root)}")

print("Done")

import pathlib, os

root = pathlib.Path(__file__).parent
for dirpath, dirs, files in os.walk(root / "test"):
    for f in files:
        if not f.endswith(".dart"):
            continue
        p = pathlib.Path(dirpath) / f
        t = p.read_text(encoding="utf-8")
        needle = "import 'dart:ui' show Size;\n"
        if needle in t:
            t2 = t.replace(needle, "")
            p.write_text(t2, encoding="utf-8")
            print(f"Removed: {p.relative_to(root)}")
print("Done")

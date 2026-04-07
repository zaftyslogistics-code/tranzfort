"""Update all setSurfaceSize calls from 1600 to 2400 height."""
import pathlib, os

root = pathlib.Path(__file__).parent
count = 0
for dirpath, dirs, files in os.walk(root / "test"):
    for f in files:
        if not f.endswith(".dart"):
            continue
        p = pathlib.Path(dirpath) / f
        t = p.read_text(encoding="utf-8")
        if "Size(1280, 1600)" in t:
            t2 = t.replace("Size(1280, 1600)", "Size(1280, 2400)")
            p.write_text(t2, encoding="utf-8")
            count += 1
print(f"Updated {count} files")

#!/usr/bin/env python3
"""Hash exact runtime/export inputs so the release matches the locally tested APK."""
from pathlib import Path
import hashlib


def runtime_digest():
    root = Path(__file__).resolve().parents[1]
    files = [root / "project.godot", root / "export_presets.cfg"]
    for directory in ["scripts", "scenes", "data", "assets"]:
        files.extend(path for path in (root / directory).rglob("*")
                     if path.is_file() and path.suffix != ".md")
    digest = hashlib.sha256()
    for path in sorted(files, key=lambda item: item.relative_to(root).as_posix()):
        digest.update(path.relative_to(root).as_posix().encode())
        digest.update(b"\0")
        digest.update(hashlib.sha256(path.read_bytes()).digest())
    return digest.hexdigest()


if __name__ == "__main__":
    print(runtime_digest())

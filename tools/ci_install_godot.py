#!/usr/bin/env python3
"""Install the exact Godot engine on a Linux CI runner, verifying official SHA-512."""
import argparse
from pathlib import Path
import zipfile
from bootstrap_android import download, GODOT_VERSION, RELEASE


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tools-root", type=Path, required=True)
    args = parser.parse_args()
    root = args.tools_root.resolve()
    filename = f"Godot_v{GODOT_VERSION}-stable_linux.x86_64.zip"
    checksums = download(RELEASE + "SHA512-SUMS.txt", root / "downloads/SHA512-SUMS.txt")
    expected = next(line.split()[0] for line in checksums.read_text().splitlines() if line.endswith(" " + filename))
    archive = download(RELEASE + filename, root / "downloads" / filename, expected, "sha512")
    output = root / "bin/godot"
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as content:
        output.write_bytes(content.read(filename.removesuffix(".zip")))
    output.chmod(0o755)
    print("Godot", GODOT_VERSION, "installed with verified SHA-512")


if __name__ == "__main__":
    main()

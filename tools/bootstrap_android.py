#!/usr/bin/env python3
"""Install verified official non-Gradle Godot Android export dependencies on Linux.

Uses urllib's supported HTTPS proxy route; Java sdkmanager ignores some cloud
proxy configuration. Checks original Google archive hashes and Godot SHA-512.
No signing secrets or credentials are stored in the repository.
"""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import urllib.request
import xml.etree.ElementTree as ET
import zipfile

GODOT_VERSION = "4.6.3"
RELEASE = f"https://github.com/godotengine/godot/releases/download/{GODOT_VERSION}-stable/"
GOOGLE = "https://dl.google.com/android/repository/"


def download(url, target, expected=None, algorithm="sha1"):
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() and expected and digest(target, algorithm) == expected:
        return target
    temporary = target.with_suffix(target.suffix + ".partial")
    with urllib.request.urlopen(url, timeout=120) as response, temporary.open("wb") as output:
        shutil.copyfileobj(response, output, length=4 * 1024 * 1024)
    if expected and digest(temporary, algorithm) != expected:
        temporary.unlink()
        raise RuntimeError(f"Checksum mismatch for {target.name}")
    temporary.replace(target)
    return target


def digest(path, algorithm):
    h = hashlib.new(algorithm)
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(4 * 1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def extract_verified(path, destination):
    with zipfile.ZipFile(path) as archive:
        for item in archive.infolist():
            output = (destination / item.filename).resolve()
            if not output.is_relative_to(destination.resolve()):
                raise RuntimeError("Unsafe archive path")
        archive.extractall(destination)
        for item in archive.infolist():
            mode = item.external_attr >> 16
            if mode and not item.is_dir():
                (destination / item.filename).chmod(mode & 0o777)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tools-root", type=Path, default=Path(__file__).resolve().parents[1] / ".tools")
    parser.add_argument("--accept-sdk-license", action="store_true", help="Accept the license in official Google repository metadata")
    args = parser.parse_args()
    root = args.tools_root.resolve()
    downloads = root / "downloads"
    metadata = download(GOOGLE + "repository2-1.xml", downloads / "repository.xml")
    packages = ET.parse(metadata).getroot()
    archives = {}
    wanted = {"build-tools;36.0.0": "build-tools_r36_linux.zip",
              "platforms;android-36": "platform-36_r02.zip",
              "platform-tools": "platform-tools_r37.0.1-linux.zip"}
    for package in packages.iter("remotePackage"):
        package_id = package.get("path")
        if package_id not in wanted:
            continue
        for archive in package.findall("archives/archive"):
            if archive.findtext("complete/url") == wanted[package_id]:
                archives[package_id] = (wanted[package_id], archive.findtext("complete/checksum"))
    if set(archives) != set(wanted):
        raise RuntimeError("Pinned SDK package missing from authoritative metadata")
    sdk = root / "android-sdk"
    if not args.accept_sdk_license:
        raise RuntimeError("Review Android SDK license; rerun with --accept-sdk-license after accepting it")
    for license_node in packages.iter("license"):
        if license_node.get("id") == "android-sdk-license":
            text = (license_node.text or "").strip()
            (root / "ANDROID_SDK_LICENSE.txt").write_text(text)
            (sdk / "licenses").mkdir(parents=True, exist_ok=True)
            (sdk / "licenses" / "android-sdk-license").write_text(hashlib.sha1(text.encode()).hexdigest() + "\n")
    for package_id, (filename, checksum) in archives.items():
        destination = sdk / package_id.replace(";", "/")
        if (destination / "source.properties").exists():
            print("Already installed:", package_id)
            continue
        archive = download(GOOGLE + filename, downloads / filename, checksum)
        staging = root / ("extract-" + package_id.replace(";", "-"))
        if staging.exists():
            shutil.rmtree(staging)
        staging.mkdir(parents=True)
        extract_verified(archive, staging)
        children = list(staging.iterdir())
        if len(children) != 1 or not children[0].is_dir():
            raise RuntimeError("Unexpected official SDK archive layout")
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists():
            raise RuntimeError("Refusing to overwrite partially installed SDK package: " + str(destination))
        shutil.move(str(children[0]), destination)
        staging.rmdir()
        print("Installed and checksum verified:", package_id)
    sums = download(RELEASE + "SHA512-SUMS.txt", downloads / "SHA512-SUMS.txt")
    template_name = f"Godot_v{GODOT_VERSION}-stable_export_templates.tpz"
    expected = next(line.split()[0] for line in sums.read_text().splitlines() if line.endswith(" " + template_name))
    existing = downloads / "export_templates.tpz"
    archive = download(RELEASE + template_name, existing, expected, "sha512")
    templates = root / "xdg/data/godot/export_templates" / (GODOT_VERSION + ".stable")
    templates.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as content:
        for name in ["android_debug.apk", "android_release.apk", "version.txt", "linux_debug.x86_64", "linux_release.x86_64"]:
            (templates / name).write_bytes(content.read("templates/" + name))
    key = root / "debug.keystore"
    if not key.exists():
        subprocess.run(["keytool", "-genkeypair", "-keystore", str(key), "-storepass", "android",
                        "-alias", "androiddebugkey", "-keypass", "android", "-dname", "CN=Android Debug,O=Android,C=US",
                        "-keyalg", "RSA", "-keysize", "2048", "-validity", "10000"], check=True)
    config_dir = root / "xdg/config/godot"
    config_dir.mkdir(parents=True, exist_ok=True)
    settings_path = config_dir / "editor_settings-4.6.tres"
    settings = settings_path.read_text() if settings_path.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    import re
    java = str(Path(shutil.which("java")).resolve().parents[1])
    updates = {"export/android/android_sdk_path": str(sdk), "export/android/java_sdk_path": java,
               "export/android/debug_keystore": str(key), "export/android/debug_keystore_pass": "android",
               "export/android/debug_keystore_user": "androiddebugkey"}
    for name, value in updates.items():
        line = name + ' = "' + value + '"'
        if re.search(r"^" + re.escape(name) + r" = .*", settings, flags=re.M):
            settings = re.sub(r"^" + re.escape(name) + r" = .*", lambda _: line, settings, flags=re.M)
        else:
            settings += line + "\n"
    settings_path.write_text(settings)
    print("Android export tools ready at", root)


if __name__ == "__main__":
    main()

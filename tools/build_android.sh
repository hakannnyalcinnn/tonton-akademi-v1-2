#!/usr/bin/env bash
set -euo pipefail
PRIZMA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIZMA_TOOL_ROOT="${PRIZMA_TOOLS_DIR:-$PRIZMA_ROOT/.tools}"
cd "$PRIZMA_ROOT"
bash tools/test.sh
bash tools/godot.sh --headless --export-debug Android build/prizma-debug.apk > build/android-export.log 2>&1
if rg -q '^SCRIPT ERROR:|^ERROR:' build/android-export.log; then
    cat build/android-export.log
    exit 1
fi
"$PRIZMA_TOOL_ROOT/android-sdk/build-tools/36.0.0/apksigner" verify --verbose build/prizma-debug.apk
"$PRIZMA_TOOL_ROOT/android-sdk/build-tools/36.0.0/aapt" dump badging build/prizma-debug.apk > build/android-package.txt
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile
manifest = Path('build/android-package.txt').read_text()
assert "name='com.prizma.renklerinuyanisi'" in manifest
assert "sdkVersion:'24'" in manifest and "targetSdkVersion:'36'" in manifest
assert 'android.permission.INTERNET' not in manifest
assert 'android.permission.VIBRATE' in manifest
with ZipFile('build/prizma-debug.apk') as apk:
    names = apk.namelist()
    assert 'assets/data/levels.json' in names
    assert 'lib/arm64-v8a/libgodot_android.so' in names
    assert 'lib/armeabi-v7a/libgodot_android.so' in names
    assert not any(name.startswith(('assets/tests/', 'assets/tools/')) for name in names)
print('PASS: APK signature, SDK versions, offline permissions, level data and ARM libraries')
PY
sha256sum build/prizma-debug.apk > build/prizma-debug.apk.sha256
echo 'Android debug APK: build/prizma-debug.apk'

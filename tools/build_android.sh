#!/usr/bin/env bash
set -euo pipefail
PRIZMA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIZMA_TOOL_ROOT="${PRIZMA_TOOLS_DIR:-$PRIZMA_ROOT/.tools}"
cd "$PRIZMA_ROOT"
PRIZMA_PRESET="${PRIZMA_ANDROID_PRESET:-Android Match3 Test}"
case "$PRIZMA_PRESET" in
  "Android Match3 Test") PRIZMA_APK_FILE=build/prizma-match3.apk; PRIZMA_PACKAGE=com.prizma.renklerinuyanisi.match3 ;;
  "Android") PRIZMA_APK_FILE=build/prizma-debug.apk; PRIZMA_PACKAGE=com.prizma.renklerinuyanisi ;;
  *) echo 'Unsupported Android preset' >&2; exit 1 ;;
esac
bash tools/test.sh
bash tools/godot.sh --headless --export-debug "$PRIZMA_PRESET" "$PRIZMA_APK_FILE" > build/android-export.log 2>&1
if rg -q '^SCRIPT ERROR:|^ERROR:' build/android-export.log; then
    cat build/android-export.log
    exit 1
fi
"$PRIZMA_TOOL_ROOT/android-sdk/build-tools/36.0.0/apksigner" verify --verbose "$PRIZMA_APK_FILE"
"$PRIZMA_TOOL_ROOT/android-sdk/build-tools/36.0.0/aapt" dump badging "$PRIZMA_APK_FILE" > build/android-package.txt
python3 - "$PRIZMA_APK_FILE" "$PRIZMA_PACKAGE" <<'PY'
import sys
from pathlib import Path
from zipfile import ZipFile
manifest = Path('build/android-package.txt').read_text()
assert "name='" + sys.argv[2] + "'" in manifest
assert "versionName='0.3.0'" in manifest
assert "sdkVersion:'24'" in manifest and "targetSdkVersion:'36'" in manifest
assert 'android.permission.INTERNET' not in manifest
assert 'android.permission.VIBRATE' in manifest
with ZipFile(sys.argv[1]) as apk:
    names = apk.namelist()
    assert 'assets/data/levels.json' in names
    assert 'lib/arm64-v8a/libgodot_android.so' in names
    assert 'lib/armeabi-v7a/libgodot_android.so' in names
    assert not any(name.startswith(('assets/tests/', 'assets/tools/')) for name in names)
print('PASS: APK signature, SDK versions, offline permissions, level data and ARM libraries')
PY
sha256sum "$PRIZMA_APK_FILE" > "$PRIZMA_APK_FILE.sha256"
echo "Android debug APK: $PRIZMA_APK_FILE"

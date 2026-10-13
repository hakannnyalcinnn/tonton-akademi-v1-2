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
bash tools/export_android.sh

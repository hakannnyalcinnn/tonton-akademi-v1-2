#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
bash tools/godot.sh --headless --editor --import --quit > build/release-import.log 2>&1
if rg -q '^SCRIPT ERROR:|^ERROR:' build/release-import.log;then cat build/release-import.log;exit 1;fi
# Broad regression suites were run locally; CI repeats release-critical acceptance once.
for suite in workflow_smoke v0123_tests v0122_ui_tests v012_tests goals_panel_tests gameplay2_ui match3_ui_only persistence_probe canyon_mechanics_tests;do
 if ! bash tools/godot.sh --headless --audio-driver Dummy --max-fps 60 --script "tests/$suite.gd" > "build/release-$suite.log" 2>&1;then cat "build/release-$suite.log";exit 1;fi
 if rg -q '^SCRIPT ERROR:|^ERROR:|^FAIL' "build/release-$suite.log";then cat "build/release-$suite.log";exit 1;fi
 tail -2 "build/release-$suite.log"
done

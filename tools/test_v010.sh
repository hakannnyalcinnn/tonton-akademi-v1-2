#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
bash tools/godot.sh --headless --editor --import --quit > build/v010-import.log 2>&1
if rg -q '^SCRIPT ERROR:|^ERROR:' build/v010-import.log; then cat build/v010-import.log; exit 1; fi
# Reuse established suites, selecting coverage of changed rules, saves and presentation.
for suite in deadlock_tests canyon_mechanics_tests run_tests mechanic_tests package2_tests package4_tests package5_mechanics gameplay2_tests campaign_smoke canyon_ui goals_panel_tests gameplay2_ui finale_ui; do
  if ! bash tools/godot.sh --headless --audio-driver Dummy --max-fps 60 --script "tests/$suite.gd" > "build/v010-$suite.log" 2>&1; then cat "build/v010-$suite.log";exit 1;fi
  if rg -q '^SCRIPT ERROR:|^ERROR:|^FAIL' "build/v010-$suite.log";then cat "build/v010-$suite.log";exit 1;fi
  tail -n 2 "build/v010-$suite.log"
done

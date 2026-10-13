#!/usr/bin/env bash
set -euo pipefail
PRIZMA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PRIZMA_ROOT"
mkdir -p build
if ! bash tools/godot.sh --headless --editor --import --quit > build/import.log 2>&1; then
    cat build/import.log
    exit 1
fi
if rg -q '^SCRIPT ERROR:|^ERROR:' build/import.log; then
    cat build/import.log
    exit 1
fi
if ! bash tools/godot.sh --headless --script tests/run_tests.gd > build/test-results.log 2>&1; then
    cat build/test-results.log
    exit 1
fi
cat build/test-results.log
if rg -q '^SCRIPT ERROR:|^ERROR:|^FAIL:' build/test-results.log; then exit 1; fi
for action in write read; do
    if ! bash tools/godot.sh --headless --script tests/persistence_probe.gd -- "$action" > "build/persistence-$action.log" 2>&1; then
        cat "build/persistence-$action.log"
        exit 1
    fi
    cat "build/persistence-$action.log"
    if rg -q '^SCRIPT ERROR:|^ERROR:' "build/persistence-$action.log"; then exit 1; fi
done

if ! bash tools/godot.sh --headless --script tests/quality_tests.gd > build/quality-results.log 2>&1; then
    cat build/quality-results.log
    exit 1
fi
cat build/quality-results.log
if rg -q '^SCRIPT ERROR:|^ERROR:' build/quality-results.log; then exit 1; fi

if ! bash tools/godot.sh --headless --audio-driver Dummy --max-fps 60 --script tests/swipe_stress.gd > build/swipe-stress.log 2>&1; then
    cat build/swipe-stress.log
    exit 1
fi
cat build/swipe-stress.log
if rg -q '^SCRIPT ERROR:|^ERROR:' build/swipe-stress.log; then exit 1; fi

for suite in mechanic_tests mechanic_ui_tests; do
    if ! bash tools/godot.sh --headless --audio-driver Dummy --script "tests/$suite.gd" > "build/$suite.log" 2>&1; then
        cat "build/$suite.log"
        exit 1
    fi
    cat "build/$suite.log"
    if rg -q '^SCRIPT ERROR:|^ERROR:|^FAIL:' "build/$suite.log"; then exit 1; fi
done

if ! bash tools/godot.sh --headless --audio-driver Dummy --max-fps 60 --script tests/swipe_stress.gd -- mechanics > build/mechanic-swipe-stress.log 2>&1; then
    cat build/mechanic-swipe-stress.log
    exit 1
fi
cat build/mechanic-swipe-stress.log
if rg -q '^SCRIPT ERROR:|^ERROR:' build/mechanic-swipe-stress.log; then exit 1; fi

for suite in package2_tests package2_levels package2_ui; do
    if ! bash tools/godot.sh --headless --audio-driver Dummy --script "tests/$suite.gd" > "build/$suite.log" 2>&1; then
        cat "build/$suite.log"
        exit 1
    fi
    cat "build/$suite.log"
    if rg -q '^SCRIPT ERROR:|^ERROR:|^FAIL:' "build/$suite.log"; then exit 1; fi
done

if ! bash tools/godot.sh --headless --audio-driver Dummy --max-fps 60 --script tests/swipe_stress.gd -- package2 > build/package2-native-swipes.log 2>&1; then
    cat build/package2-native-swipes.log
    exit 1
fi
cat build/package2-native-swipes.log
if rg -q '^SCRIPT ERROR:|^ERROR:' build/package2-native-swipes.log; then exit 1; fi

for suite in package4_tests ocean_levels package4_ui; do
    if ! bash tools/godot.sh --headless --audio-driver Dummy --script "tests/$suite.gd" > "build/$suite.log" 2>&1; then
        cat "build/$suite.log"
        exit 1
    fi
    cat "build/$suite.log"
    if rg -q '^SCRIPT ERROR:|^ERROR:|^FAIL:' "build/$suite.log"; then exit 1; fi
done
if ! bash tools/godot.sh --headless --audio-driver Dummy --max-fps 60 --script tests/swipe_stress.gd -- ocean > build/ocean-native-swipes.log 2>&1; then
    cat build/ocean-native-swipes.log
    exit 1
fi
cat build/ocean-native-swipes.log
if rg -q '^SCRIPT ERROR:|^ERROR:' build/ocean-native-swipes.log; then exit 1; fi

if ! bash tools/godot.sh --headless --audio-driver Dummy --script tests/casual_ui.gd > build/casual-ui.log 2>&1; then
    cat build/casual-ui.log
    exit 1
fi
cat build/casual-ui.log
if rg -q '^SCRIPT ERROR:|^ERROR:|^FAIL:' build/casual-ui.log; then exit 1; fi

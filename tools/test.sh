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

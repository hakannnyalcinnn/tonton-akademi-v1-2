#!/usr/bin/env bash
set -euo pipefail
PRIZMA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIZMA_TOOL_ROOT="${PRIZMA_TOOLS_DIR:-$PRIZMA_ROOT/.tools}"
export XDG_DATA_HOME="$PRIZMA_TOOL_ROOT/xdg/data"
export XDG_CONFIG_HOME="$PRIZMA_TOOL_ROOT/xdg/config"
export XDG_CACHE_HOME="$PRIZMA_TOOL_ROOT/xdg/cache"
export ANDROID_USER_HOME="$PRIZMA_TOOL_ROOT/android-user"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
mkdir -p "$ANDROID_USER_HOME"
exec godot --path "$PRIZMA_ROOT" "$@"

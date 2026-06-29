#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="FlypyHelper"
INSTALL_ROOT="/Applications"

if [[ ! -w "$INSTALL_ROOT" ]]; then
  INSTALL_ROOT="$HOME/Applications"
  mkdir -p "$INSTALL_ROOT"
fi

APP_DIR="$INSTALL_ROOT/$APP_NAME.app"

if [[ "$APP_DIR" != */FlypyHelper.app ]]; then
  echo "Refusing to install to unexpected path: $APP_DIR" >&2
  exit 1
fi

cd "$ROOT"
swift build -c release

BIN_DIR="$(swift build -c release --show-bin-path)"
BIN="$BIN_DIR/$APP_NAME"

if [[ ! -x "$BIN" ]]; then
  echo "Built executable not found: $BIN" >&2
  exit 1
fi

pids="$(pgrep -x "$APP_NAME" || true)"
if [[ -n "$pids" ]]; then
  echo "$pids" | xargs kill
  sleep 0.5
fi

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$BIN" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/packaging/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT/packaging/PkgInfo" "$APP_DIR/Contents/PkgInfo"
cp "$ROOT/packaging/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

open "$APP_DIR"

echo "$APP_DIR"

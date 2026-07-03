#!/usr/bin/env bash
# Same as: flutter build apk --release
# Obfuscation is enabled automatically via android/gradle.properties

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SYMBOLS_DIR="$PROJECT_ROOT/build/app/outputs/symbols"

cd "$PROJECT_ROOT"
mkdir -p "$SYMBOLS_DIR"

BUILD_ARGS=(
  build apk
  --release
  --obfuscate
  "--split-debug-info=$SYMBOLS_DIR"
)

if [[ "${1:-}" == "--split-per-abi" ]]; then
  BUILD_ARGS+=(--split-per-abi)
fi

echo "Building obfuscated release APK..."
echo "Debug symbols will be saved to: $SYMBOLS_DIR"
echo "(Keep symbols private - needed to deobfuscate Crashlytics stack traces.)"

flutter "${BUILD_ARGS[@]}"

echo ""
echo "Build complete."
echo "APK output: build/app/outputs/flutter-apk/"
echo "Symbols:    $SYMBOLS_DIR"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_DIR="$ROOT/assets/icons/template"
GENERATED_DIR="$ROOT/assets/icons/generated"
IOS_TARGET="$ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_BASE="$ROOT/android/app/src/main/res"

function ensure_dir() {
  if [[ ! -d "$1" ]]; then
    echo "Directory mancante: $1"
    exit 1
  fi
}

ensure_dir "$GENERATED_DIR"
ensure_dir "$IOS_TARGET"
ensure_dir "$ANDROID_BASE"

echo "Copio icone iOS..."
cp "$GENERATED_DIR"/*.png "$IOS_TARGET/"

echo "Copio icone Android (mipmap)..."
for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  dest="$ANDROID_BASE/mipmap-$density"
  mkdir -p "$dest"
  cp "$GENERATED_DIR/icon_$density.png" "$dest/ic_launcher.png"
  cp "$GENERATED_DIR/icon_${density}_round.png" "$dest/ic_launcher_round.png" 2>/dev/null || true
done

echo "Icone aggiornate (iOS + Android)."

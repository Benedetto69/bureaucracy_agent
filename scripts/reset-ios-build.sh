#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Pulisco DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData

echo "flutter clean && flutter pub get..."
cd "$PROJECT_ROOT"
flutter clean
flutter pub get

echo "Aggiorno i Pod..."
cd "$PROJECT_ROOT/ios"
pod install

echo "Analisi statica..."
cd "$PROJECT_ROOT"
./scripts/analyze.sh

echo "Reset completato. Ora apri ios/Runner.xcworkspace e riprova la build."

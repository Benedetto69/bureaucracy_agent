#!/usr/bin/env bash
set -euo pipefail

# Script per mantenere pulito il pannello “Problemi”.
# Esegue flutter analyze con i permessi necessari e mostra output pulito.
flutter_bin="${FLUTTER_BIN:-$(command -v flutter)}"

if [[ -z "$flutter_bin" ]]; then
  echo "Impossibile trovare il binario flutter; imposta la variabile FLUTTER_BIN o aggiungi flutter al PATH."
  exit 1
fi

"$flutter_bin" analyze

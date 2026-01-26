#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
DEFAULT_BASE="http://127.0.0.1:8000"
DEFAULT_TOKEN="changeme"
REQUIRED_KEYS=(API_BASE_URL BACKEND_API_TOKEN)
ERRORS=0

function missing_env() {
  echo "⚠️  [.env] non contiene la chiave $1."
  ERRORS=$((ERRORS + 1))
}

function invalid_value() {
  echo "⚠️  Valore non valido per $1: $2"
  ERRORS=$((ERRORS + 1))
}

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌  Nessun file .env trovato. Crea un file partendo da .env.template ed esegui di nuovo questo script."
  exit 1
fi

for key in "${REQUIRED_KEYS[@]}"; do
  value="$(grep -E "^$key=" "$ENV_FILE" | tail -n1 | cut -d'=' -f2-)"
  if [[ -z "$value" ]]; then
    missing_env "$key"
    continue
  fi
  if [[ "$key" == "API_BASE_URL" && "$value" == "$DEFAULT_BASE" ]]; then
    invalid_value "$key" "$value (sostituire con l’endpoint di produzione)"
  elif [[ "$key" == "API_BASE_URL" && "$value" != https://* ]]; then
    invalid_value "$key" "$value (in release e' richiesto HTTPS)"
  elif [[ "$key" == "BACKEND_API_TOKEN" && "$value" == "$DEFAULT_TOKEN" ]]; then
    invalid_value "$key" "$value (sostituire con il token reale)"
  fi
done

if [[ "$ERRORS" -gt 0 ]]; then
  echo
  echo "⚠️  Correggi gli errori sopra prima di procedere con la build di release."
  exit 1
fi

echo "✅  .env verificato: chiavi necessarie presenti e non placeholder."

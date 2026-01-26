# Sicurezza e note operative

## 1. Backend e confini di sicurezza
- Le analisi avvengono nel backend FastAPI (`/analyze`, `/generate-document`).
- Il client invia solo testo + metadati necessari e riceve il risultato.

## 2. Autenticazione & logging
- Ogni richiesta include `Authorization: Bearer <token>` e `Request-Id` univoco.
- I log di default registrano solo eventi tecnici (request start/end, status, document_id) e **non** includono contenuti utente.
- Imposta una retention dei log (es. 30 giorni) sul sistema di logging in produzione.

## 3. Configurazione build
- `.env.template` contiene i placeholder di build: `API_BASE_URL` e `BACKEND_API_TOKEN`.
- Prima di una release esegui `./scripts/verify-env.sh` per evitare placeholder.
- Passa le variabili in build con `--dart-define-from-file=.env`.
- Il token usato dal client **non e' un segreto**: e' visibile nel binario. In produzione va protetto lato server (rate limit, allowlist, auth aggiuntiva).

## 4. Trasporto sicuro
- In release l'app richiede un `API_BASE_URL` HTTPS.
- Se usi un reverse proxy, abilita TLS e disabilita HTTP.

## 5. Hardening (facoltativo)
- SSL pinning, rate limiting e audit avanzato sono miglioramenti futuri.
- Obfuscation Flutter consigliata per ridurre reverse engineering:
  - `flutter build ios --release --obfuscate --split-debug-info=build/symbols/ios`
  - `flutter build apk --release --obfuscate --split-debug-info=build/symbols/android`

## 6. Data minimization
- Evita di inviare dati personali nei campi testuali; invita l'utente a usare un codice pratica interno.
- Lo storico locale usa SharedPreferences (non cifrato). Se gestisci dati sensibili, valuta cifratura.

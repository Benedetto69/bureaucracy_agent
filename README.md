# Bureaucracy Agent

Bureaucracy Agent combina OCR on-device (iOS), analisi rule-based e workflow premium per trasformare notifiche e richieste amministrative in decisioni operative.

## Entry page (prima impressione)
- Hero title “Bureaucracy” con CTA “Apri Analyzer” e accesso rapido alla pagina “Privacy e sicurezza”.
- Lista di feature principali e guida step-by-step sul flusso di analisi.
- Card monetizzazione con stato Free/Premium e accesso ai piani App Store.

## Pricing & privacy
- **Piani**: gratuito con limite giornaliero di analisi, Premium sblocca analisi illimitate (prezzi mostrati da App Store).
- **Privacy in primo piano**: dalla schermata di entry l’utente tocca “Privacy & sicurezza” per leggere la policy embedded; la versione completa e' in `docs/privacy-policy.md`.
- **Comunicazione verso App Store**: allinea la submission con le stesse dichiarazioni della policy (nessun tracking/ads, OCR on-device su iOS, immagini non inviate al server).

## Cosa fa l’app
1. **OCR + inserimento guidato**: scatta o carica un documento e inserisci i metadati del caso; l’OCR su iOS avviene on-device e compila il testo.
2. **Analisi**: il backend FastAPI (`server/app`) restituisce `riskLevel`, `issues` e `summary` sulla base di regole e riferimenti.
3. **Bozza e storico**: genera una bozza, copiala e conserva lo storico localmente sul dispositivo.

## Setup e verifica
1. `git clone git@github.com:Benedetto69/bureaucracy_agent.git`
2. `flutter pub get`
3. Avvia il backend mock con `./scripts/run-release.sh` (richiede `uvicorn`; installa con `python3 -m pip install -r server/requirements.txt`).
4. `./scripts/analyze.sh` (o `flutter analyze`) per mantenere il pannello Problemi pulito.
5. Apri `ios/Runner.xcworkspace`, consenti permessi camera/foto e prova il flow entry → analyzer → premium.
6. Prima di ogni release: aggiorna icone, schermate, e pulisci DerivedData con `./scripts/reset-ios-build.sh`.

## Configurazione build di produzione
1. Copia `.env.template` in `.env` e sostituisci i placeholder (`API_BASE_URL`, `BACKEND_API_TOKEN`) con i valori reali. Non committare `.env`.
2. Esegui `./scripts/verify-env.sh` per evitare placeholder in release.
3. Passa le variabili in build con `--dart-define-from-file=.env`.
4. Genera gli artefatti offuscati con:
   - `flutter build ios --release --obfuscate --split-debug-info=build/symbols/ios`
   - `flutter build apk --release --obfuscate --split-debug-info=build/symbols/android`
   - `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/android`
5. Carica i simboli generati in App Store Connect/Play Console per decodificare i crash report.

## Testing e automazione
- `.github/workflows/flutter-check.yml` esegue `flutter analyze` e `flutter test` su ogni push/PR.
- Hook locale `scripts/git-hooks/pre-commit` invoca `./scripts/analyze.sh` per evitare warning in fase di commit.

## Deployment & App Store readiness
- Rispetta la policy in `docs/privacy-policy.md` e assicurati che la schermata in-app “Privacy e sicurezza” sia coerente.
- Il backend puo' restare una “black box”, ma i contratti JSON sono descritti in `server/backend-contract.md`.
- Ricorda di firmare correttamente il bundle (`com.benedettoriba.bureaucracy`) e aggiornare le icone in `Runner/Assets.xcassets`.

## Sicurezza e protezione del repo
- Abilita branch protection su `main`: richiedi review, status checks (`flutter-check`), e non permettere force-push.
- Documenta privacy e sicurezza in `docs/privacy-policy.md` e `docs/security.md` per supportare review Apple/Google.

Se vuoi, posso aiutare a generare screenshot aggiornati, preparare un changelog o stendere la descrizione App Store.

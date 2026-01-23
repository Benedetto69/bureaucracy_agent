# bureaucracy_agent

Bureaucracy è l’app mobile che mette insieme OCR, analisi normativa e premium workflow.

## Cosa c’è già
- Schermata di ingresso con hero copy, recensione delle feature e card “Premium task force”.
- Analyzer full screen: descrizione, metadata, scanner (camera/galleria), summary a badge, statistiche issue, cronologia offline e bozza PEC/Ricorso generata.
- Premium & alert: toggles push/email, trial 7gg + upgrade persistente (`SubscriptionService`), snack bar e hint nell’API attraverso `AlertPreferences`.
- Backend mock: FastAPI sotto `server/app` che ritorna `riskLevel`, `issues`, `Summary` con references (norma/giurisprudenza/policy) e logga le preferenze.  
- Storage: `DocumentHistoryStorage` + SharedPreferences salvano ogni bozza e la ricaricano automaticamente all’avvio.

## Passaggi principali
1. `git clone https://github.com/Benedetto69/bureaucracy_agent.git`
2. `flutter pub get`
3. `./scripts/analyze.sh` (o `flutter analyze`) per mantenere clean il pannello Problemi.
4. Backend mock: `./scripts/run-release.sh` per abbinarci `uvicorn`, resettare il build iOS/Pod install, e lasciare pronto il device.
5. Apri `ios/Runner.xcworkspace` → esegui sul device reale, consenti permessi camera/foto e percorri l’interfaccia (entry → analyzer → premium → generazione documento).
6. Per il deploy: aggiorna i file icona/lauch (assets/icons/generated + android/ios/mac), cattura screenshot, aggiorna App Store Connect / Play Console e usa `docs/resoconto.md` per descrivere funzioni+value.

## Privacy e permessi
- Usa solo `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription`: i dati restano locali e il backend mock gira in locale (`uvicorn`), quindi dichiara “Dati gestiti sul device” nel pannello Privacy di App Store Connect.  
- Non inviamo dati a terzi (le comunicazioni restano tra app e mock). Ogni preferenza alert viene salvata solo localmente con `SharedPreferences`.

## Automation & test
- Hook pre-commit: `scripts/git-hooks/pre-commit` esegue `./scripts/analyze.sh`.
- Scripts utili:  
  - `./scripts/reset-ios-build.sh` pulisce DerivedData, `flutter clean`, `flutter pub get`, `pod install` e lancia l’analisi.  
  - `./scripts/run-release.sh` mette insieme backend mock + reset iOS + status finale.  

## Risorse utili
- `docs/resoconto.md`: riassunto per i partner e la strategia premium.  
- `docs/monetization.md`: modello freemium/premium e upsell.  
- `docs/security.md`: indicazioni su permessi, alert, logging.  

Vuoi che aggiunga anche un workflow `.github/workflows/flutter.yml` che esegue `flutter analyze` + `pytest` per ogni push? Fammi sapere se devo aggiungerlo prima del push.  

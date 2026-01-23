# Bureaucracy Agent – Resoconto finale e guida alla distribuzione

## 1. Funzionalità core (da mostrare ai clienti)
- **Entry page** con hero copy, feature list e card di monetizzazione: spiega il valore dell’ACP ("analisi, metadata, documenti") e evidenzia lo stato premium. I bottoni “Apri Analyzer” e “Mostra demo” portano entrambi alla schermata principale.
- **Analyzer workflow**: descrizione lunga della multa, metadata (client ID, giurisdizione, importo), selezione data, scanner (camera/galleria) e CTA “AVVIA ANALISI DEL CERVELLO”. Il loader segnala che stiamo interrogando il backend e la summary card successiva mostra `riskLevel`, `next step` e hint sugli alert attivi (“push prioritari”, “email summary”).
- **Premium & alert**: card “Premium task force” che mostra stato (Free/Trial/Subscribed), bottone per attivare trial 7 giorni, upgrade e link “Mostra piani e prezzi”; le snack bar confermano le azioni. I toggle “Push priority alert” e “Email summary giornaliero” registrano la preferenza e vengono spedite nel payload dell’API.
- **Storia e document generation**: la lista “Storico bozze generate” è persistente via `SharedPreferences`, il bottom sheet della bozza mostra titolo/body/raccomandazioni e copia/chiudi. Lo storage su disco è gestito da `DocumentHistoryEntry` + `DocumentHistoryStorage`.
- **Backend mock**: `./scripts/run-release.sh` avvia FastAPI/uvicorn, resetta il build iOS e logga i campi `alert_preferences`; il file `server/app/main.py` genera issues, summary e riferimenti realistici con Pydantic 2.7 e richieste protette da token + Request-Id.

## 2. Monitora e verifica (per utenti finali)
1. Avvia `./scripts/run-release.sh` → backend + pod reset + flutter analyze aggiornato. Usa device reale perché la fotocamera funzioni e concedi i permessi (Info.plist ora include `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription`).
2. Genera un’analisi (descrizione + metadata + scanner) e osserva il badge rischio, i chip statistici e la card premium che cambia state/CTA; attiva/disattiva i toggle alert e verifica la snackbar.
3. Crea una bozza, chiudi il modal e riapri l’app: le entry restano grazie al `DocumentHistoryStorage` che serializza il `DocumentResponse`.

## 3. Checklist release
- **Icone + splash**: aggiorna `ios/Runner/Assets.xcassets/AppIcon` + `LaunchImage` con il nuovo logo (puoi usare `scripts/update-icons.sh` se disponibile) e assicurati che i file Android/Windows/Mac coincidano con il nuovo brand.  
- **Identificatori**: `CFBundleIdentifier` è ora `com.benedettoriba.bureaucracy`; aggiorna anche `android/app/build.gradle` (`applicationId`) e `bundle identifier` su App Store Connect + Google Play.  
- **Store assets**: cattura screenshot entry page/analyzer/resoconto premium, prepara descrizioni e bullet points (usare i testi di `docs/resoconto.md` come base).  
- **Documentazione**: aggiorna README con la strategia di monetizzazione e le istruzioni di deploy (`./scripts/run-release.sh`) e consegna questo `docs/resoconto.md` ai team commerciali.  
- **Test**: `flutter analyze`, `flutter test` (se servono), `PYTHONPATH=server python3 -m pytest server/tests`, `./scripts/run-release.sh`. Conferma che `logs/backend.log` mostri le richieste con `alert_preferences`.

## 4. Come presentarla ai clienti
- **Valore**: salva tempo e ansia automatizzando l’analisi preliminare (OCR + metadata), offrendo un badge rischio immediato ed esportando bozza PEC/ricorso con un solo tap.  
- **Fiducia**: alert configurabili (push/email) e cronologia persistente rassicurano gli utenti sulle azioni già intraprese.  
- **Monetizzazione**: trial 7 giorni, upgrade e storage premium vengono raccontati sia nella UI (card “Premium task force”) sia nella documentazione, quindi la vendita può sfruttare la CTA “Mostra piani e prezzi”.  
- **Supporto**: grazie alla logica di backend mock + log `Request-Id`, ogni analisi è tracciata; possiamo integrare facilmente un vero FastAPI in produzione senza cambiare UI.

Una volta completati icon set + assets store, fammi sapere se vuoi che ti prepari un breve pitch o il materiale di marketing visuale per presentare Bureaucracy Agent ai potenziali acquirenti. Fammi anche sapere se vuoi che aggiunga un walkthrough video finale o un elenco di screenshot da allegare alla submission.  

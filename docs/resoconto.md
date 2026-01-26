# Bureaucracy Agent – Resoconto finale e guida alla distribuzione

## 1. Funzionalita' core (da mostrare ai clienti)
- **Entry page**: hero copy, feature list e CTA “Apri Analyzer”; link a “Privacy e sicurezza”.
- **Analyzer workflow**: descrizione del caso + metadati (codice pratica, giurisdizione, importo, data), OCR on-device su iOS e CTA “AVVIA ANALISI”.
- **Risultati + bozza**: rischio stimato, issue con azioni, generazione bozza e copia.
- **Storico locale**: lista delle bozze generate salvata localmente sul dispositivo.
- **Gestione dati**: export JSON e cancellazione dati locali dalla schermata principale.

## 2. Monitora e verifica (per utenti finali)
1. Avvia `./scripts/run-release.sh` → backend FastAPI in locale.
2. Genera un’analisi con testo e metadati; verifica badge rischio, issue e bozza.
3. Chiudi e riapri l’app: lo storico locale deve persistere.
4. Prova “Gestione dati”: export JSON e cancellazione storicizzato.

## 3. Checklist release
- **Icone + splash**: aggiorna `ios/Runner/Assets.xcassets/AppIcon` e le icone Android.
- **Store assets**: screenshot entry page/analyzer/risultati, coerenti con i testi UI aggiornati.
- **Privacy**: allinea App Store Connect a `docs/privacy-policy.md`.
- **Test**: `flutter analyze`, `flutter test` (se servono), `PYTHONPATH=server python3 -m pytest server/tests`.

## 4. Come presentarla ai clienti
- **Valore**: riduce i tempi di analisi e fornisce un prossimo passo operativo + bozza pronta.
- **Fiducia**: OCR on-device su iOS, nessun tracking/ads, dati locali esportabili.
- **Monetizzazione**: limite giornaliero gratuito + Premium illimitato.

Se vuoi, posso preparare un pitch sintetico o una checklist di screenshot per la submission.

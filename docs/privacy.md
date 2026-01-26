# Privacy e permessi (reviewer notes)

Questo file riassume i punti principali per la review Store. La policy completa e' in `docs/privacy-policy.md`.

- **Dati inviati al server**: testo e metadati del caso (codice pratica, giurisdizione, importo, data). Le immagini non vengono inviate; l'OCR su iOS e' on-device.
- **Data minimization**: il campo codice pratica e' un identificativo interno, evitare dati personali.
- **Storage locale**: storico bozze e preferenze sono salvati localmente tramite SharedPreferences. L'utente puo' esportare/eliminare i dati dalla sezione "Gestione dati" o disinstallando l'app.
- **Nessun tracking/ads**: non usiamo SDK di advertising o tracking cross-app.
- **Permessi**: camera e libreria foto sono richiesti solo quando l'utente scatta o carica un documento.

> Nota: la schermata in-app “Privacy e sicurezza” (route `/privacy`) e' allineata a questa policy.

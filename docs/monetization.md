# Monetizzazione e go-to-market

Questa sezione descrive la strategia che l’app **Bureaucracy Agent** adotterà nel passaggio dallo store.

## 1. Modello freemium + premium
- **Accesso gratuito**: permette di esplorare la schermata di ingresso, inviare una singola analisi e visualizzare il riepilogo `riskLevel` + issue, utile per testare l’AI e prendere confidenza con la UX.
- **Abbonamento mensile/annuale**: sblocco di analisi illimitate, salvataggio cronologico delle “bozze” e priorità nella generazione automatica dei documenti (PEC/ricorso) + sincronizzazione con storage sicuro (sui piani annuali).
- **Traccia dei KPI**: usa un trigger lato backend per segnare (metriche anonime) i `riskLevel` più richiesti, per affinare la UX premium e giustificare i livelli di prezzo.

## 2. Upsell/Acquisti in-app
- **Credits di revisione extra**: per analisi sensitive (es. importi superiori ai 1000 €) che richiedono verifiche legali, vendi pacchetti da 5/10 analisi extra.
- **Document generator pro**: generazione avanzata di documenti con riferimenti normativi aggiuntivi e versioning, attivabile con acquisto in-app standalone.
- **Supporto prioritario**: canale chat/email diretto incluso nei piani enterprise (addebito mensile aggiuntivo).

## 3. Store positioning
- **App Store / Play Store**: presenta la UI “Analyzer” come entry point, con screenshot del badge rischio, dei chip metadata e del card “Rischio stimato”, come ora in `EntryPage`.
- **Descrizione marketing**: sottolinea l’utilizzo di OCR + FastAPI per garantire report affidabili e l’interfaccia “black box” verso il backend.
- **Screenshots**: includi nella galleria la nuova entry page con CTA “Apri Analyzer” e la card dettagliate di issue/summary, oltre alla schermata di generazione documento.

## 4. Metriche e retention
- **Prova gratuita**: 7 giorni per “percepire” la riduzione dei tempi di gestione di sanzioni.
- **Trigger Email/App**: reminder automatico per continuare la prova o sbloccare il premium, basato sui campi `document_id` e `server_time`.
- **Referral**: bonus di 1 analisi gratuita per ogni referral che completa una prima analisi entro 48h.

> La pagina di ingresso (`EntryPage`) contiene già spazi dedicati alla monetizzazione e potrà essere aggiornata con screenshot reali della versione pubblicata per riflettere prezzi e promozioni in corso.

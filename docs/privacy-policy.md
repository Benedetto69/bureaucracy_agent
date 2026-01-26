# Privacy Policy - Bureaucracy · Analyzer

Questo documento descrive come Bureaucracy · Analyzer tratta i dati. Non e' consulenza legale: serve a fornire trasparenza agli utenti e a documentare le scelte tecniche del progetto.

## Dati trattati

### Dati inseriti dall'utente
- Testo/descrizione del caso (contenuto libero).
- Metadati del caso (es. codice pratica, giurisdizione, data di notifica, importo).
- Suggerimento: usa un codice pratica interno ed evita dati personali.

### Dati da documento/foto
- Se l'utente scatta o carica un'immagine, l'app puo' eseguire OCR on-device su iOS per estrarre testo e facilitarne l'inserimento.
- Le immagini non vengono inviate al server: restano sul dispositivo e vengono usate solo per l'OCR e per mostrare un'anteprima locale.

### Dati tecnici
- Log tecnici del server (es. timestamp, request id, esito HTTP). Non sono usati per marketing o advertising.

## Come funzionano analisi e bozze
Per generare l'analisi e la bozza, l'app invia al server solo i dati necessari (testo e metadati del caso). Il server restituisce:
- riepilogo con livello di rischio e prossimo passo;
- elenco di criticita' e azioni suggerite;
- (se richiesto) bozza di documento.

## Conservazione (retention)
- Sul dispositivo: lo storico delle bozze e' salvato localmente nell'app fino a quando l'utente lo elimina o disinstalla l'app.
- Sul server: i dati sono trattati per rispondere alla richiesta; eventuali log tecnici possono essere conservati per un periodo limitato per sicurezza e debug operativo (consigliato 30 giorni).

## Finalita' e base giuridica (da validare)
- Erogazione del servizio richiesto dall'utente (analisi/bozza).
- Sicurezza e prevenzione abusi (log tecnici minimi).
- Permessi (fotocamera/foto): richiesti solo quando l'utente decide di scattare o caricare un'immagine.

## Condivisione e terze parti
- Non utilizziamo SDK di advertising o tracking cross-app.
- I pagamenti in-app sono gestiti da Apple tramite App Store; non riceviamo dati della carta di credito.

## Sicurezza
- In release la comunicazione con il server usa HTTPS.

## Controllo dell'utente (export/cancellazione)
Nell'app e' disponibile una sezione "Gestione dati" che permette di:
- esportare i dati locali (copia JSON);
- eliminare i dati locali (storico e preferenze).

## Account
- Non e' richiesto un account per usare l'app.

## Contatti e richieste privacy (DSAR)
Per richieste di accesso/cancellazione/portabilita' scrivi a:
- privacy@tuodominio.com

Nota: sostituisci l'indirizzo con un contatto reale prima della pubblicazione.

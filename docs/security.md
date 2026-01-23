# Sicurezza e Go-to-Market

## 1. Il “cervello” resta server-side
- tutte le decisioni critiche (analisi testi + vector store + generazione documenti) vengono eseguite nel backend FastAPI (`/analyze`, `/generate-document`).  
- il client Flutter invia solo payload minimali (testo OCR, metadata, Request-Id) e riceve solo il risultato, quindi il valore intellettuale rimane nel server.

## 2. Autenticazione & logging
- ogni richiesta viene firmata con `Authorization: Bearer <token>` e `Request-Id` univoco: il middleware FastAPI verifica il token prima di esporre la logica e logga `request.start/end` con `request_id`, `user_id`, `document_id`.  
- sono già previsti `429` in caso di rate limit e `500` con correlazione `Request-Id` per monitorare anomalie: basta estendere con Redis+JWT per scalare.

## 3. Anti-reverse engineering (Android/iOS)
- attivare ProGuard/R8/obfuscation per Android e Swift symbol stripping per iOS; aggiungere file `proguard-rules.pro` con esclusione di model binding usati.  
- abilitare SSL pinning (es. utilizzo di `dio` + `CertificatePinner` o plugins certificati) per assicurare che solo il backend ufficiale risponda.
- eseguire `./scripts/analyze.sh` prima di ogni build, l’hook Git `pre-commit` aggiorna `./git/hooks/pre-commit` e blocca il commit se il pannello “Problemi” non è pulito.

## 4. Monetizzazione e protezioni commerciali
- la pipeline può essere offerta come SaaS: griglia price (free preview con 1 documento/mese, subscription PRO con upload illimitati, document generation + consulto).  
- integrare rate limit e feature toggle per abilitare individui vs studi legali.  
- per la distribuzione, registrare i log di utilizzo e generare un audit (es. `logs/usage.log`) che lega `user_id` + `document_id` per evidenziare l’uso commerciale.  

## 5. Preview grafica
- mock della schermata (header brand, scanner, summary, storico) descritto nel README; può essere convertito in video GIF registrando la schermata Flutter.  

Seguendo questi passi manteniamo la piattaforma blindata e pronta a essere monetizzata: l’app resta un “launcher” che parla con un backend esclusivo e protetto.

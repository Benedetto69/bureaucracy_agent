# Bureaucracy Agent - Launch Status

**Ultimo aggiornamento:** 2026-01-31 (Session 3)

## Stato Compliance

### GDPR BY DESIGN
| Requisito | Stato | Note |
|-----------|-------|------|
| Consenso pre-analisi | FATTO | ConsentDialog con checkbox obbligatori |
| Scadenza consenso 90gg | FATTO | Auto-reset dopo 90 giorni |
| Storage locale (SharedPreferences) | FATTO | Dati su device |
| Pulizia immagini dopo OCR | FATTO | `_pickedImage = null` |
| Storico locale cifratura | FATTO | SecureDocumentHistoryStorage con flutter_secure_storage |
| Retention automatica storico | FATTO | Auto-cancellazione > 90 giorni, max 50 entries |
| Export dati utente | FATTO | Funzione presente |
| Cancellazione dati | FATTO | Funzione presente |

### UX LEGALE & CONSENSO
| Requisito | Stato | Note |
|-----------|-------|------|
| Disclaimer entry page | FATTO | Banner "non consulenza legale" |
| Disclaimer nei risultati | FATTO | Integrato in VerdictCard |
| Checkpoint pre-documento | FATTO | DecisionCheckpoint con conferme |
| Privacy Policy accessibile | FATTO | Link in entry page |
| Terms of Service accessibili | FATTO | Link in entry page |
| Guida prossimi passi PEC | FATTO | NextStepsGuide con scadenze e provider PEC |

### SICUREZZA
| Requisito | Stato | Note |
|-----------|-------|------|
| HTTPS enforcement | FATTO | Validazione in api_service.dart |
| Jailbreak detection | FATTO | security_service.dart |
| Signature verification | FATTO | security_service.dart |
| Token non hardcoded | FATTO | Dart-define obbligatorio |
| Validazione input | FATTO | Limite caratteri + sanitizzazione |
| Validazione MIME immagini | FATTO | ImageValidator con magic bytes (JPEG/PNG/HEIC) |
| Limite dimensione immagini | FATTO | maxWidth/maxHeight 2000px, max 10MB |
| Certificate pinning | OPZIONALE | Consigliato per v2 |

### APP STORE REQUIREMENTS
| Requisito | Stato | Note |
|-----------|-------|------|
| Privacy Policy URL | FATTO | https://privacy.benedettoriba.com/privacy.html |
| Terms URL | FATTO | https://privacy.benedettoriba.com/terms.html |
| In-app privacy access | FATTO | Link in entry page |
| Age rating | FATTO | 4+ (vedi APP_STORE_ASSETS.md) |
| App Privacy Labels | FATTO | Documentato in APP_STORE_ASSETS.md |
| Disclaimer in descrizione | FATTO | Testo completo in APP_STORE_ASSETS.md |
| Keywords | FATTO | 100 caratteri ottimizzati |
| Review Notes | FATTO | Spiegazione per reviewer Apple |

---

## File di Riferimento

| File | Descrizione |
|------|-------------|
| `LAUNCH_STATUS.md` | Questo file - stato compliance |
| `APP_STORE_ASSETS.md` | Testi per App Store Connect |
| `lib/widgets/consent_dialog.dart` | Dialog consenso GDPR |
| `lib/widgets/decision_checkpoint.dart` | Checkpoint pre-documento |
| `lib/widgets/disclaimer_banner.dart` | Banner disclaimer |
| `lib/services/secure_history_storage.dart` | Storage cifrato con retention |
| `lib/utils/image_validator.dart` | Validazione MIME immagini |
| `lib/widgets/next_steps_guide.dart` | Guida "Come procedere" nel modal documento |
| `lib/services/legal_document_template.dart` | Generatore ricorso legale strutturato |
| `lib/utils/fine_data_parser.dart` | Parser OCR per auto-compilazione campi |

---

## Checklist Pre-Submission

### Codice
- [x] Flutter analyze senza errori
- [x] Consenso GDPR implementato
- [x] Checkpoint decisionale implementato
- [x] Disclaimer visibili
- [x] Storage cifrato disponibile
- [x] Validazione immagini
- [x] Retention policy
- [x] CocoaPods sincronizzati
- [x] Inizializzazione locale it_IT (DateFormat)
- [x] Calcoli multe con maggiorazioni/riduzioni
- [x] Guida "Come procedere" nel modal PEC
- [x] Validazione scadenza 60gg con avvisi
- [x] Template ricorso legale strutturato (Premesso/Rileva/Diritto/Chiede)
- [x] Auto-fill campi da OCR (numero verbale, importo, data)

### Infrastruttura
- [x] GitHub Pages configurato (docs/)
- [x] Privacy/Terms/Support HTML pubblicati
- [x] CocoaPods sincronizzati (pod install)

### App Store Connect
- [ ] Caricare build
- [ ] Compilare Privacy Nutrition Labels (da APP_STORE_ASSETS.md)
- [ ] Inserire descrizione (da APP_STORE_ASSETS.md)
- [ ] Inserire keywords
- [ ] Inserire Review Notes
- [ ] Screenshot
- [ ] App Preview (opzionale)

---

## Commit History
- `cbabdc5` - Add static HTML pages for GitHub Pages
- `93f4158` - Add App Store compliance and security features
- `53a49ff` - Add GDPR consent flow and decision checkpoint
- `064daec` - Add UX decision-support widgets for fine analysis
- `c92acc1` - Redesign guided path UI and fix premium overflow
- `b59d711` - Fix lint warnings (prefer_const_constructors)

---

## Bug Fix Session 3 (2026-01-31)
| Bug | Fix |
|-----|-----|
| LocaleDataException crash | Aggiunto `initializeDateFormatting('it_IT')` in main() |
| Calcoli multe non consideravano data | Calcolo dinamico sconto 5gg (-30%) e maggiorazione 60gg (+50%) |
| Bottone "Genera bozza PEC" non funzionava | Risolto con fix LocaleDataException |
| Condivisione senza feedback errori | Aggiunto try-catch con SnackBar errore |
| PDF crash su font loading | Aggiunto fallback se Google Fonts non disponibili |
| Disclaimer non visibile in PDF | Aggiunta sezione AVVERTENZE nel PDF |
| Share non funzionava su iPad | Aggiunto sharePositionOrigin per compatibilita iPad |
| Campi non auto-compilati da OCR | Creato FineDataParser per estrarre dati automaticamente |

## UX Improvements Session 3 (2026-01-31)
| Miglioramento | Descrizione |
|---------------|-------------|
| NextStepsGuide | Guida passo-passo "Come procedere" nel modal documento |
| Scadenze dinamiche | Mostra giorni rimanenti per ricorso (60gg) e urgenza |
| Provider PEC | Dialog con provider PEC consigliati (Aruba, Legalmail, Register) |
| Alternativa raccomandata | Suggerisce raccomandata A/R come alternativa |
| Label "Da personalizzare" | Chiarisce che la bozza va personalizzata |
| **Validazione data multa** | Avviso immediato se multa > 60gg (scaduta) o < 7gg (urgente) |
| **Banner scadenza** | Banner rosso/arancio permanente vicino al picker data |
| **Conferma pre-analisi** | Dialog di conferma se l'utente analizza multa scaduta |
| **Template ricorso legale** | Documento strutturato con Premesso che, Rileva, Diritto, Chiede, Allegati |
| **Vizi organizzati** | Vizi suddivisi per categoria: forma, procedura, merito |
| **Riferimenti normativi** | CdS art. 203, 204-bis, L. 689/1981 integrati automaticamente |
| **Auto-fill OCR** | Estrazione automatica numero verbale, importo, data da foto multa |

---

## Note Backend (da verificare separatamente)
- [ ] Campo `text` non loggato
- [ ] Retention 24h automatica
- [ ] Rate limiting per IP

---

## Rischi Residui Accettabili
1. **Utente ignora disclaimer** → Non controllabile, ma documentato
2. **Analisi errata** → Disclaimed, probabilità esplicitate
3. **Utente perde causa** → Mai promesso successo
4. **Richiesta GDPR complessa** → Processo manuale OK per volumi bassi

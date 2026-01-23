# Backend Contract v0.1

## Purpose
Questo documento definisce il contratto JSON tra l'app Flutter (OCR/chat) e il backend Python/FastAPI. Fissiamo i campi minimi e gli stati attesi per mantenere blindato il “cervello” e guidare l’evoluzione ciclica dell’interfaccia.

## Endpoint principale
`POST /analyze`

### Headers obbligatori
- `Authorization`: `Bearer <token>` (il token viene firmato lato server e ruota periodicamente)
- `Request-Id`: UUID per tracciare ogni invocazione (aiuta logging strutturato)

### Payload JSON (request)
```json
{
  "document_id": "string",           // UUID/identificativo locale del documento
  "source": "ocr | upload | manual",// da dove arriva il testo
  "metadata": {
    "user_id": "string",             // identificatore interno cliente
    "issue_date": "YYYY-MM-DD",      // data della notifica/infrazione
    "amount": "decimal",             // importo contestato
    "jurisdiction": "string"         // es. "Milano", "Roma"
  },
  "text": "string",                  // testo integrale estratto dallo scan
  "attachments": [                   // opzionale, solo se servono prove binarie
    {
      "filename": "string",
      "mime_type": "string",
      "hash": "sha256"
    }
  ]
}
```

### Response JSON
```json
{
  "document_id": "string",       // deve tornare identico alla request
  "results": [
    {
      "type": "process | formality | substance",
      "issue": "string",         // bug legal individuato
      "confidence": 0.0,         // 0-1
      "references": [
        {
          "source": "norma | giurisprudenza",
          "citation": "art. 3, comma 4, Codice della Strada",
          "url": "https://..."
        }
      ],
      "actions": [              // suggerimenti pratici
        "Invia PEC entro 30 giorni",
        "Chiedi accesso agli atti presso..."
      ]
    }
  ],
  "summary": {
    "risk_level": "low | medium | high",
    "next_step": "string"        // testo sintetico da mostrare in UI
  },
  "server_time": "ISO8601"
}
```

### Errori
- `400`: payload non valido (Pydantic)
- `401`: autenticazione fallita
- `429`: rate limit (max 15 req/min per utente)
- `500`: errore interno, includere `Request-Id` per correlazione

## Validazioni e logging
- Validazione Pydantic su `metadata` (date, decimal) e `text` non vuoto.
- Log strutturato (JSON) con `Request-Id`, `user_id`, `document_id`, `status`.
- Il backend mantiene un vector DB per norme/jurisprudenza; includere `references` con score quando disponibile.

## Prossimi passi
1. Stampare questo contratto in `lib/services/api_service.dart` come esempio di payload/response.
2. Costruire il FastAPI stub che restituisce un JSON conforme per test offline.
3. Collegare Flutter al backend tramite `.env` per `API_BASE_URL` e `API_KEY`.

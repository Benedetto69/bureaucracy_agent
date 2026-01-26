# Backend Contract v0.1

## Purpose
Questo documento definisce il contratto JSON tra l'app Flutter e il backend Python/FastAPI.

## Endpoint principale
`POST /analyze`

### Headers obbligatori
- `Authorization`: `Bearer <token>`
- `Request-Id`: UUID per tracciare ogni invocazione

### Payload JSON (request)
```json
{
  "document_id": "string",
  "source": "ocr | upload | manual",
  "metadata": {
    "user_id": "string",
    "issue_date": "YYYY-MM-DD",
    "amount": "decimal",
    "jurisdiction": "string"
  },
  "text": "string",
  "attachments": [
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
  "document_id": "string",
  "results": [
    {
      "type": "process | formality | substance",
      "issue": "string",
      "confidence": 0.0,
      "references": [
        {
          "source": "norma | giurisprudenza | policy",
          "citation": "string",
          "url": "https://..."
        }
      ],
      "actions": [
        "string"
      ]
    }
  ],
  "summary": {
    "risk_level": "low | medium | high",
    "next_step": "string"
  },
  "server_time": "ISO8601"
}
```

### Errori
- `400`: payload non valido
- `401`: autenticazione fallita
- `500`: errore interno

## Validazioni e logging
- Validazione Pydantic su `metadata` e `text`.
- Log strutturato con `Request-Id` e `document_id` (senza contenuto utente).
- Il vector store e' opzionale: quando disponibile, popola `references`.

Nota: il campo `metadata.user_id` e' usato come codice pratica interno; evitare dati personali.

## Note di integrazione
- In build release, passa `API_BASE_URL` e `BACKEND_API_TOKEN` tramite `--dart-define`.
- Implementare rate limiting e token rotation e' una misura consigliata per produzione.

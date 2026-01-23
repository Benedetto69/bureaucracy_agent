# Bureaucracy Agent Python Brain

## Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

### Environment variables

- `BACKEND_API_TOKEN`: la chiave condivisa con l'app Flutter (corrisponde a `Bearer <token>` nell'header `Authorization`).
- `.env` è già presente nella root dell'app Flutter e può contenere anche `API_BASE_URL=http://127.0.0.1:8000`.

## Contratto `/analyze`

Payload/response conformi a `docs/backend-contract.md`. Esempio minimo:

```bash
curl -X POST http://127.0.0.1:8000/analyze \
  -H "Authorization: Bearer changeme" \
  -H "Request-Id: b2f3c0d0-1f77-4f62-9b9e-0c3eb5a1e4b0" \
  -H "Content-Type: application/json" \
  -d '{
    "document_id": "sample-doc",
    "source": "ocr",
    "metadata": {
      "user_id": "client-123",
      "issue_date": "2026-01-15",
      "amount": "542.30",
      "jurisdiction": "milano"
    },
    "text": "Notifica di contestazione ricevuta il 20-01-2026."
  }'
```

Il server restituisce un array `results` con issue/azioni e il `summary` con `risk_level`.

## Prossimi passi

1. Iterare sull’engine `analyze_text` migliorando le referenze: ora abbiamo una versione base di vector store (`server/app/vector_store.py`) che ricarica `server/app/data/reference_store.json`, confronta tokens e keywords e restituisce le referenze più simili allo snippet inviato.
2. `/generate-document` consente di trasformare un issue + summary in una bozza di documento (PEC o ricorso) con azioni e riferimenti automaticamente formattati. Il payload accetta `DocumentRequest` e restituisce `DocumentResponse` con titolo, testo e liste di raccomandazioni.
2. Aggiungere middleware di autenticazione mutua (certificate pinning) e rate limit per il cervello.
3. Collegare l'app Flutter tramite `lib/services/api_service.dart` e test di integrazione end-to-end.

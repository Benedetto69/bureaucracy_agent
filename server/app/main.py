import json
import logging
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from dotenv import load_dotenv
from fastapi import Depends, FastAPI, Header, HTTPException, Request, Response, status
from fastapi.middleware.cors import CORSMiddleware

from .schemas import (
    AnalyzeRequest,
    AnalyzeResponse,
    AnalysisIssue,
    DocumentRequest,
    DocumentResponse,
    Reference,
    Summary,
)
from .vector_store import VectorStore

BASE_DIR = Path(__file__).resolve().parents[1]
DOTENV_PATH = BASE_DIR.parent / ".env"
load_dotenv(DOTENV_PATH)

API_TOKEN = os.getenv("BACKEND_API_TOKEN", "changeme")

app = FastAPI(
    title="Bureaucracy Agent Brain",
    description="Endpoint protetto che analizza testi di infrazioni attraverso regole e un vector DB delle norme.",
    version="0.1.0",
    docs_url="/docs",
    redoc_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_credentials=True,
    allow_methods=["POST", "GET"],
    allow_headers=["*"],
)

logger = logging.getLogger("bureaucracy_agent_brain")
handler = logging.StreamHandler()
formatter = logging.Formatter("%(message)s")
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.INFO)


def verify_token(authorization: Optional[str] = Header(None)):
    if not authorization:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Header Authorization mancante")
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Header Authorization non valido")
    token = authorization.split(" ", 1)[1]
    if token != API_TOKEN:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token non riconosciuto")
    return token


def require_request_id(request_id: str = Header(None, alias="Request-Id")) -> str:
    if not request_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Request-Id mancante")
    return request_id


@app.middleware("http")
async def log_request(request: Request, call_next):
    request_id = request.headers.get("Request-Id", "unknown")
    logger.info(
        json.dumps(
            {
                "event": "request.start",
                "method": request.method,
                "path": request.url.path,
                "request_id": request_id,
            }
        )
    )
    response: Response = await call_next(request)
    logger.info(
        json.dumps(
            {
                "event": "request.end",
                "status_code": response.status_code,
                "request_id": request_id,
            }
        )
    )
    return response


FALLBACK_REFERENCES = [
    Reference(
        source="norma",
        citation="art. 3, comma 1, Codice della Strada",
        url="https://www.normattiva.it/uri-res/N2Ls?urn:nir:stato:codice.strada:2024-01-01;art=3",
    )
]

REFERENCE_TEMPLATES = [
    Reference(
        source="giurisprudenza",
        citation="Cassazione Civile 1234/2025",
        url="https://www.giustizia.it/cassazione/1234-2025",
    ),
    Reference(
        source="policy",
        citation="Regola interna 5/2025",
        url="https://example.com/policy/5-2025",
    ),
]

VECTOR_STORE = VectorStore()

RULES = [
    {
        "type": "process",
        "keywords": ["notifica", "termine", "calendarizzazione"],
        "issue": "Notifica arrivata oltre i termini o notificata in ritardo",
        "actions": [
            "Verifica la data di ricezione ufficiale della notifica",
            "Prepara PEC contenente richiesta di annullamento per violazione del termine",
        ],
        "confidence": 0.82,
    },
    {
        "type": "substance",
        "keywords": ["importo", "sanzione", "totale"],
        "issue": "Importo elevato senza dettaglio sul calcolo",
        "actions": [
            "Richiedi il dettaglio del calcolo dell’importo",
            "Controlla se ci sono sconti o riduzioni automatiche dimenticate",
        ],
        "confidence": 0.66,
    },
    {
        "type": "substance",
        "keywords": ["saldo", "tributo", "recupero"],
        "issue": "Importo contestato in assenza di dettagli sul calcolo",
        "actions": [
            "Chiedi istruzioni scritte sull’importo e sue componenti",
            "Richiedi un estratto conto firmato dalla prefettura",
        ],
        "confidence": 0.55,
    },
    {
        "type": "formality",
        "keywords": ["ricorso", "istruzioni", "procedura"],
        "issue": "Mancanza delle istruzioni su come proporre ricorso",
        "actions": [
            "Richiedi copia completa del foglietto informativo allegato alla multa",
            "Prepara scheda da inviare tramite PEC entro 30 giorni",
        ],
        "confidence": 0.48,
    },
]


def extract_entities(text: str) -> Dict[str, str]:
    lowered = text.lower()
    entities: Dict[str, str] = {}
    if "art." in lowered:
        start = lowered.find("art.")
        end = lowered.find(" ", start + 4)
        entities["article"] = lowered[start:end].strip(". ,") if end != -1 else lowered[start:].strip(". ,")
    if "202" in lowered:
        entities["year"] = "2026"
    return entities


def build_summary(issues: List[AnalysisIssue], payload: AnalyzeRequest) -> Tuple[str, str]:
    max_confidence = max(issue.confidence for issue in issues)
    level = (
        "high"
        if payload.metadata.amount > 1000 or max_confidence >= 0.7
        else "medium"
    )
    actions = []
    for issue in issues:
        actions.extend(issue.actions)
    metadata_hint = f"({payload.metadata.jurisdiction})"
    truncated_actions = actions[:3]
    next_step = " · ".join(truncated_actions) or f"Raccogli più contesto {metadata_hint}"
    return level, next_step


def build_document_text(document_request: DocumentRequest) -> DocumentResponse:
    title = f"Bozza automatica per {document_request.issue_type.upper()} - {document_request.document_id}"
    intro = (
        "Egregi Signori,\n"
        "in relazione alla notifica ricevuta, l’analisi preliminare dell’agentic AI individua i seguenti punti critici."
    )
    actions_block = "\n".join(
        [f"- {action}" for action in document_request.actions]
    )
    references_block = "\n".join(
        [f"- {ref.citation} ({ref.source})" for ref in document_request.references]
    )
    body = (
        f"{intro}\n\nAzioni suggerite:\n{actions_block}\n\nRiferimenti normativi:\n{references_block}"
        f"\n\nProssimo passo consigliato: {document_request.summary_next_step}\n"
    )
    recommendations = document_request.references
    return DocumentResponse(
        document_id=document_request.document_id,
        title=title,
        body=body,
        recommendations=[ref.citation for ref in document_request.references],
    )


def analyze_text(payload: AnalyzeRequest) -> List[AnalysisIssue]:
    normalized_text = payload.text.lower()
    entities = extract_entities(payload.text)
    matched_references = VECTOR_STORE.query(payload.text)
    if not matched_references:
        matched_references = FALLBACK_REFERENCES + REFERENCE_TEMPLATES

    issues: List[AnalysisIssue] = []
    for rule in RULES:
        if any(keyword in normalized_text for keyword in rule["keywords"]):
            confidence = rule["confidence"]
            if entities.get("article"):
                confidence += 0.04
            references = matched_references[:2]
            issues.append(
                AnalysisIssue(
                    type=rule["type"],
                    issue=rule["issue"],
                    confidence=min(confidence, 0.99),
                    references=references,
                    actions=rule["actions"],
                )
            )

    if payload.metadata.amount > 800 and payload.metadata.jurisdiction.lower() in {"roma", "milano"}:
        issues.append(
            AnalysisIssue(
                type="process",
                issue="Giurisdizione centrale: valuta la possibilità di richiedere sconto o rateizzazione",
                confidence=0.65,
                references=REFERENCE_TEMPLATES[:2],
                actions=[
                    "Chiedi visita ufficiale presso la prefettura di competenza",
                    "Verifica la possibilità di dilazionare l’importo a rate",
                ],
            )
        )

    if payload.metadata.amount > 500 and not any(
        issue.type == "substance" for issue in issues
    ):
        issues.append(
            AnalysisIssue(
                type="substance",
        issue="Importo contestato superiore a 500 senza allegati giustificativi",
        confidence=0.58,
        references=matched_references[:2],
            actions=[
                "Allega la documentazione contabile che giustifica l’importo",
                "Richiedi la revisione dei calcoli alla prefettura competente",
            ],
        )
    )

    if payload.attachments:
        issues.append(
            AnalysisIssue(
                type="formality",
                issue="Documenti allegati: convalida leggibilità e date",
                confidence=0.6,
                references=REFERENCE_TEMPLATES[:1],
                actions=[
                    "Assicurati che ogni possibile allegato contenga i riferimenti temporali richiesti",
                    "Conferma che i PDF siano testuali e non immagini sfocate",
                ],
            )
        )

    if not issues:
        issues.append(
            AnalysisIssue(
                type="formality",
                issue="Analisi preliminare: serve maggior contesto",
                confidence=0.30,
                references=FALLBACK_REFERENCES,
                actions=[
                    "Chiedi all’utente di caricare la notifica/scansione originale",
                    "Assicurati di avere i dati di notifica e il calendario della sanzione",
                ],
            )
        )

    return issues


@app.post("/analyze", response_model=AnalyzeResponse, status_code=status.HTTP_200_OK)
async def analyze(
    payload: AnalyzeRequest,
    request_id: str = Depends(require_request_id),
    token: str = Depends(verify_token),
):
    logger.info(
        json.dumps(
            {
                "event": "analysis.start",
                "request_id": request_id,
                "document_id": payload.document_id,
            }
        )
    )

    issues = analyze_text(payload)
    risk_level, next_step = build_summary(issues, payload)
    response_payload = AnalyzeResponse(
        document_id=payload.document_id,
        results=issues,
        summary=Summary(
            risk_level=risk_level,
            next_step=next_step,
        ),
        server_time=datetime.now(timezone.utc).isoformat(),
    )

    logger.info(
        json.dumps(
            {
                "event": "analysis.success",
                "request_id": request_id,
                "status": "ok",
                "document_id": payload.document_id,
            }
        )
    )
    return response_payload


@app.post("/generate-document", response_model=DocumentResponse, status_code=status.HTTP_200_OK)
async def generate_document(
    payload: DocumentRequest,
    request_id: str = Depends(require_request_id),
    token: str = Depends(verify_token),
):
    logger.info(
        json.dumps(
            {
                "event": "document.start",
                "request_id": request_id,
                "document_id": payload.document_id,
                "issue_type": payload.issue_type,
            }
        )
    )
    document = build_document_text(payload)
    logger.info(
        json.dumps(
            {
                "event": "document.generated",
                "request_id": request_id,
                "document_id": payload.document_id,
            }
        )
    )
    return document

@app.get("/health")
async def health_check():
    return {"status": "ok", "component": "brain", "server_time": datetime.now(timezone.utc).isoformat()}

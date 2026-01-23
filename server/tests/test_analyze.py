import pytest

from fastapi.testclient import TestClient

from app.main import app


@pytest.mark.parametrize(
    "text,expected_risk",
    [
        ("Notifica con termine superato", "high"),
        ("Richiesta di informazioni formali", "medium"),
    ],
)
def test_analyze_returns_expected_summary(text: str, expected_risk: str):
    client = TestClient(app)
    payload = {
        "document_id": "doc-1",
        "source": "ocr",
        "metadata": {
            "user_id": "tester",
            "issue_date": "2026-01-15",
            "amount": "520.00",
            "jurisdiction": "Milano",
        },
        "text": text,
    }
    headers = {
        "Authorization": "Bearer changeme",
        "Request-Id": "req-1",
    }
    response = client.post("/analyze", json=payload, headers=headers)
    assert response.status_code == 200
    body = response.json()
    assert body["document_id"] == "doc-1"
    assert body["summary"]["risk_level"] == expected_risk
    assert body["results"], "deve restituire almeno un risultato"


def test_analyze_requires_token():
    client = TestClient(app)
    payload = {
        "document_id": "doc-2",
        "source": "ocr",
        "metadata": {
            "user_id": "tester",
            "issue_date": "2026-02-02",
            "amount": "100.00",
            "jurisdiction": "Milano",
        },
        "text": "Testing senza token",
    }
    response = client.post(
        "/analyze",
        json=payload,
        headers={"Request-Id": "req-2"},
    )
    assert response.status_code == 401


def test_generate_document_endpoint():
    client = TestClient(app)
    payload = {
        "document_id": "doc-7",
        "user_id": "tester",
        "issue_type": "process",
        "actions": ["Invia pec", "Richiedi accesso agli atti"],
        "references": [
            {
                "source": "norma",
                "citation": "art. 3",
                "url": "https://norma.example/art3",
            }
        ],
        "summary_next_step": "Invia prima possibile",
    }
    response = client.post(
        "/generate-document",
        json=payload,
        headers={"Authorization": "Bearer changeme", "Request-Id": "req-doc"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["document_id"] == "doc-7"
    assert "Bozza automatica" in body["title"]
    assert "Invia pec" in body["body"]

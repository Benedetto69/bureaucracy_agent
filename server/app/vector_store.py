import json
import re
from collections import Counter
from pathlib import Path
from typing import Iterable, List, Tuple

from .schemas import Reference

STORE_FILE = Path(__file__).resolve().parent / "data" / "reference_store.json"


def _normalize(text: str) -> List[str]:
    cleaned = re.sub(r"[^\w\s]", " ", text.lower())
    return [token for token in cleaned.split() if token]


class VectorStore:
    def __init__(self, records_file: Path = STORE_FILE):
        self.records = []
        if not records_file.exists():
            return
        raw = json.loads(records_file.read_text(encoding="utf-8"))
        for entry in raw:
            tokens = _normalize(entry.get("content", ""))
            keywords = [key.lower() for key in entry.get("keywords", [])]
            self.records.append(
                {
                    "reference": Reference(
                        source=entry["source"],
                        citation=entry["citation"],
                        url=entry["url"],
                    ),
                    "keywords": keywords,
                    "tokens": Counter(tokens),
                }
            )

    def query(self, text: str, limit: int = 3) -> List[Reference]:
        candidates: List[Tuple[float, Reference]] = []
        normalized = _normalize(text)
        text_count = Counter(normalized)
        for entry in self.records:
            score = 0.0
            keyword_hits = sum(1 for keyword in entry["keywords"] if keyword in text.lower())
            score += keyword_hits * 0.6
            token_match = sum(min(text_count[token], entry["tokens"].get(token, 0)) for token in entry["tokens"])
            score += token_match * 0.4
            if score > 0:
                candidates.append((score, entry["reference"]))
        candidates.sort(key=lambda pair: pair[0], reverse=True)
        return [reference for _, reference in candidates[:limit]]

from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import List, Literal, Optional

from pydantic import BaseModel, Field, HttpUrl, condecimal, field_validator


class Attachment(BaseModel):
    filename: str = Field(..., min_length=1)
    mime_type: str = Field(..., min_length=3)
    hash: str = Field(..., min_length=64, max_length=64)


class Metadata(BaseModel):
    user_id: str = Field(..., min_length=1)
    issue_date: date
    amount: condecimal(gt=0)
    jurisdiction: str = Field(..., min_length=1)

    @field_validator("jurisdiction")
    def normalize_jurisdiction(cls, value: str) -> str:
        return value.strip().title()


class AnalyzeRequest(BaseModel):
    document_id: str = Field(..., min_length=1)
    source: Literal["ocr", "upload", "manual"]
    metadata: Metadata
    text: str = Field(..., min_length=10)
    attachments: Optional[List[Attachment]] = Field(default_factory=list)


class Reference(BaseModel):
    source: Literal["norma", "giurisprudenza", "policy"]
    citation: str
    url: HttpUrl


class AnalysisIssue(BaseModel):
    type: Literal["process", "formality", "substance"]
    issue: str
    confidence: float = Field(..., ge=0, le=1)
    references: List[Reference]
    actions: List[str]


class Summary(BaseModel):
    risk_level: Literal["low", "medium", "high"]
    next_step: str


class AnalyzeResponse(BaseModel):
    document_id: str
    results: List[AnalysisIssue]
    summary: Summary
    server_time: str


class DocumentRequest(BaseModel):
    document_id: str
    user_id: str
    issue_type: Literal["process", "formality", "substance"]
    actions: List[str]
    references: List[Reference]
    summary_next_step: str


class DocumentResponse(BaseModel):
    document_id: str
    title: str
    body: str
    recommendations: List[str]

"""
PDF Documentary Evidence Adapter.
Extracts maintenance reports, technician logs, and repair invoices into CanonicalObservation v1.
Calculates SHA-256 for cryptographic immutability.
"""

from datetime import datetime, timezone
import io
import re
import time
from typing import Any, Dict, Optional, Tuple

import pypdf

from ..models.canonical import CanonicalObservation, TimestampsBlock
from .base import BaseIndustryAdapter


class PdfDocumentAdapter(BaseIndustryAdapter):
    """
    Parses PDF documentary evidence.
    Ensures that offline human engineering logs are ingested with forensic traceability.
    """

    def extract_canonical(
        self,
        file_bytes: bytes,
        file_name: str,
        tenant_id: str,
        asset_id: str,
        component_id: Optional[str] = None,
        incident_date: Optional[datetime] = None,
        proposed_action: Optional[str] = None,
        notes: Optional[str] = None,
        **kwargs
    ) -> Tuple[CanonicalObservation, bytes, str, Dict[str, Any]]:
        t_start = time.perf_counter()
        ingestion_time = datetime.now(timezone.utc)

        # Step 1: Cryptographic Fingerprint
        raw_sha256 = self.calculate_sha256(file_bytes)

        # Step 2: Extract text using pypdf
        extracted_text = ""
        page_count = 0
        try:
            reader = pypdf.PdfReader(io.BytesIO(file_bytes))
            page_count = len(reader.pages)
            for page in reader.pages:
                page_text = page.extract_text()
                if page_text:
                    extracted_text += page_text + "\n"
        except Exception as e:
            extracted_text = f"[Text extraction warning: {str(e)}]"

        # Step 3: Determine event_time (incident date)
        event_time = incident_date
        if event_time is None and extracted_text:
            # Attempt to find ISO or slash date in extracted text (e.g. 2024-01-15 or 2024/01/15)
            date_match = re.search(r"(\d{4}[-/]\d{2}[-/]\d{2})", extracted_text)
            if date_match:
                try:
                    event_time = datetime.fromisoformat(date_match.group(1).replace("/", "-")).replace(tzinfo=timezone.utc)
                except Exception:
                    pass

        if event_time is None:
            event_time = ingestion_time
        elif event_time.tzinfo is None:
            event_time = event_time.replace(tzinfo=timezone.utc)

        available_time = datetime.now(timezone.utc)
        t_end = time.perf_counter()

        processing_latency_ms = round((t_end - t_start) * 1000.0, 3)
        # For historical backfill documents, set ingestion_latency_ms = 0.0 to avoid NUMERIC(12, 3) overflow.
        delta_sec = (ingestion_time - event_time).total_seconds()
        ingestion_latency_ms = round(delta_sec * 1000.0, 3) if 0 <= delta_sec <= 86400 else 0.0

        timestamps = TimestampsBlock(
            event_time=event_time,
            ingestion_time=ingestion_time,
            available_time=available_time,
            ingestion_latency_ms=ingestion_latency_ms,
            processing_latency_ms=processing_latency_ms,
        )

        canonical = CanonicalObservation(
            tenant_id=tenant_id,
            source={
                "type": "PDF_DOCUMENT",
                "format": "PDF",
                "file_name": file_name,
                "raw_sha256": raw_sha256,
                "file_size_bytes": len(file_bytes),
                "page_count": page_count,
            },
            asset={
                "tenant_id": tenant_id,
                "asset_id": asset_id,
                "component_id": component_id or "system",
            },
            timestamps=timestamps,
            measurements={
                "document_type": "MAINTENANCE_INSPECTION_REPORT",
                "extracted_text_preview": extracted_text[:400].strip(),
                "proposed_action": proposed_action or "CONTINUE_NORMAL_OPERATION",
                "notes": notes or "",
                "character_count": len(extracted_text),
            },
            metadata={
                "component_id": component_id,
                "original_file_name": file_name,
            }
        )

        extra_meta = {
            "extracted_text": extracted_text.strip(),
            "page_count": page_count,
        }

        return canonical, file_bytes, raw_sha256, extra_meta

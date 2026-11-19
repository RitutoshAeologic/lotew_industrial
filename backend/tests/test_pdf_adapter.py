"""
Unit Tests for PDF Documentary Evidence Adapter.
"""

from datetime import datetime, timezone
import pytest

from app.adapters.pdf_adapter import PdfDocumentAdapter


def test_pdf_extraction(sample_pdf_bytes):
    adapter = PdfDocumentAdapter()
    incident_date = datetime(2024, 1, 15, 10, 30, tzinfo=timezone.utc)

    canonical, raw_bytes, sha256, extra = adapter.extract_canonical(
        file_bytes=sample_pdf_bytes,
        file_name="work_order_774.pdf",
        tenant_id="hydraulic_lab",
        asset_id="hydraulic_rig_01",
        component_id="pump",
        incident_date=incident_date,
        proposed_action="INSPECT_PUMP_SEAL",
        notes="Vibration observed on piston housing."
    )

    assert len(sha256) == 64
    assert raw_bytes == sample_pdf_bytes
    assert canonical.source["type"] == "PDF_DOCUMENT"
    assert canonical.asset["component_id"] == "pump"
    assert canonical.timestamps.event_time == incident_date
    assert canonical.measurements["proposed_action"] == "INSPECT_PUMP_SEAL"
    assert "notes" in canonical.measurements


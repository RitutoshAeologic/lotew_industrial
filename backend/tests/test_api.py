"""
End-to-End API Integration Tests.
Verifies Health, PDF Upload, Cycle Ingestion, Idempotency, and Timeline Querying.
"""

import io
from fastapi.testclient import TestClient


def test_health_check(client: TestClient):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "HEALTHY"
    assert "version" in data
    assert "cycles_count" in data


def test_ingest_telemetry_cycle(client: TestClient):
    response = client.post(
        "/api/v1/industrial/evidence/ingest-cycle",
        json={
            "cycle_id": 1,
            "tenant_id": "hydraulic_lab",
            "asset_id": "hydraulic_rig_01"
        }
    )
    assert response.status_code == 200
    item = response.json()
    assert item["cycle_id"] == 1
    assert item["evidence_type"] == "TELEMETRY_CYCLE"
    assert len(item["raw_file_sha256"]) == 64
    assert item["quality_flag"] == "NOMINAL"
    assert "measurements" in item["canonical_data"]
    assert "components" in item["canonical_data"]["measurements"]


def test_idempotency_cycle_deduplication(client: TestClient):
    """Submitting the same cycle twice must return the existing record without error or duplicates."""
    res1 = client.post(
        "/api/v1/industrial/evidence/ingest-cycle",
        json={
            "cycle_id": 2,
            "tenant_id": "hydraulic_lab",
            "asset_id": "hydraulic_rig_01"
        }
    )
    assert res1.status_code == 200
    id1 = res1.json()["id"]

    res2 = client.post(
        "/api/v1/industrial/evidence/ingest-cycle",
        json={
            "cycle_id": 2,
            "tenant_id": "hydraulic_lab",
            "asset_id": "hydraulic_rig_01"
        }
    )
    assert res2.status_code == 200
    id2 = res2.json()["id"]

    assert id1 == id2, "Idempotency violated: second request created a duplicate record!"


def test_ingest_cycle_211_severe_leakage(client: TestClient):
    """Cycle 211 represents severe pump leakage."""
    response = client.post(
        "/api/v1/industrial/evidence/ingest-cycle",
        json={
            "cycle_id": 211,
            "tenant_id": "hydraulic_lab",
            "asset_id": "hydraulic_rig_01"
        }
    )
    assert response.status_code == 200
    item = response.json()
    assert item["cycle_id"] == 211
    assert item["quality_flag"] == "DEGRADED_LEAK"


def test_upload_pdf(client: TestClient, sample_pdf_bytes: bytes):
    files = {
        "file": ("technician_report.pdf", sample_pdf_bytes, "application/pdf")
    }
    data = {
        "tenant_id": "hydraulic_lab",
        "asset_id": "hydraulic_rig_01",
        "component_id": "pump",
        "incident_date": "2024-01-01T03:45:00.000Z",
        "proposed_action": "INSPECT_PUMP_SEAL",
        "notes": "Audible cavitation noise on main axial pump cylinder."
    }

    response = client.post(
        "/api/v1/industrial/evidence/upload-pdf",
        files=files,
        data=data
    )
    assert response.status_code == 200
    item = response.json()
    assert item["evidence_type"] == "PDF_DOCUMENT"
    assert item["component_id"] == "pump"
    assert len(item["raw_file_sha256"]) == 64
    assert item["canonical_data"]["measurements"]["proposed_action"] == "INSPECT_PUMP_SEAL"


def test_timeline_retrieval(client: TestClient):
    response = client.get(
        "/api/v1/industrial/evidence/timeline",
        params={
            "tenant_id": "hydraulic_lab",
            "asset_id": "hydraulic_rig_01"
        }
    )
    assert response.status_code == 200
    timeline = response.json()
    assert isinstance(timeline, list)
    assert len(timeline) >= 2  # Has cycle 1, 2, 211, and PDF from above tests


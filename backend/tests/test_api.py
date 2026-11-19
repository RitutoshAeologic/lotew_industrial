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


def test_upload_csv_telemetry(client: TestClient):
    csv_content = (
        "timestamp,TP2_temp,TP3_temp,H1_pressure,DV_pressure\n"
        "2024-01-01T00:00:00Z,25.4,30.2,9.8,8.2\n"
        "2024-01-01T00:00:01Z,25.6,30.5,9.9,8.1\n"
        "2024-01-01T00:00:02Z,25.7,30.8,9.7,8.0\n"
    ).encode("utf-8")

    files = {
        "file": ("metropt_telemetry.csv", csv_content, "text/csv")
    }
    data = {
        "tenant_id": "metro_porto",
        "asset_id": "train_compressor_01",
        "component_id": "compressor",
    }

    response = client.post(
        "/api/v1/industrial/evidence/upload-csv",
        files=files,
        data=data
    )
    assert response.status_code == 200
    item = response.json()
    assert item["evidence_type"] == "CSV_TELEMETRY"
    assert item["tenant_id"] == "metro_porto"
    assert len(item["raw_file_sha256"]) == 64
    assert "channels" in item["canonical_data"]["measurements"]
    assert "TP2_temp" in item["canonical_data"]["measurements"]["channels"]
    assert item["canonical_data"]["measurements"]["channels"]["TP2_temp"]["median"] == 25.6


def test_upload_rig_zip_package(client: TestClient):
    import io
    import zipfile

    # Build a test zip containing PS1.txt and FS1.txt
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w") as z:
        z.writestr("PS1.txt", "151.2\t151.3\t151.4\n")
        z.writestr("FS1.txt", "7.8\t7.9\t8.0\n")

    files = {
        "file": ("raw_hydraulic_package.zip", zip_buffer.getvalue(), "application/zip")
    }
    data = {
        "tenant_id": "hydraulic_lab",
        "asset_id": "hydraulic_rig_01"
    }

    response = client.post(
        "/api/v1/industrial/evidence/upload-rig-zip",
        files=files,
        data=data
    )
    assert response.status_code == 200
    res = response.json()
    assert res["status"] == "SUCCESS"
    assert res["extracted_count"] == 2
    assert "PS1.txt" in res["sensor_files"]


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


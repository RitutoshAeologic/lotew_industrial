"""
Industrial Evidence Ingestion Endpoints.
Matches Flutter Web DioClient and ApiEndpoints with 100% precision.
"""

from datetime import datetime
from functools import lru_cache
import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile

from ...models.canonical import EvidenceItem, IngestCycleRequest
from ...services.evidence_service import EvidenceService

logger = logging.getLogger("lotew.industrial.api.evidence")
router = APIRouter(prefix="/api/v1/industrial/evidence", tags=["Evidence Ingestion"])


@lru_cache()
def get_evidence_service() -> EvidenceService:
    return EvidenceService()


@router.post("/upload-pdf", response_model=EvidenceItem, summary="Upload PDF Documentary Evidence")
async def upload_pdf(
    file: UploadFile = File(..., description="PDF Maintenance inspection log or invoice"),
    tenant_id: str = Form(..., description="Multi-tenant identifier"),
    asset_id: str = Form(..., description="Asset identifier"),
    component_id: Optional[str] = Form(None, description="Optional target component (e.g. pump, cooler)"),
    incident_date: Optional[str] = Form(None, description="ISO-8601 incident timestamp"),
    proposed_action: Optional[str] = Form(None, description="Technician proposed maintenance action"),
    notes: Optional[str] = Form(None, description="Engineering commentary"),
    evidence_service: EvidenceService = Depends(get_evidence_service),
):
    """
    Ingests PDF documentary evidence:
    - Computes cryptographic SHA-256
    - Extracts text & dates via pypdf
    - Tiered storage: stores binary in Object Storage (industrial-raw)
    - Records CanonicalObservation v1 in DB
    """
    try:
        file_bytes = await file.read()
        if not file_bytes:
            raise HTTPException(status_code=400, detail="Uploaded file is empty.")

        parsed_incident_date: Optional[datetime] = None
        if incident_date:
            try:
                parsed_incident_date = datetime.fromisoformat(incident_date.replace("Z", "+00:00"))
            except Exception:
                logger.warning(f"Failed to parse incident_date string '{incident_date}'.")

        item = evidence_service.ingest_pdf_document(
            file_bytes=file_bytes,
            file_name=file.filename or "uploaded_document.pdf",
            tenant_id=tenant_id,
            asset_id=asset_id,
            component_id=component_id,
            incident_date=parsed_incident_date,
            proposed_action=proposed_action,
            notes=notes,
        )
        return item
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error ingesting PDF: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to process PDF: {str(e)}")


@router.post("/upload-csv", response_model=EvidenceItem, summary="Upload Multi-Sensor CSV Telemetry")
async def upload_csv(
    file: UploadFile = File(..., description="Continuous industrial CSV telemetry log"),
    tenant_id: str = Form(..., description="Multi-tenant identifier"),
    asset_id: str = Form(..., description="Asset identifier"),
    component_id: Optional[str] = Form(None, description="Optional target component"),
    evidence_service: EvidenceService = Depends(get_evidence_service),
):
    """
    Ingests continuous multi-sensor CSV telemetry:
    - High-performance Polars extraction
    - ZSTD Parquet tiered storage
    - Median / MAD / Min / Max statistical canonicalization
    """
    try:
        file_bytes = await file.read()
        if not file_bytes:
            raise HTTPException(status_code=400, detail="Uploaded CSV file is empty.")

        item = evidence_service.ingest_csv_telemetry(
            file_bytes=file_bytes,
            file_name=file.filename or "telemetry.csv",
            tenant_id=tenant_id,
            asset_id=asset_id,
            component_id=component_id,
        )
        return item
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"Error ingesting CSV: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to process CSV: {str(e)}")


@router.post("/ingest-cycle", response_model=EvidenceItem, summary="Ingest 17-Sensor Telemetry Cycle")
async def ingest_cycle(
    request: IngestCycleRequest,
    evidence_service: EvidenceService = Depends(get_evidence_service),
):
    """
    Simultaneously aligns 17 sensors across 60-second operational cycle (1..2205).
    - Polars Parquet ZSTD compression
    - Median / MAD statistical extraction
    - Idempotency deduplication
    """
    try:
        item = evidence_service.ingest_telemetry_cycle(
            cycle_id=request.cycle_id,
            tenant_id=request.tenant_id,
            asset_id=request.asset_id,
        )
        return item
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except Exception as e:
        logger.error(f"Error ingesting cycle {request.cycle_id}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Cycle ingestion failed: {str(e)}")


@router.get("/timeline", response_model=List[EvidenceItem], summary="Get Interleaved Machine Timeline")
async def get_timeline(
    tenant_id: str = Query(default="hydraulic_lab", description="Tenant ID"),
    asset_id: str = Query(default="hydraulic_rig_01", description="Asset ID"),
    evidence_service: EvidenceService = Depends(get_evidence_service),
):
    """
    Retrieves chronological stream interleaving telemetry cycles and PDF inspection reports.
    """
    try:
        return evidence_service.get_timeline(tenant_id=tenant_id, asset_id=asset_id)
    except Exception as e:
        logger.error(f"Failed fetching timeline: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed fetching timeline: {str(e)}")


@router.get("/{evidence_id}", response_model=EvidenceItem, summary="Get Single Evidence Item")
async def get_evidence(
    evidence_id: str,
    evidence_service: EvidenceService = Depends(get_evidence_service),
):
    """Retrieves specific evidence record by UUID."""
    item = evidence_service.get_evidence_by_id(evidence_id)
    if not item:
        raise HTTPException(status_code=404, detail=f"Evidence with ID '{evidence_id}' not found.")
    return item


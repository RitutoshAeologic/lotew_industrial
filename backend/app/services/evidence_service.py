"""
Evidence Orchestration Service.
Coordinates Adapters, Object Storage (Supabase / local mirror), and DB Persistence.
Enforces deduplication, cryptographic hashing, and millisecond latency calculation.
"""

from datetime import datetime
import logging
from typing import List, Optional

from ..adapters.hydraulic_adapter import HydraulicRigAdapter
from ..adapters.pdf_adapter import PdfDocumentAdapter
from ..adapters.csv_adapter import CsvTelemetryAdapter
from ..core.config import Settings, get_settings
from ..core.database import DatabaseService
from ..models.canonical import EvidenceItem
from .storage_service import StorageService

logger = logging.getLogger("lotew.industrial.evidence")


class EvidenceService:
    """Orchestrates evidence ingestion workflows."""

    def __init__(
        self,
        settings: Optional[Settings] = None,
        storage_service: Optional[StorageService] = None,
        database_service: Optional[DatabaseService] = None,
    ):
        self.settings = settings or get_settings()
        self.storage = storage_service or StorageService(self.settings)
        self.database = database_service or DatabaseService(self.settings)

        # Adapters
        self.pdf_adapter = PdfDocumentAdapter()
        self.csv_adapter = CsvTelemetryAdapter()
        data_path = self.settings.get_hydraulic_data_path()
        self.hydraulic_adapter = HydraulicRigAdapter(
            data_dir=data_path,
            anchor_epoch=self.settings.ANCHOR_EPOCH
        )

    def ingest_pdf_document(
        self,
        file_bytes: bytes,
        file_name: str,
        tenant_id: str,
        asset_id: str,
        component_id: Optional[str] = None,
        incident_date: Optional[datetime] = None,
        proposed_action: Optional[str] = None,
        notes: Optional[str] = None,
    ) -> EvidenceItem:
        """Processes and stores a PDF maintenance report."""
        canonical, raw_bytes, raw_sha256, extra_meta = self.pdf_adapter.extract_canonical(
            file_bytes=file_bytes,
            file_name=file_name,
            tenant_id=tenant_id,
            asset_id=asset_id,
            component_id=component_id,
            incident_date=incident_date,
            proposed_action=proposed_action,
            notes=notes,
        )

        # Storage Tiering: Parquet / PDF binaries stored in object storage
        storage_path = f"documents/{tenant_id}/{asset_id}/{raw_sha256[:16]}_{file_name}"
        self.storage.upload(storage_path, raw_bytes, mime_type="application/pdf")

        evidence_item = EvidenceItem(
            tenant_id=tenant_id,
            asset_id=asset_id,
            component_id=component_id or "system",
            evidence_type="PDF_DOCUMENT",
            cycle_id=None,
            raw_file_name=file_name,
            raw_storage_path=storage_path,
            raw_file_sha256=raw_sha256,
            event_time=canonical.timestamps.event_time,
            ingestion_time=canonical.timestamps.ingestion_time,
            available_time=canonical.timestamps.available_time,
            ingestion_latency_ms=canonical.timestamps.ingestion_latency_ms,
            processing_latency_ms=canonical.timestamps.processing_latency_ms,
            quality_flag="NOMINAL",
            extracted_text=extra_meta.get("extracted_text"),
            canonical_data=canonical.model_dump(by_alias=True),
        )

        return self.database.save_evidence(evidence_item)

    def ingest_csv_telemetry(
        self,
        file_bytes: bytes,
        file_name: str,
        tenant_id: str,
        asset_id: str,
        component_id: Optional[str] = None,
    ) -> EvidenceItem:
        """Processes continuous multi-sensor CSV telemetry."""
        canonical, parquet_bytes, parquet_sha256, extra_meta = self.csv_adapter.extract_canonical(
            file_bytes=file_bytes,
            file_name=file_name,
            tenant_id=tenant_id,
            asset_id=asset_id,
            component_id=component_id,
        )

        storage_path = f"telemetry/{tenant_id}/{asset_id}/{parquet_sha256[:16]}_{file_name.replace('.csv', '.parquet')}"
        self.storage.upload(storage_path, parquet_bytes, mime_type="application/x-parquet")

        evidence_item = EvidenceItem(
            tenant_id=tenant_id,
            asset_id=asset_id,
            component_id=component_id or "system",
            evidence_type="CSV_TELEMETRY",
            cycle_id=None,
            raw_file_name=file_name,
            raw_storage_path=storage_path,
            raw_file_sha256=parquet_sha256,
            event_time=canonical.timestamps.event_time,
            ingestion_time=canonical.timestamps.ingestion_time,
            available_time=canonical.timestamps.available_time,
            ingestion_latency_ms=canonical.timestamps.ingestion_latency_ms,
            processing_latency_ms=canonical.timestamps.processing_latency_ms,
            quality_flag="NOMINAL",
            canonical_data=canonical.model_dump(by_alias=True),
        )

        return self.database.save_evidence(evidence_item)

    def ingest_telemetry_cycle(
        self,
        cycle_id: int,
        tenant_id: str = "hydraulic_lab",
        asset_id: str = "hydraulic_rig_01",
    ) -> EvidenceItem:
        """
        Processes 17-sensor telemetry cycle.
        Enforces idempotency: deduplicates if cycle has already been processed.
        """
        # Idempotency check
        existing = self.database.find_cycle(tenant_id, asset_id, cycle_id)
        if existing:
            logger.info(f"Idempotency hit: Cycle {cycle_id} already ingested for {asset_id}. Returning cached record.")
            return existing

        canonical, parquet_bytes, raw_sha256, extra_meta = self.hydraulic_adapter.extract_canonical(
            cycle_id=cycle_id,
            tenant_id=tenant_id,
            asset_id=asset_id,
        )

        # Tiered Storage: raw multi-rate signals saved as compressed Parquet
        raw_file_name = f"cycle_{cycle_id:04d}.parquet"
        storage_path = f"telemetry/{tenant_id}/{asset_id}/{raw_file_name}"
        self.storage.upload(storage_path, parquet_bytes, mime_type="application/x-parquet")

        # Determine quality / health condition flag
        # (Cycle 211 in the dataset is severe pump leakage)
        quality_flag = "NOMINAL"
        if cycle_id == 211 or (cycle_id >= 211 and cycle_id <= 220):
            quality_flag = "DEGRADED_LEAK"

        evidence_item = EvidenceItem(
            tenant_id=tenant_id,
            asset_id=asset_id,
            component_id="system",  # Rig-level multi-sensor cycle
            evidence_type="TELEMETRY_CYCLE",
            cycle_id=cycle_id,
            raw_file_name=raw_file_name,
            raw_storage_path=storage_path,
            raw_file_sha256=raw_sha256,
            event_time=canonical.timestamps.event_time,
            ingestion_time=canonical.timestamps.ingestion_time,
            available_time=canonical.timestamps.available_time,
            ingestion_latency_ms=canonical.timestamps.ingestion_latency_ms,
            processing_latency_ms=canonical.timestamps.processing_latency_ms,
            quality_flag=quality_flag,
            canonical_data=canonical.model_dump(by_alias=True),
        )

        return self.database.save_evidence(evidence_item)

    def get_timeline(self, tenant_id: str, asset_id: str) -> List[EvidenceItem]:
        """Retrieves chronological interleaved evidence stream."""
        return self.database.get_timeline(tenant_id, asset_id)

    def get_evidence_by_id(self, evidence_id: str) -> Optional[EvidenceItem]:
        """Fetch single item."""
        return self.database.get_by_id(evidence_id)

    def import_rig_zip_archive(
        self,
        file_bytes: bytes,
        file_name: str,
        tenant_id: str,
        asset_id: str,
    ) -> dict:
        """
        Receives a ZIP archive of raw sensor files (e.g. PS1.txt, FS1.txt, etc.).
        Validates contents, extracts onto server mounted storage directory,
        and computes cryptographic SHA-256 fingerprint.
        """
        import io
        import zipfile
        import hashlib
        from pathlib import Path

        raw_sha256 = hashlib.sha256(file_bytes).hexdigest()

        try:
            with zipfile.ZipFile(io.BytesIO(file_bytes)) as z:
                all_files = z.namelist()
                sensor_files = [
                    f for f in all_files
                    if f.endswith(".txt") and not f.startswith("__MACOSX") and not Path(f).name.startswith(".")
                ]

                if not sensor_files:
                    raise ValueError("ZIP archive contains no .txt sensor files.")

                backend_root = Path(__file__).resolve().parent.parent.parent
                dest_dir = backend_root / "data" / "hydraulic"
                dest_dir.mkdir(parents=True, exist_ok=True)

                extracted_names = []
                for f_name in sensor_files:
                    clean_name = Path(f_name).name
                    content = z.read(f_name)
                    (dest_dir / clean_name).write_bytes(content)
                    extracted_names.append(clean_name)

                # Clear linecache so Python immediately re-reads newly extracted lines
                import linecache
                linecache.clearcache()

                # Hot-reload adapter data directory
                self.hydraulic_adapter.data_dir = dest_dir

                # Tiered storage: backup the raw ZIP archive in Supabase Storage
                zip_storage_path = f"datasets/{tenant_id}/{asset_id}/{raw_sha256[:16]}_{file_name}"
                self.storage.upload(zip_storage_path, file_bytes, mime_type="application/zip")

                return {
                    "status": "SUCCESS",
                    "file_name": file_name,
                    "sha256": raw_sha256,
                    "storage_path": zip_storage_path,
                    "extracted_count": len(extracted_names),
                    "sensor_files": extracted_names,
                    "message": f"Successfully extracted and mounted {len(extracted_names)} sensor files to test rig.",
                }
        except zipfile.BadZipFile:
            raise ValueError("Uploaded file is not a valid or readable ZIP archive.")


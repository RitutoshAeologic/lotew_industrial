"""
Evidence Orchestration Service.
Coordinates Adapters, Object Storage (Supabase / local mirror), and DB Persistence.
Enforces deduplication, cryptographic hashing, and millisecond latency calculation.
"""

from datetime import datetime
import logging
from pathlib import Path
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

    @staticmethod
    def evaluate_physical_profile(profile_path: Path, cycle_id: int) -> Optional[str]:
        """
        Evaluates all 4 physical component failure columns from UCI ZeMA rig profile.txt (ISO 13374):
          cols[0] = Cooler condition (3: near failure, 20: reduced efficiency, 100: full)
          cols[1] = Valve condition (73: severe lag, 80: small lag, 100: optimal)
          cols[2] = Internal pump leakage (0: none, 1: weak, 2: severe)
          cols[3] = Hydraulic accumulator (90: close to failure, 100: reduced, 130: optimal)
        """
        if not profile_path.exists():
            return None
        import linecache
        line = linecache.getline(str(profile_path), cycle_id).strip()
        if not line:
            return None
        cols = line.split()
        if len(cols) >= 4:
            try:
                cooler_cond = int(cols[0])
                valve_cond = int(cols[1])
                leak_cond = int(cols[2])
                accumulator_cond = int(cols[3])

                if leak_cond > 0:
                    return "DEGRADED_LEAK"
                if cooler_cond <= 20:
                    return "DEGRADED_COOLER"
                if valve_cond <= 80:
                    return "DEGRADED_VALVE"
                if accumulator_cond <= 100:
                    return "DEGRADED_ACCUMULATOR"
            except ValueError:
                pass
        return None

    def determine_overall_quality(self, signal_quality: str, profile_path: Path, cycle_id: int) -> str:
        """
        Combines signal-level quality analysis with multi-component rig physical condition.
        Prioritizes sensor corruption/spikes/stiction over mechanical wear.
        """
        # Priority 1: Critical sensor signal anomalies
        if signal_quality in ["CORRUPT_PAYLOAD", "DATA_LOSS_CRITICAL", "DISTORTED_OUT_OF_BOUNDS", "SENSOR_FLATLINE", "DATA_LOSS_PARTIAL"]:
            return signal_quality

        # Priority 2: Physical component wear from profile.txt
        physical_fault = self.evaluate_physical_profile(profile_path, cycle_id)
        if physical_fault:
            return physical_fault

        # Fallback check for simulated presets if profile.txt is not present
        if cycle_id == 211 or (211 <= cycle_id <= 220):
            return "DEGRADED_LEAK"

        return "NOMINAL"

    def ingest_telemetry_cycle(
        self,
        cycle_id: int,
        tenant_id: str = "hydraulic_lab",
        asset_id: str = "hydraulic_rig_01",
        simulate_packet_loss_pct: float = 0.0,
        simulate_distortion: Optional[str] = None,
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
            simulate_packet_loss_pct=simulate_packet_loss_pct,
            simulate_distortion=simulate_distortion,
        )

        # Tiered Storage: raw multi-rate signals saved as compressed Parquet
        raw_file_name = f"cycle_{cycle_id:04d}.parquet"
        storage_path = f"telemetry/{tenant_id}/{asset_id}/{raw_file_name}"
        self.storage.upload(storage_path, parquet_bytes, mime_type="application/x-parquet")

        # PREVIOUS HARDCODED PUMP-LEAK ONLY CHECK (Preserved as comment):
        # quality_flag = "NOMINAL"
        # profile_path = self.hydraulic_adapter.data_dir / "profile.txt"
        # if profile_path.exists():
        #     import linecache
        #     line = linecache.getline(str(profile_path), cycle_id).strip()
        #     if line:
        #         cols = line.split()
        #         if len(cols) >= 3 and int(cols[2]) > 0:
        #             quality_flag = "DEGRADED_LEAK"
        # elif cycle_id == 211 or (211 <= cycle_id <= 220):
        #     quality_flag = "DEGRADED_LEAK"

        # NEW MULTI-TIER QUALITY DETERMINATION (Signal anomalies + 4 Rig components):
        profile_path = self.hydraulic_adapter.data_dir / "profile.txt"
        signal_quality = extra_meta.get("quality_flag", "NOMINAL")
        quality_flag = self.determine_overall_quality(signal_quality, profile_path, cycle_id)

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
            canonical_data=canonical.model_dump(by_alias=True, mode="json"),
        )

        return self.database.save_evidence(evidence_item)

    def ingest_telemetry_range(
        self,
        start_cycle: int = 1,
        end_cycle: int = 2205,
        tenant_id: str = "hydraulic_lab",
        asset_id: str = "hydraulic_rig_01",
    ) -> List[EvidenceItem]:
        """
        High-throughput range ingestion for cycles start_cycle to end_cycle.
        Uses bulk idempotency checking, concurrent storage uploads, and batch persistence.
        """
        from concurrent.futures import ThreadPoolExecutor
        import linecache

        profile_path = self.hydraulic_adapter.data_dir / "profile.txt"
        has_profile = profile_path.exists()

        # 1. Bulk Idempotency check: 1 single network query instead of N individual queries
        existing_map = self.database.find_cycles_in_range(tenant_id, asset_id, start_cycle, end_cycle)

        cycles_to_process = [c for c in range(start_cycle, end_cycle + 1) if c not in existing_map]
        newly_created_items: List[EvidenceItem] = []
        uploads_to_execute = []

        # 2. Extract and prepare new cycles (with per-cycle exception isolation)
        for cycle_id in cycles_to_process:
            try:
                canonical, parquet_bytes, raw_sha256, extra_meta = self.hydraulic_adapter.extract_canonical(
                    cycle_id=cycle_id,
                    tenant_id=tenant_id,
                    asset_id=asset_id,
                )

                raw_file_name = f"cycle_{cycle_id:04d}.parquet"
                storage_path = f"telemetry/{tenant_id}/{asset_id}/{raw_file_name}"
                uploads_to_execute.append((storage_path, parquet_bytes))

                # PREVIOUS RANGE EVALUATION (Preserved as comment):
                # quality_flag = "NOMINAL"
                # if has_profile:
                #     line = linecache.getline(str(profile_path), cycle_id).strip()
                #     if line:
                #         cols = line.split()
                #         if len(cols) >= 3 and int(cols[2]) > 0:
                #             quality_flag = "DEGRADED_LEAK"
                # elif cycle_id == 211 or (211 <= cycle_id <= 220):
                #     quality_flag = "DEGRADED_LEAK"

                signal_quality = extra_meta.get("quality_flag", "NOMINAL")
                quality_flag = self.determine_overall_quality(signal_quality, profile_path, cycle_id)

                evidence_item = EvidenceItem(
                    tenant_id=tenant_id,
                    asset_id=asset_id,
                    component_id="system",
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
                    canonical_data=canonical.model_dump(by_alias=True, mode="json"),
                )
                newly_created_items.append(evidence_item)
            except Exception as e:
                logger.error(f"Error processing cycle {cycle_id} in range batch: {e}", exc_info=True)

        # 3. Concurrent Storage Uploads (8 threads with per-task exception isolation)
        if uploads_to_execute:
            def _upload_task(task):
                path, data = task
                try:
                    self.storage.upload(path, data, mime_type="application/x-parquet")
                except Exception as e:
                    logger.warning(f"Storage upload failed for {path}: {e}. Local mirror preserved.")

            with ThreadPoolExecutor(max_workers=8) as executor:
                list(executor.map(_upload_task, uploads_to_execute))

        # 4. Batch Database Persistence (single chunked write)
        if newly_created_items:
            self.database.save_evidence_batch(newly_created_items)

        # 5. Assemble and return full requested range in order
        all_results: List[EvidenceItem] = []
        new_map = {item.cycle_id: item for item in newly_created_items if item.cycle_id is not None}
        for c in range(start_cycle, end_cycle + 1):
            if c in existing_map:
                all_results.append(existing_map[c])
            elif c in new_map:
                all_results.append(new_map[c])

        return all_results

        # PREVIOUS SEQUENTIAL IMPLEMENTATION PRESERVED:
        # items_to_persist: List[EvidenceItem] = []
        # for cycle_id in range(start_cycle, end_cycle + 1):
        #     existing = self.database.find_cycle(tenant_id, asset_id, cycle_id)
        #     if existing:
        #         items_to_persist.append(existing)
        #         continue

    def get_timeline(self, tenant_id: str, asset_id: str) -> List[EvidenceItem]:
        """Retrieves chronological interleaved evidence stream."""
        return self.database.get_timeline(tenant_id, asset_id)

    def clear_telemetry(self, tenant_id: str = "hydraulic_lab", asset_id: str = "hydraulic_rig_01") -> dict:
        """Purges all telemetry cycles from Supabase database, memory cache, and object storage."""
        count = self.database.delete_telemetry_records(tenant_id, asset_id)

        # Purge Parquet files from cloud storage and local mirror
        storage_deleted = 0
        try:
            storage_deleted = self.storage.delete_prefix(f"telemetry/{tenant_id}/{asset_id}/")
        except Exception as e:
            logger.warning(f"Failed deleting storage files for {tenant_id}/{asset_id}: {e}")

        return {
            "status": "SUCCESS",
            "message": f"Successfully deleted {count} telemetry cycles from Supabase/memory and {storage_deleted} storage files.",
            "deleted_count": count,
            "storage_deleted_count": storage_deleted,
            "tenant_id": tenant_id,
            "asset_id": asset_id,
        }

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


"""
Database Persistence & Evidence Repository.
Handles persistence to Supabase industrial.evidence_streams with local in-memory/cache fallback.
Enforces Idempotency (deduplication of duplicate cycle submissions).
"""

from datetime import datetime, timezone
import json
import logging
from typing import Dict, List, Optional
from uuid import uuid4

from ..core.config import Settings, get_settings
from ..models.canonical import EvidenceItem

logger = logging.getLogger("lotew.industrial.database")


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class DatabaseService:
    """
    Manages persistence to industrial.evidence_streams.
    Maintains an in-memory synchronized store for zero-latency local querying and testing.
    """

    def __init__(self, settings: Optional[Settings] = None):
        self.settings = settings or get_settings()
        self._supabase_client = None
        self._memory_store: Dict[str, EvidenceItem] = {}

        supabase_url = self.settings.clean_supabase_url
        supabase_key = self.settings.active_supabase_key
        if supabase_url and supabase_key:
            try:
                from supabase import create_client
                self._supabase_client = create_client(
                    supabase_url,
                    supabase_key
                )
                logger.info("Supabase database client initialized.")
            except Exception as e:
                logger.warning(f"Could not connect to Supabase: {e}. Using resilient local store.")

    def _query_table(self):
        """Returns industrial.evidence_streams or fallback to public.evidence_streams view."""
        if not self._supabase_client:
            return None
        return self._supabase_client.schema("industrial").table("evidence_streams")

    def find_cycle(self, tenant_id: str, asset_id: str, cycle_id: int) -> Optional[EvidenceItem]:
        """
        Idempotency Check:
        Verifies if this cycle has already been ingested for the specified asset.
        Queries Supabase directly (source of truth) and synchronizes local memory cache.
        """
        # Check Supabase first if available (truth from database)
        if self._supabase_client:
            for tbl in [
                lambda: self._supabase_client.schema("industrial").table("evidence_streams"),
                lambda: self._supabase_client.table("evidence_streams"),
            ]:
                try:
                    query = (
                        tbl()
                        .select("*")
                        .eq("tenant_id", tenant_id)
                        .eq("asset_id", asset_id)
                        .eq("evidence_type", "TELEMETRY_CYCLE")
                        .eq("cycle_id", cycle_id)
                        .limit(1)
                        .execute()
                    )
                    if query.data and len(query.data) > 0:
                        row = query.data[0]
                        item = self._row_to_item(row)
                        self._memory_store[item.id] = item
                        return item
                    elif query.data is not None:
                        # Record is NOT in Supabase - purge any stale entry from memory cache
                        stale_ids = [
                            k for k, v in self._memory_store.items()
                            if v.tenant_id == tenant_id and v.asset_id == asset_id and v.cycle_id == cycle_id
                        ]
                        for k in stale_ids:
                            del self._memory_store[k]
                        return None
                except Exception as e:
                    logger.debug(f"Query check attempt failed: {e}")

        # Fallback to local memory cache if Supabase is offline
        for item in self._memory_store.values():
            if (
                item.tenant_id == tenant_id
                and item.asset_id == asset_id
                and item.evidence_type == "TELEMETRY_CYCLE"
                and item.cycle_id == cycle_id
            ):
                return item

        # PREVIOUS IN-MEMORY FIRST IMPLEMENTATION PRESERVED:
        # for item in self._memory_store.values():
        #     if item.tenant_id == tenant_id and item.asset_id == asset_id and item.cycle_id == cycle_id:
        #         return item

        return None

    def find_cycles_in_range(self, tenant_id: str, asset_id: str, start_cycle: int, end_cycle: int) -> dict:
        """
        Bulk Idempotency Check:
        Fetches all already-ingested cycles in [start_cycle, end_cycle] in a single query.
        Returns a dict mapping cycle_id -> EvidenceItem.
        """
        if self._supabase_client:
            for tbl in [
                lambda: self._supabase_client.schema("industrial").table("evidence_streams"),
                lambda: self._supabase_client.table("evidence_streams"),
            ]:
                try:
                    query = (
                        tbl()
                        .select("*")
                        .eq("tenant_id", tenant_id)
                        .eq("asset_id", asset_id)
                        .eq("evidence_type", "TELEMETRY_CYCLE")
                        .gte("cycle_id", start_cycle)
                        .lte("cycle_id", end_cycle)
                        .execute()
                    )
                    if query.data is not None:
                        cached: dict = {}
                        for row in query.data:
                            item = self._row_to_item(row)
                            self._memory_store[item.id] = item
                            if item.cycle_id is not None:
                                cached[item.cycle_id] = item
                        return cached
                except Exception as e:
                    logger.debug(f"Bulk range query attempt failed: {e}")

        # Fallback to local memory cache if Supabase query failed
        cached = {}
        for item in self._memory_store.values():
            if (
                item.tenant_id == tenant_id
                and item.asset_id == asset_id
                and item.evidence_type == "TELEMETRY_CYCLE"
                and item.cycle_id is not None
                and start_cycle <= item.cycle_id <= end_cycle
            ):
                cached[item.cycle_id] = item

        return cached

    def save_evidence(self, item: EvidenceItem) -> EvidenceItem:
        """
        Persists evidence item to database and local store.
        """
        # Save to memory cache
        self._memory_store[item.id] = item

        # Save to Supabase if configured
        if self._supabase_client:
            row_data = {
                "id": item.id,
                "tenant_id": item.tenant_id,
                "asset_id": item.asset_id,
                "component_id": item.component_id or "system",
                "evidence_type": item.evidence_type,
                "cycle_id": item.cycle_id,
                "raw_file_name": item.raw_file_name,
                "raw_storage_path": item.raw_storage_path,
                "raw_file_sha256": item.raw_file_sha256,
                "event_time": item.event_time.isoformat() if item.event_time else None,
                "ingestion_time": item.ingestion_time.isoformat(),
                "available_time": item.available_time.isoformat(),
                "ingestion_latency_ms": None if (item.ingestion_latency_ms is None or item.ingestion_latency_ms >= 86400000.0) else item.ingestion_latency_ms,
                "processing_latency_ms": item.processing_latency_ms,
                "quality_flag": item.quality_flag,
                "extracted_text": item.extracted_text,
                "canonical_data": item.canonical_data,
            }

            # Safe JSON-serializable sanitization for Supabase postgrest
            clean_row_data = json.loads(json.dumps(row_data, default=str))

            persisted = False
            last_err = None
            for tbl in [
                lambda: self._supabase_client.schema("industrial").table("evidence_streams"),
                lambda: self._supabase_client.table("evidence_streams"),
            ]:
                try:
                    # Previous direct upsert:
                    # tbl().upsert(row_data).execute()
                    tbl().upsert(clean_row_data).execute()
                    persisted = True
                    logger.info(f"Persisted evidence {item.id} to Supabase evidence_streams.")
                    break
                except Exception as e:
                    last_err = e

            if not persisted and last_err:
                logger.warning(f"Could not persist to Supabase: {last_err}. Saved in local memory.")

        return item

    def save_evidence_batch(self, items: List[EvidenceItem]) -> List[EvidenceItem]:
        """
        Persists a batch of evidence items to database and local store in chunks.
        """
        for item in items:
            self._memory_store[item.id] = item

        if self._supabase_client and items:
            rows_data = []
            for item in items:
                row = {
                    "id": item.id,
                    "tenant_id": item.tenant_id,
                    "asset_id": item.asset_id,
                    "component_id": item.component_id or "system",
                    "evidence_type": item.evidence_type,
                    "cycle_id": item.cycle_id,
                    "raw_file_name": item.raw_file_name,
                    "raw_storage_path": item.raw_storage_path,
                    "raw_file_sha256": item.raw_file_sha256,
                    "event_time": item.event_time.isoformat() if item.event_time else None,
                    "ingestion_time": item.ingestion_time.isoformat(),
                    "available_time": item.available_time.isoformat(),
                    "ingestion_latency_ms": None if (item.ingestion_latency_ms is None or item.ingestion_latency_ms >= 86400000.0) else item.ingestion_latency_ms,
                    "processing_latency_ms": item.processing_latency_ms,
                    "quality_flag": item.quality_flag,
                    "extracted_text": item.extracted_text,
                    "canonical_data": item.canonical_data,
                }
                rows_data.append(json.loads(json.dumps(row, default=str)))

            chunk_size = 50
            for i in range(0, len(rows_data), chunk_size):
                chunk = rows_data[i : i + chunk_size]
                chunk_persisted = False
                chunk_err = None
                for tbl in [
                    lambda: self._supabase_client.schema("industrial").table("evidence_streams"),
                    lambda: self._supabase_client.table("evidence_streams"),
                ]:
                    try:
                        tbl().upsert(chunk).execute()
                        chunk_persisted = True
                        logger.info(f"Persisted batch of {len(chunk)} evidence rows to Supabase.")
                        break
                    except Exception as e:
                        chunk_err = e

                if not chunk_persisted and chunk_err:
                    logger.warning(f"Could not persist batch to Supabase: {chunk_err}. Saved in local memory.")

        return items

    def get_timeline(self, tenant_id: str, asset_id: str) -> List[EvidenceItem]:
        """
        Retrieves interleaved timeline of all PDF documents and Telemetry cycles,
        sorted chronologically by event_time ASC.
        Fetches directly from Supabase (source of truth) and synchronizes in-memory store.
        """
        items: List[EvidenceItem] = []

        if self._supabase_client:
            for tbl in [
                lambda: self._supabase_client.schema("industrial").table("evidence_streams"),
                lambda: self._supabase_client.table("evidence_streams"),
            ]:
                try:
                    all_rows = []
                    page_size = 1000
                    start = 0
                    while True:
                        query = (
                            tbl()
                            .select("*")
                            .eq("tenant_id", tenant_id)
                            .eq("asset_id", asset_id)
                            .order("event_time", desc=False)
                            .range(start, start + page_size - 1)
                            .execute()
                        )
                        if query.data is not None:
                            all_rows.extend(query.data)
                            if len(query.data) < page_size:
                                break
                            start += page_size
                        else:
                            break

                    items = [self._row_to_item(r) for r in all_rows]

                    # Synchronize memory store for this tenant & asset with Supabase database truth:
                    # If records were deleted or cleared in Supabase, purge them from local memory as well!
                    stale_ids = [
                        k for k, v in self._memory_store.items()
                        if v.tenant_id == tenant_id and v.asset_id == asset_id
                    ]
                    for k in stale_ids:
                        del self._memory_store[k]
                    for item in items:
                        self._memory_store[item.id] = item

                    return items
                except Exception as e:
                    logger.debug(f"Timeline query attempt failed: {e}")

        # PREVIOUS NON-PAGINATED FALLBACK PRESERVED:
        # if self._supabase_client:
        #     query = self._supabase_client.table("evidence_streams").select("*").eq("tenant_id", tenant_id).execute()
        #     if query.data:
        #         return [self._row_to_item(r) for r in query.data]

        # Fallback to in-memory items only if Supabase is completely unreachable
        items = [
            it for it in self._memory_store.values()
            if it.tenant_id == tenant_id and it.asset_id == asset_id
        ]
        # Sort chronologically by event_time (None placed at the beginning or sorted by ingestion_time)
        items.sort(key=lambda x: x.event_time or x.ingestion_time)
        return items

    def get_by_id(self, evidence_id: str) -> Optional[EvidenceItem]:
        """Fetch single evidence item by ID directly from Supabase, syncing memory store."""
        if self._supabase_client:
            for tbl in [
                lambda: self._supabase_client.schema("industrial").table("evidence_streams"),
                lambda: self._supabase_client.table("evidence_streams"),
            ]:
                try:
                    res = (
                        tbl()
                        .select("*")
                        .eq("id", evidence_id)
                        .limit(1)
                        .execute()
                    )
                    if res.data and len(res.data) > 0:
                        item = self._row_to_item(res.data[0])
                        self._memory_store[item.id] = item
                        return item
                    elif res.data is not None:
                        # Record not found in Supabase (e.g. deleted); remove from memory
                        if evidence_id in self._memory_store:
                            del self._memory_store[evidence_id]
                        return None
                except Exception:
                    pass

        if evidence_id in self._memory_store:
            return self._memory_store[evidence_id]

        return None

    def delete_telemetry_records(self, tenant_id: str, asset_id: str) -> int:
        """
        Deletes all telemetry cycle records for the given tenant & asset
        from Supabase database (both public and industrial schemas) and purges local memory store.
        Returns the number of deleted records.
        """
        deleted_count = 0

        # 1. Purge from Supabase database
        if self._supabase_client:
            for tbl in [
                lambda: self._supabase_client.schema("industrial").table("evidence_streams"),
                lambda: self._supabase_client.table("evidence_streams"),
            ]:
                try:
                    res = (
                        tbl()
                        .delete()
                        .eq("tenant_id", tenant_id)
                        .eq("asset_id", asset_id)
                        .eq("evidence_type", "TELEMETRY_CYCLE")
                        .execute()
                    )
                    if res.data:
                        deleted_count += len(res.data)
                        logger.info(f"Deleted {len(res.data)} telemetry records from Supabase.")
                except Exception as e:
                    logger.debug(f"Supabase delete attempt on table failed: {e}")

        # 2. Always purge matching records from local memory store
        stale_keys = [
            k for k, v in self._memory_store.items()
            if v.tenant_id == tenant_id and v.asset_id == asset_id and v.evidence_type == "TELEMETRY_CYCLE"
        ]
        for k in stale_keys:
            del self._memory_store[k]

        logger.info(f"Purged {len(stale_keys)} telemetry records from local memory store.")
        return deleted_count or len(stale_keys)

    def _row_to_item(self, row: dict) -> EvidenceItem:
        """Converts database row to EvidenceItem model."""
        event_time = None
        if row.get("event_time"):
            try:
                event_time = datetime.fromisoformat(row["event_time"].replace("Z", "+00:00"))
            except Exception:
                pass

        ingestion_time = utc_now()
        if row.get("ingestion_time"):
            try:
                ingestion_time = datetime.fromisoformat(row["ingestion_time"].replace("Z", "+00:00"))
            except Exception:
                pass

        available_time = utc_now()
        if row.get("available_time"):
            try:
                available_time = datetime.fromisoformat(row["available_time"].replace("Z", "+00:00"))
            except Exception:
                pass

        canonical_raw = row.get("canonical_data") or {}
        if isinstance(canonical_raw, dict):
            # Enforce standardized canonical key order (reversing PostgreSQL JSONB arbitrary length sorting)
            canonical_ordered = {}
            for k in ["schema", "tenant_id", "source", "asset", "timestamps", "measurements", "metadata"]:
                if k in canonical_raw:
                    canonical_ordered[k] = canonical_raw[k]
            for k, v in canonical_raw.items():
                if k not in canonical_ordered:
                    canonical_ordered[k] = v
            canonical_raw = canonical_ordered

        raw_ingest_lat = row.get("ingestion_latency_ms")
        if raw_ingest_lat is not None and (raw_ingest_lat >= 86400000.0 or raw_ingest_lat == 0.0):
            raw_ingest_lat = None

        return EvidenceItem(
            id=str(row["id"]),
            tenant_id=str(row.get("tenant_id", "hydraulic_lab")),
            asset_id=str(row.get("asset_id", "hydraulic_rig_01")),
            component_id=row.get("component_id"),
            evidence_type=str(row.get("evidence_type", "TELEMETRY_CYCLE")),
            cycle_id=row.get("cycle_id"),
            raw_file_name=str(row.get("raw_file_name", "")),
            raw_storage_path=str(row.get("raw_storage_path", "")),
            raw_file_sha256=str(row.get("raw_file_sha256", "")),
            event_time=event_time,
            ingestion_time=ingestion_time,
            available_time=available_time,
            ingestion_latency_ms=raw_ingest_lat,
            processing_latency_ms=row.get("processing_latency_ms"),
            quality_flag=str(row.get("quality_flag", "NOMINAL")),
            extracted_text=row.get("extracted_text"),
            canonical_data=canonical_raw,
        )

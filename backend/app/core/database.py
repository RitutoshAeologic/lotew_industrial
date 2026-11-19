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
        """
        # Check memory cache first
        for item in self._memory_store.values():
            if (
                item.tenant_id == tenant_id
                and item.asset_id == asset_id
                and item.evidence_type == "TELEMETRY_CYCLE"
                and item.cycle_id == cycle_id
            ):
                return item

        # Check Supabase
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
                    break
                except Exception as e:
                    logger.debug(f"Query check attempt failed: {e}")

        return None

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
                "ingestion_latency_ms": item.ingestion_latency_ms,
                "processing_latency_ms": item.processing_latency_ms,
                "quality_flag": item.quality_flag,
                "extracted_text": item.extracted_text,
                "canonical_data": item.canonical_data,
            }

            for tbl in [
                lambda: self._supabase_client.schema("industrial").table("evidence_streams"),
                lambda: self._supabase_client.table("evidence_streams"),
            ]:
                try:
                    tbl().upsert(row_data).execute()
                    logger.info(f"Persisted evidence {item.id} to Supabase evidence_streams.")
                    break
                except Exception as e:
                    logger.warning(f"Could not persist to Supabase: {e}. Saved in local memory.")

        return item

    def get_timeline(self, tenant_id: str, asset_id: str) -> List[EvidenceItem]:
        """
        Retrieves interleaved timeline of all PDF documents and Telemetry cycles,
        sorted chronologically by event_time ASC.
        """
        items: List[EvidenceItem] = []

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
                        .order("event_time", desc=False)
                        .execute()
                    )
                    if query.data is not None:
                        items = [self._row_to_item(r) for r in query.data]
                        for item in items:
                            self._memory_store[item.id] = item
                        return items
                except Exception as e:
                    logger.debug(f"Timeline query attempt failed: {e}")

        # Fallback to in-memory items
        items = [
            it for it in self._memory_store.values()
            if it.tenant_id == tenant_id and it.asset_id == asset_id
        ]
        # Sort chronologically by event_time (None placed at the beginning or sorted by ingestion_time)
        items.sort(key=lambda x: x.event_time or x.ingestion_time)
        return items

    def get_by_id(self, evidence_id: str) -> Optional[EvidenceItem]:
        """Fetch single evidence item by ID."""
        if evidence_id in self._memory_store:
            return self._memory_store[evidence_id]

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
                except Exception:
                    pass

        return None

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
            ingestion_latency_ms=row.get("ingestion_latency_ms"),
            processing_latency_ms=row.get("processing_latency_ms"),
            quality_flag=str(row.get("quality_flag", "NOMINAL")),
            extracted_text=row.get("extracted_text"),
            canonical_data=row.get("canonical_data") or {},
        )

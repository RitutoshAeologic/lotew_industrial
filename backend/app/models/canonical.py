"""
Canonical Observation v1 and Evidence Item Models.
Enforces the 3-Timestamp Rule and component-grouped telemetry structures.
"""

from datetime import datetime, timezone
from typing import Any, Dict, Optional
from uuid import uuid4

from pydantic import BaseModel, Field


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class TimestampsBlock(BaseModel):
    """
    Forensic 3-Timestamp Architecture.
    - event_time: Physical real-world occurrence (Anchor Epoch + (N-1)*60s or maintenance date)
    - ingestion_time: Moment raw byte payload reached the API gateway
    - available_time: Moment Parquet compression & canonical JSON persisted to memory/DB
    - latencies: Millisecond differentials proving temporal causality
    """
    event_time: Optional[datetime] = None
    ingestion_time: datetime = Field(default_factory=utc_now)
    available_time: datetime = Field(default_factory=utc_now)
    ingestion_latency_ms: Optional[float] = None
    processing_latency_ms: Optional[float] = None


class SensorMeasurementStats(BaseModel):
    """Extracted statistical summary per sensor stream."""
    median: float
    mad: float
    min: float
    max: float
    rate_hz: int
    unit: str
    samples_count: int


class CanonicalObservation(BaseModel):
    """
    Universal CanonicalObservation v1.
    Decoupled representation bridging multi-rate time-series telemetry and documentary logs.
    """
    schema_: Dict[str, str] = Field(
        default_factory=lambda: {"name": "lotew.canonical_observation", "version": "1.0.0"},
        alias="schema"
    )
    tenant_id: str
    source: Dict[str, Any]
    asset: Dict[str, Any]
    timestamps: TimestampsBlock
    measurements: Dict[str, Any]
    metadata: Optional[Dict[str, Any]] = None

    class Config:
        populate_by_name = True


class EvidenceItem(BaseModel):
    """
    Persistent Evidence Stream row representation.
    Mirrors industrial.evidence_streams in Supabase and EvidenceItemModel in Flutter Web.
    """
    id: str = Field(default_factory=lambda: str(uuid4()))
    tenant_id: str
    asset_id: str
    component_id: Optional[str] = "system"
    evidence_type: str  # 'PDF_DOCUMENT' | 'TELEMETRY_CYCLE'
    cycle_id: Optional[int] = None
    raw_file_name: str
    raw_storage_path: str
    raw_file_sha256: str
    event_time: Optional[datetime] = None
    ingestion_time: datetime = Field(default_factory=utc_now)
    available_time: datetime = Field(default_factory=utc_now)
    ingestion_latency_ms: Optional[float] = None
    processing_latency_ms: Optional[float] = None
    quality_flag: str = "NOMINAL"
    extracted_text: Optional[str] = None
    canonical_data: Dict[str, Any] = Field(default_factory=dict)


class IngestCycleRequest(BaseModel):
    cycle_id: int = Field(..., ge=1, le=2205, description="UCI Hydraulic Operational Cycle Number (1 to 2205)")
    tenant_id: str = Field(default="hydraulic_lab", description="Logical multi-tenant identifier")
    asset_id: str = Field(default="hydraulic_rig_01", description="Monitored industrial rig ID")
    simulate_packet_loss_pct: float = Field(default=0.0, ge=0.0, le=100.0, description="Optional packet loss simulation percentage")
    simulate_distortion: Optional[str] = Field(default=None, description="Optional signal distortion simulation ('SPIKE' | 'FLATLINE')")


class IngestRangeRequest(BaseModel):
    start_cycle: int = Field(default=1, ge=1, le=2205, description="Starting cycle number (1 to 2205)")
    end_cycle: int = Field(default=2205, ge=1, le=2205, description="Ending cycle number (1 to 2205)")
    tenant_id: str = Field(default="hydraulic_lab", description="Logical multi-tenant identifier")
    asset_id: str = Field(default="hydraulic_rig_01", description="Monitored industrial rig ID")


class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    dataset_available: bool
    cycles_count: int
    storage_mode: str
    timestamp: datetime

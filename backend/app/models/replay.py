"""
Pydantic models for Forensic Claim Replay, Adjudication, and Demo Fixtures.
Enforces the 8-Field Decision Record specification and RFC 8785 Canonical JSON hashing.
"""

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class TrajectoryEvent(BaseModel):
    timestamp_utc: str
    cycle_id: int
    event_type: str  # 'BASELINE_HANDOVER', 'TELEMETRY_ALERT', 'OPERATOR_ACTION', 'CMMS_QUERY', 'SLA_BREACH', 'FAILURE'
    title: str
    detail: str
    status: str      # 'NOMINAL', 'WARNING', 'DELIVERED', 'DISMISSED', 'MISSING_RECORD', 'BREACH', 'FAILURE'
    evidence_sha256: Optional[str] = None
    hardware_origin_id: Optional[str] = "HW-HYD-RIG-01-PRIMARY-BUS"


class ReplayEvaluationRequest(BaseModel):
    tenant_id: str = "TEN-TITAN-01"
    asset_id: str = "hydraulic_rig_01"
    cutoff_cycle: int = 211
    user_role: str = "INSURER_ADJUSTER"
    insurer_id: Optional[str] = "INS-ALLIANZ-01"


class DecisionRecordResponse(BaseModel):
    decision_id: str
    case_id: str = "CLM-2026-9042"
    asset_id: str = "hydraulic_rig_01"
    tenant_id: str = "TEN-TITAN-01"
    operator_id: str = "OP-ABC-01"
    insurer_id: str = "INS-ALLIANZ-01"
    policy_number: str = "POL-ALLZ-8812"
    cutoff_cycle: int
    cutoff_time_utc: str
    action_requested: str = "INDEMNITY_PAYOUT_ASSESSMENT"
    verdict: str  # 'DENY_INDEMNITY' or 'APPROVE_INDEMNITY'
    authority_score: float
    adherence_followed: bool
    service_missed: bool
    breached_clauses: List[str]
    rationale_summary: str
    reconstructed_trajectory: List[TrajectoryEvent]
    canonical_data_sha256: str
    block_hash: str
    previous_hash: str
    block_index: int = 42
    created_at: datetime = Field(default_factory=utc_now)


class ClaimDeterminationRequest(BaseModel):
    claim_id: str = "CLM-2026-9042"
    decision_id: str
    determination: str  # 'DENIED' or 'APPROVED'
    clause_referenced: Optional[str] = "Clause 3.1 & Clause 4.2"
    adjuster_notes: str
    adjuster_user_id: str = "claims@allianz.com"


class ClaimDeterminationResponse(BaseModel):
    determination_id: str
    claim_id: str
    decision_id: str
    status: str
    determination: str
    clause_referenced: Optional[str]
    adjuster_notes: str
    recorded_at: datetime = Field(default_factory=utc_now)
    dossier_download_url: str


class AlertActionRequest(BaseModel):
    asset_id: str = "hydraulic_rig_01"
    cycle_id: int = 211
    action: str  # 'DISMISS_AND_RUN' or 'DISPATCH_SERVICE'
    operator_notes: Optional[str] = None
    operator_user_id: str = "operator@dealer.com"


class AlertActionResponse(BaseModel):
    status: str
    action: str
    followed: bool
    service_missed: bool
    message: str
    timestamp: datetime = Field(default_factory=utc_now)


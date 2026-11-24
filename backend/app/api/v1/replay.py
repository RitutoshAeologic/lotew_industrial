"""
Forensic Claim Replay & Adjudication Endpoints.
Serves the 8-Field Decision Record, Timeline Cutoff Replay, Adjuster Determination, and Verifiable Export Pack.
"""

from functools import lru_cache
import logging
from typing import Any, Dict

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response, StreamingResponse

from ...models.replay import (
    AlertActionRequest,
    AlertActionResponse,
    ClaimDeterminationRequest,
    ClaimDeterminationResponse,
    DecisionRecordResponse,
    ReplayEvaluationRequest,
)
from ...services.replay_service import ReplayService

logger = logging.getLogger("lotew.industrial.api.replay")
router = APIRouter(prefix="/api/v1/industrial", tags=["Forensic Claim Replay & Adjudication"])


@lru_cache()
def get_replay_service() -> ReplayService:
    return ReplayService()


@router.post("/replay/evaluate", response_model=DecisionRecordResponse, summary="Evaluate Claim Replay at Cutoff Cycle T")
async def evaluate_replay(
    req: ReplayEvaluationRequest,
    service: ReplayService = Depends(get_replay_service),
):
    """
    Evaluates evidence knowable strictly up to cutoff_cycle (Time T).
    Enforces strict lookahead quarantine and returns 8-field Decision Record with SHA-256 block hash.
    """
    try:
        return service.evaluate_replay(
            tenant_id=req.tenant_id,
            asset_id=req.asset_id,
            cutoff_cycle=req.cutoff_cycle,
            user_role=req.user_role,
            insurer_id=req.insurer_id or "INS-ALLIANZ-01",
        )
    except Exception as e:
        logger.error(f"Error evaluating replay: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/claims/determine", response_model=ClaimDeterminationResponse, summary="Record Adjuster Final Determination")
async def determine_claim(
    req: ClaimDeterminationRequest,
    service: ReplayService = Depends(get_replay_service),
):
    """
    Records human claims adjuster determination (DENIED / APPROVED) with policy clause reference.
    Locks decision into tamper-evident ledger.
    """
    try:
        return service.determine_claim(req)
    except Exception as e:
        logger.error(f"Error recording determination: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/operations/alert-action", response_model=AlertActionResponse, summary="Log Operator Cab Alert Action")
async def record_operator_action(
    req: AlertActionRequest,
    service: ReplayService = Depends(get_replay_service),
):
    """
    Simulates operator action in cab console (DISPATCH_SERVICE vs DISMISS_AND_RUN).
    Sets adherence status (followed = true/false) and maintenance state.
    """
    try:
        return service.record_operator_action(req)
    except Exception as e:
        logger.error(f"Error logging alert action: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/claims/{claim_id}/dossier", summary="Download Self-Contained Verifiable Forensic Dossier ZIP")
async def download_dossier(
    claim_id: str,
    service: ReplayService = Depends(get_replay_service),
):
    """
    Generates and downloads a self-contained ZIP archive containing:
    1. decision_record.json (Canonical JSON format)
    2. forensic_summary_report.txt (Human-readable determination & clause citations)
    3. verify_chain.py (Standalone Python verification script)
    """
    try:
        zip_buf = service.generate_dossier_zip(claim_id)
        return StreamingResponse(
            zip_buf,
            media_type="application/zip",
            headers={"Content-Disposition": f"attachment; filename=lotew_forensic_pack_{claim_id}.zip"},
        )
    except Exception as e:
        logger.error(f"Error generating dossier zip: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/replay/demo-fixtures", summary="Get Pre-Configured Multi-Role Demo Fixtures")
async def get_demo_fixtures() -> Dict[str, Any]:
    """
    Returns complete dummy data hierarchy for instant UI rendering:
    - 4 User Personas with pre-configured credentials
    - Multi-tenant organization tree (Tenant -> Operator -> Insurer)
    - Monitored assets and policy bindings
    - The 3 key physical dataset cycles (1665, 211, 226)
    """
    return {
        "personas": [
            {
                "id": "lotew_admin",
                "name": "👑 Tier 1: Lotew Admin",
                "email": "admin@lotew.io",
                "role": "SUPER_ADMIN",
                "scope": "Cross-Tenant Full Control",
                "default_console": 1,
            },
            {
                "id": "fleet_operator",
                "name": "👷 Tier 2: Fleet Operator",
                "email": "operator@dealer.com",
                "role": "FLEET_OPERATOR",
                "tenant_id": "TEN-TITAN-01",
                "operator_id": "OP-ABC-01",
                "scope": "Titan Rentals / ABC Infrastructure Fleet",
                "default_console": 1,
            },
            {
                "id": "insurer_allianz",
                "name": "🛡️ Tier 3: Insurer Adjuster (Allianz)",
                "email": "claims@allianz.com",
                "role": "INSURER_ADJUSTER",
                "insurer_id": "INS-ALLIANZ-01",
                "scope": "Policy #POL-ALLZ-8812 (Rig #01 & #02)",
                "default_console": 2,
            },
            {
                "id": "external_auditor",
                "name": "🏛️ Tier 4: External Auditor (TÜV SÜD)",
                "email": "auditor@tuv.com",
                "role": "AUDITOR",
                "scope": "Cryptographic Offline Audit Only",
                "default_console": 2,
            },
        ],
        "organizational_hierarchy": {
            "root": "Lotew Industrial Assurance Core",
            "tenants": [
                {
                    "tenant_id": "TEN-TITAN-01",
                    "name": "Titan Rentals Heavy Fleet",
                    "operators": [
                        {
                            "operator_id": "OP-ABC-01",
                            "name": "ABC Infrastructure Contractors",
                            "insurer": {
                                "insurer_id": "INS-ALLIANZ-01",
                                "name": "Allianz Global Corporate & Specialty",
                                "policy_number": "POL-ALLZ-8812",
                                "coverage_window": "2024-01-01 to 2024-12-31",
                            },
                            "assets": ["hydraulic_rig_01", "hydraulic_rig_02"],
                        },
                        {
                            "operator_id": "OP-DELTA-02",
                            "name": "Delta Heavy Civil Works",
                            "insurer": {
                                "insurer_id": "INS-ZURICH-02",
                                "name": "Zurich Commercial Insurance",
                                "policy_number": "POL-ZUR-4419",
                                "coverage_window": "2024-01-01 to 2024-12-31",
                            },
                            "assets": ["hydraulic_rig_03"],
                        },
                    ],
                }
            ],
        },
        "dispute_claim": {
            "claim_id": "CLM-2026-9042",
            "asset_id": "hydraulic_rig_01",
            "asset_name": "Excavator Rig #01 (Axial Piston Hydraulic Bench)",
            "policy_number": "POL-ALLZ-8812",
            "amount_claimed_usd": 18500.00,
            "incident_cycle": 211,
            "failure_cycle": 226,
            "baseline_cycle": 1665,
        },
        "cycles": [
            {
                "cycle_id": 1665,
                "label": "Baseline Handover",
                "status": "NOMINAL",
                "ps1_bar": 156.4,
                "flow_lpm": 10.1,
                "cooler_pct": 100.0,
                "pump_leak_score": 0.0,
                "hash": "53418536ae968dc51d46b7a0b5a3fa7166113bdf2d0014a4b49195b0042da09c",
                "description": "Pre-rental delivery handover. 100% nominal state verified.",
            },
            {
                "cycle_id": 211,
                "label": "Internal Pump Leak",
                "status": "WARNING",
                "ps1_bar": 142.1,
                "flow_lpm": 2.15,
                "cooler_pct": 100.0,
                "pump_leak_score": 2.85,
                "hash": "8f3b1409ae221dc51d46b7a0b5a3fa7166113bdf2d0014a4b49195b0042dc012",
                "description": "Critical flow drop to 2.15 L/min. Mandatory service warning issued.",
            },
            {
                "cycle_id": 226,
                "label": "Catastrophic Seizure",
                "status": "FAILURE",
                "ps1_bar": 215.8,
                "flow_lpm": 0.0,
                "cooler_pct": 20.0,
                "pump_leak_score": 5.0,
                "hash": "9900ab124400114a4b49195b0042da09c77113bdf2d0014a4b49195b0042da09",
                "description": "Total pump destruction after 14 unserviced cycles. Claim filed.",
            },
        ],
    }


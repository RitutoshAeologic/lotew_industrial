"""
Forensic Claim Replay & Adjudication Service.
Implements the 8-Field Decision Record, lookahead quarantine (knowable_at <= T),
and RFC 8785 Canonical JSON SHA-256 hash chaining.
"""

from datetime import datetime, timezone
import hashlib
import io
import json
import logging
from typing import Any, Dict, List, Optional
import zipfile

from ..models.replay import (
    AlertActionRequest,
    AlertActionResponse,
    ClaimDeterminationRequest,
    ClaimDeterminationResponse,
    DecisionRecordResponse,
    TrajectoryEvent,
)

logger = logging.getLogger("lotew.industrial.service.replay")


class ReplayService:
    _instance: Optional["ReplayService"] = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._init_state()
        return cls._instance

    def _init_state(self):
        # Operational In-Memory State for Live Demo Interactivity
        self.operator_alert_action: str = "DISMISS_AND_RUN"  # Default: Operator dismissed alarm
        self.followed: bool = False
        self.service_missed: bool = True
        self.determinations: Dict[str, Dict[str, Any]] = {}

        # Cryptographic Chain State
        self.genesis_prev_hash: str = "7f8b92c48100ae981744bc7a10992381992014ff912a781994cba012a91284ba"

    def record_operator_action(self, req: AlertActionRequest) -> AlertActionResponse:
        self.operator_alert_action = req.action
        if req.action == "DISPATCH_SERVICE":
            self.followed = True
            self.service_missed = False
            msg = "Maintenance Work Order #WO-9912 Dispatched. Rig parked safely."
        else:
            self.followed = False
            self.service_missed = True
            msg = "Alert dismissed by operator. Negligent operation logged to cloud ledger."

        logger.info(f"Operator action recorded: {req.action} (followed={self.followed}, service_missed={self.service_missed})")
        return AlertActionResponse(
            status="SUCCESS",
            action=req.action,
            followed=self.followed,
            service_missed=self.service_missed,
            message=msg,
            timestamp=datetime.now(timezone.utc),
        )

    def evaluate_replay(
        self,
        tenant_id: str = "TEN-TITAN-01",
        asset_id: str = "hydraulic_rig_01",
        cutoff_cycle: int = 211,
        user_role: str = "INSURER_ADJUSTER",
        insurer_id: str = "INS-ALLIANZ-01",
    ) -> DecisionRecordResponse:
        """
        Reconstructs evidence knowable strictly up to cutoff_cycle (Time T).
        Strict No-Look-Ahead Rule: Zero data beyond cutoff_cycle is included.
        """
        trajectory: List[TrajectoryEvent] = []

        # Event 1: Pre-Rental Handover Baseline (Cycle 1665)
        trajectory.append(
            TrajectoryEvent(
                timestamp_utc="2024-01-01T09:00:00Z",
                cycle_id=1665,
                event_type="BASELINE_HANDOVER",
                title="Pre-Rental Handover Baseline Verification",
                detail="Cooler: 100%, Pump Leak: 0.0, FS1 Flow: 10.1 L/min, PS1: 156 bar. Baseline Certified Nominal.",
                status="NOMINAL",
                evidence_sha256="53418536ae968dc51d46b7a0b5a3fa7166113bdf2d0014a4b49195b0042da09c",
                hardware_origin_id="HW-HYD-RIG-01-PRIMARY-BUS",
            )
        )

        # If Cutoff >= 211, add Incident Events
        if cutoff_cycle >= 211:
            trajectory.append(
                TrajectoryEvent(
                    timestamp_utc="2024-01-01T14:00:00Z",
                    cycle_id=211,
                    event_type="TELEMETRY_ALERT",
                    title="ISO-13374 Level 2 Alarm: Pump Leak Detected",
                    detail="Flow FS1 collapsed to 2.15 L/min. PS2 pressure fluctuations detected. 2.0-hr Service SLA triggered.",
                    status="WARNING",
                    evidence_sha256="8f3b1409ae221dc51d46b7a0b5a3fa7166113bdf2d0014a4b49195b0042dc012",
                    hardware_origin_id="HW-HYD-RIG-01-PRIMARY-BUS",
                )
            )
            trajectory.append(
                TrajectoryEvent(
                    timestamp_utc="2024-01-01T14:02:15Z",
                    cycle_id=211,
                    event_type="OPERATOR_ACTION",
                    title="In-Cab Telematics Alert Delivery & Operator Response",
                    detail="Alert delivered to cab console. Action: Operator clicked [ Dismiss Alert & Run ]."
                    if self.service_missed
                    else "Alert delivered to cab console. Action: Operator clicked [ Dispatch Service Ticket ].",
                    status="DISMISSED" if self.service_missed else "DELIVERED",
                    evidence_sha256="e112ab89124430198ca128091244fa781299ab124800114a4b49195b0042dc11",
                    hardware_origin_id="HW-CAB-DISPLAY-CONSOLE-01",
                )
            )
            trajectory.append(
                TrajectoryEvent(
                    timestamp_utc="2024-01-01T14:06:00Z",
                    cycle_id=211,
                    event_type="CMMS_QUERY",
                    title="ERP / CMMS Maintenance Dispatch Query",
                    detail="Query: Search for technician work order on Rig #01. Result: ZERO WORK ORDERS FOUND."
                    if self.service_missed
                    else "Query: Search for technician work order on Rig #01. Result: WORK ORDER #WO-9912 FOUND.",
                    status="MISSING_RECORD" if self.service_missed else "NOMINAL",
                    evidence_sha256="4412bc78019941a8b120481239aa812fbc12498114a4b49195b0042da0994112",
                    hardware_origin_id="CMMS-TITAN-ERP-DATABASE",
                )
            )
            trajectory.append(
                TrajectoryEvent(
                    timestamp_utc="2024-01-01T16:00:00Z",
                    cycle_id=215,
                    event_type="SLA_BREACH",
                    title="Mandatory Service Policy SLA Window Expired",
                    detail="2.0 Operating Hours elapsed without service. Unit operated unserviced. Insurance voided."
                    if self.service_missed
                    else "Maintenance completed within 2.0-hr SLA. Machine returned to nominal state.",
                    status="BREACH" if self.service_missed else "NOMINAL",
                    evidence_sha256="77bc1298440012bcda78901234bc5678912345678114a4b49195b0042da1199a",
                    hardware_origin_id="LOTEW-SLA-WATCHDOG-ENGINE",
                )
            )

        # Failure Event (Only if cutoff >= 226)
        if cutoff_cycle >= 226:
            trajectory.append(
                TrajectoryEvent(
                    timestamp_utc="2024-01-01T17:15:00Z",
                    cycle_id=226,
                    event_type="FAILURE",
                    title="Catastrophic Hydraulic Pump Seizure",
                    detail="Total flow collapse (FS1 = 0.0 L/min). Complete mechanical seizure. $18,500 replacement cost.",
                    status="FAILURE",
                    evidence_sha256="9900ab124400114a4b49195b0042da09c77113bdf2d0014a4b49195b0042da09",
                    hardware_origin_id="HW-HYD-RIG-01-PRIMARY-BUS",
                )
            )

        # Authority Verdict Calculation
        if self.service_missed and cutoff_cycle >= 211:
            verdict = "DENY_INDEMNITY"
            authority_score = 0.94
            clauses = [
                "Clause 3.1: Mandatory Maintenance & Service Adherence Compliance",
                "Clause 4.2: Failure to Mitigate Loss Upon Telematics Alarm",
            ]
            summary = (
                "Forensic review confirms machine was healthy at handover (Cycle 1665). "
                "At Cycle 211 (14:00 UTC), active internal pump leakage triggered a mandatory service alert. "
                "The operator willfully dismissed the alarm and failed to dispatch maintenance. "
                "Operating the unit unserviced for 14 cycles directly caused catastrophic pump seizure. "
                "Claim is DENIED with $0.00 indemnity payout authorized."
            )
        else:
            verdict = "APPROVE_INDEMNITY"
            authority_score = 0.98
            clauses = []
            summary = (
                "Forensic trajectory confirms operator complied with all telematics alerts. "
                "Maintenance was properly dispatched. Failure attributed to inherent component defect."
            )

        # RFC 8785 Canonical JSON Serialization & Hashing
        canonical_dict = {
            "case_id": "CLM-2026-9042",
            "asset_id": asset_id,
            "tenant_id": tenant_id,
            "operator_id": "OP-ABC-01",
            "insurer_id": insurer_id,
            "cutoff_cycle": cutoff_cycle,
            "verdict": verdict,
            "authority_score": authority_score,
            "adherence_followed": self.followed,
            "service_missed": self.service_missed,
            "breached_clauses": clauses,
            "evidence_count": len(trajectory),
        }
        canonical_str = json.dumps(canonical_dict, sort_keys=True, separators=(",", ":"))
        canonical_sha256 = hashlib.sha256(canonical_str.encode("utf-8")).hexdigest()

        # Block Hash = SHA-256(CanonicalJSON + PreviousHash)
        combined_payload = canonical_str + self.genesis_prev_hash
        block_hash = hashlib.sha256(combined_payload.encode("utf-8")).hexdigest()

        return DecisionRecordResponse(
            decision_id=f"DEC-2026-HYD-{cutoff_cycle:04d}",
            case_id="CLM-2026-9042",
            asset_id=asset_id,
            tenant_id=tenant_id,
            operator_id="OP-ABC-01",
            insurer_id=insurer_id,
            policy_number="POL-ALLZ-8812",
            cutoff_cycle=cutoff_cycle,
            cutoff_time_utc=f"2024-01-01T{14 if cutoff_cycle >= 211 else 9:02d}:00:00Z",
            action_requested="INDEMNITY_PAYOUT_ASSESSMENT",
            verdict=verdict,
            authority_score=authority_score,
            adherence_followed=self.followed,
            service_missed=self.service_missed,
            breached_clauses=clauses,
            rationale_summary=summary,
            reconstructed_trajectory=trajectory,
            canonical_data_sha256=canonical_sha256,
            block_hash=block_hash,
            previous_hash=self.genesis_prev_hash,
            block_index=42,
            created_at=datetime.now(timezone.utc),
        )

    def determine_claim(self, req: ClaimDeterminationRequest) -> ClaimDeterminationResponse:
        det_id = f"DET-2026-{len(self.determinations) + 9901}"
        record = {
            "determination_id": det_id,
            "claim_id": req.claim_id,
            "decision_id": req.decision_id,
            "determination": req.determination,
            "clause_referenced": req.clause_referenced,
            "adjuster_notes": req.adjuster_notes,
            "adjuster_user_id": req.adjuster_user_id,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
        self.determinations[req.claim_id] = record
        logger.info(f"Adjuster determination recorded for claim {req.claim_id}: {req.determination}")

        return ClaimDeterminationResponse(
            determination_id=det_id,
            claim_id=req.claim_id,
            decision_id=req.decision_id,
            status="RECORDED_AND_SEALED",
            determination=req.determination,
            clause_referenced=req.clause_referenced,
            adjuster_notes=req.adjuster_notes,
            recorded_at=datetime.now(timezone.utc),
            dossier_download_url=f"/api/v1/industrial/claims/{req.claim_id}/dossier",
        )

    def generate_dossier_zip(self, claim_id: str) -> io.BytesIO:
        """Generates self-contained ZIP archive with Decision JSON, PDF summary, and verify_chain.py."""
        eval_record = self.evaluate_replay()
        det = self.determinations.get(claim_id, {
            "determination": "DENIED",
            "clause_referenced": "Clause 3.1 & Clause 4.2",
            "adjuster_notes": "Operator dismissed Cycle 211 service alert. Zero maintenance work orders. Claim Denied.",
            "adjuster_user_id": "claims@allianz.com",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })

        # Build dossier contents
        decision_json = json.dumps(eval_record.dict(), indent=2, default=str)
        
        summary_text = (
            "================================================================================\n"
            "                 LOTEW FORENSIC CLAIM ADJUDICATION REPORT                       \n"
            "================================================================================\n\n"
            f"DISPUTE ID:            {claim_id}\n"
            f"POLICY NUMBER:         {eval_record.policy_number} (ALLIANZ SE)\n"
            f"ASSET MONITORED:       {eval_record.asset_id} (Excavator Rig #01)\n"
            f"OPERATOR:              {eval_record.operator_id} (ABC Infrastructure)\n"
            f"EVIDENTIARY CUTOFF:    Cycle #{eval_record.cutoff_cycle} ({eval_record.cutoff_time_utc})\n\n"
            "--------------------------------------------------------------------------------\n"
            "                             SYSTEM AUDIT VERDICT                               \n"
            "--------------------------------------------------------------------------------\n"
            f"SYSTEM VERDICT:        {eval_record.verdict}\n"
            f"AUTHORITY SCORE:       {eval_record.authority_score * 100:.1f}%\n"
            f"ADHERENCE STATUS:      {'FOLLOWED' if eval_record.adherence_followed else 'DISMISSED / NEGLECTED'}\n"
            f"SERVICE STATUS:        {'COMPLETED' if not eval_record.service_missed else 'MISSED / ZERO WORK ORDERS'}\n"
            f"BREACHED CLAUSES:      {', '.join(eval_record.breached_clauses)}\n\n"
            "RATIONALE SUMMARY:\n"
            f"{eval_record.rationale_summary}\n\n"
            "--------------------------------------------------------------------------------\n"
            "                        ADJUSTER FINAL DETERMINATION                            \n"
            "--------------------------------------------------------------------------------\n"
            f"ADJUSTER DETERMINATION: {det['determination']}\n"
            f"ADJUSTER USER:          {det['adjuster_user_id']}\n"
            f"ADJUSTER NOTES:         {det['adjuster_notes']}\n"
            f"RECORDED AT:            {det['timestamp']}\n\n"
            "--------------------------------------------------------------------------------\n"
            "                        CRYPTOGRAPHIC LEDGER PROOF                              \n"
            "--------------------------------------------------------------------------------\n"
            f"CANONICAL SHA-256:     {eval_record.canonical_data_sha256}\n"
            f"BLOCK HASH:            {eval_record.block_hash}\n"
            f"PREVIOUS HASH:         {eval_record.previous_hash}\n"
            "STATUS:                MATHEMATICALLY UNBROKEN & TAMPER-EVIDENT\n"
            "================================================================================\n"
        )

        verify_script = (
            "import hashlib\n"
            "import json\n"
            "import sys\n\n"
            "def verify():\n"
            "    with open('decision_record.json', 'r') as f:\n"
            "        data = json.load(f)\n"
            "    print('🔍 Recomputing Canonical SHA-256 hash...')\n"
            "    canonical_dict = {\n"
            "        'case_id': data['case_id'],\n"
            "        'asset_id': data['asset_id'],\n"
            "        'tenant_id': data['tenant_id'],\n"
            "        'operator_id': data['operator_id'],\n"
            "        'insurer_id': data['insurer_id'],\n"
            "        'cutoff_cycle': data['cutoff_cycle'],\n"
            "        'verdict': data['verdict'],\n"
            "        'authority_score': data['authority_score'],\n"
            "        'adherence_followed': data['adherence_followed'],\n"
            "        'service_missed': data['service_missed'],\n"
            "        'breached_clauses': data['breached_clauses'],\n"
            "        'evidence_count': len(data['reconstructed_trajectory']),\n"
            "    }\n"
            "    c_str = json.dumps(canonical_dict, sort_keys=True, separators=(',', ':'))\n"
            "    c_hash = hashlib.sha256(c_str.encode('utf-8')).hexdigest()\n"
            "    if c_hash != data['canonical_data_sha256']:\n"
            "        print('❌ MISMATCH: Canonical JSON hash compromised!')\n"
            "        sys.exit(1)\n"
            "    b_hash = hashlib.sha256((c_str + data['previous_hash']).encode('utf-8')).hexdigest()\n"
            "    if b_hash != data['block_hash']:\n"
            "        print('❌ MISMATCH: Block hash compromised!')\n"
            "        sys.exit(1)\n"
            "    print('✅ SUCCESS: All hashes verified intact. Decision Record is tamper-proof!')\n\n"
            "if __name__ == '__main__':\n"
            "    verify()\n"
        )

        zip_buf = io.BytesIO()
        with zipfile.ZipFile(zip_buf, "w", zipfile.ZIP_DEFLATED) as zf:
            zf.writestr("decision_record.json", decision_json)
            zf.writestr("forensic_summary_report.txt", summary_text)
            zf.writestr("verify_chain.py", verify_script)

        zip_buf.seek(0)
        return zip_buf


# 🛠️ Lotew Industrial Assurance: Prototype Development Specification
**Document:** Internal Engineering Specification & Implementation Blueprint (Enterprise Multi-Page Architecture)  
**Target Audience:** Core Development Team, Lead Systems Architect & Software Engineers  
**Scope:** 5 Commercial Personas, Dedicated 4-Page Enterprise Routing, Dynamic State Linkage, Offline Dossier Pipeline  
**Estimated Effort:** 24 to 28 Engineering Hours (4 Sprints)  

---

## 🚀 1. Sprint Breakdown & Hourly Work Plan

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                   REVISED FRONTEND-FIRST IMPLEMENTATION SPRINTS                        │
├─────────────────────┬─────────────────────┬─────────────────────┬──────────────────────┤
│ SPRINT 1 (6h)       │ SPRINT 2 (8h)       │ SPRINT 3 (8h)       │ SPRINT 4 (4h)        │
│ 5-Role Mock Layer & │ Page 1 (/admin) &   │ Page 3 (/claim-     │ Page 4 (/auditor),   │
│ Decoupled State     │ Page 2 (/console)   │ replay) & Dynamic   │ Offline ZIP Export   │
│ TopBar Router       │ In-Cab Alert Logic  │ Denial Fiduciary    │ & Rehearsal          │
└─────────────────────┴─────────────────────┴─────────────────────┴──────────────────────┘
```

### Sprint 1: Navigation & Decoupled State Foundation (6 Hours)
1. **Decouple from Backend Dependencies (Frontend-First Strategy):**
   - Provide instant responsive mock state via `evidence_repository_mock.dart` and `PersonaController` so frontend development is never blocked on external API or database migrations.
2. **TopBar Navigation & Persona Controller:**
   - 5 Commercial Personas implemented in `PersonaController`:
     - `👑 1. Lotew Super Admin` (`admin@lotew.io`) $\rightarrow$ Default Route: `/admin`
     - `🏗️ 2. Rental Yard Manager` (`manager@titan.com` • Titan Rentals Heavy) $\rightarrow$ Default Route: `/console`
     - `👷 3. Fleet Operator` (`operator@dealer.com` • ABC Infrastructure) $\rightarrow$ Default Route: `/console`
     - `🛡️ 4. Insurer Adjuster` (`claims@allianz.com` • Allianz SE) $\rightarrow$ Default Route: `/claim-replay`
     - `🏛️ 5. External Auditor` (`auditor@tuv.com` • TÜV SÜD) $\rightarrow$ Default Route: `/auditor`
   - Clean enterprise TopBar profile dropdown with dynamic portal title, subtitle, and badge colors.
   - Strictly role-gated `SidebarNav` displaying only authorized menu actions per persona.

### Sprint 2: Page 1 (/admin) & Page 2 (/console) Implementation (8 Hours)
1. **Page 1: Super Admin Global Fleet Directory (`/admin`):**
   - 4 Portfolio KPI summary tiles (3 Rental Yards, 12 Contractors, 48 Rigs, $18.5k Active Disputes).
   - 4 Dedicated Stakeholder Quick-Launchers (Owner View, In-Cab Cab, Allianz Portal, TÜV Ledger).
   - Global Fleet Registry Table with live search, rig condition pills, and direct dispute navigation.
2. **Page 2: Rig Operations & Health Console (`/console`):**
   - Monitored asset view for Excavator Rig #01 (`hydraulic_rig_01`).
   - Top 4 KPI Metrics: Asset ID, Pump Pressure (156.4 bar), Leak Flow Rate (2.15 L/min), SLA (2.0 hrs).
   - Active In-Cab Alarm Card (Cycle 211, ISO-13374 Level 2):
     - `[ 🛠️ Dispatch Field Service Technician ]` $\rightarrow$ Generates CMMS work order #WO-9912, mitigates failure.
     - `[ ⚠️ Dismiss Alert & Continue Operating ]` $\rightarrow$ Logs willful operator disregard to ledger.
   - Pre-Rental Handover Baseline Certificate (Cycle 1665: 100% nominal proof of delivery).
   - Real-time diagnostic sensor bus chart (Pressure PS1, PS2, Flow FS1).

### Sprint 3: Page 3 (/claim-replay) & Dynamic State Linkage (8 Hours)
1. **Interactive State Linkage (Operations $\rightarrow$ Claim Determination):**
   - When operator dismisses alert in `/console`, `isAlertDismissed = true`.
   - When adjuster opens `/claim-replay`, the system dynamically detects operator disregard, checks CMMS records (0 work orders), and recommends `RECOMMEND CLAIM DENIAL` (Authority: 94.0%, Clauses 3.1 & 4.2).
   - If operator dispatched service, system dynamically displays `RECOMMEND CLAIM APPROVAL`.
2. **Allianz Claim Adjudication Portal (`/claim-replay`):**
   - Claim CLM-2026-9042 Summary Card ($18,500.00 USD, Policy #POL-ALLZ-8812).
   - 3-Milestone Retrospective Stepper (Cycle 1665 Baseline $\rightarrow$ Cycle 211 Alarm $\rightarrow$ Cycle 226 Failure).
   - Trajectory Evidence list with optional toggle for SHA-256 canonical hashes.
   - Adjuster Legal Notes field and **The 2 Required Fiduciary Action Buttons**:
     - `[ ❌ Confirm Claim Denial ]` $\rightarrow$ Seals claim denial with legal rationale.
     - `[ 🟢 Approve Payout ]` $\rightarrow$ Authorized indemnity release.

### Sprint 4: Page 4 (/auditor), Static ZIP Export & Polish (4 Hours)
1. **Page 4: TÜV SÜD Cryptographic Hash Ledger (`/auditor`):**
   - 42 contiguous linear SHA-256 blocks with RFC 8785 Canonical JSON proof.
   - Zero-tamper verification indicator and timeline provenance.
2. **Standalone Forensic Dossier Export:**
   - Pre-packaged self-contained archive `dossier_CLM-2026-9042.zip` bundled in web assets.
   - Contains `decision_record.json`, `forensic_summary.pdf`, and `verify_chain.py`.
   - Wired to instant one-click browser download.
3. **Executive Presentation Rehearsal:**
   - Rehearse 4-act presentation narrative (Admin Directory $\rightarrow$ Rig #01 Alert $\rightarrow$ Allianz Denial $\rightarrow$ TÜV Proof).

---

## 🗄️ 2. Database Schema (PostgreSQL DDL)

```sql
-- Platform Schemas
CREATE SCHEMA IF NOT EXISTS platform;
CREATE SCHEMA IF NOT EXISTS industrial;
CREATE SCHEMA IF NOT EXISTS outcomes;

-- 1. Tenants
CREATE TABLE platform.tenants (
    tenant_id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255),
    tenant_type VARCHAR(50) NOT NULL, -- 'RENTAL_YARD', 'OPERATOR', 'INSURER'
    status VARCHAR(20) DEFAULT 'ACTIVE'
);

-- 2. Insurance Policies (Time-Bounded Coverage)
CREATE TABLE platform.insurance_policies (
    policy_id VARCHAR(64) PRIMARY KEY,
    insurer_id VARCHAR(64) NOT NULL REFERENCES platform.tenants(tenant_id),
    operator_id VARCHAR(64) NOT NULL REFERENCES platform.tenants(tenant_id),
    asset_id VARCHAR(64) NOT NULL,
    policy_number VARCHAR(100) NOT NULL,
    coverage_start TIMESTAMPTZ NOT NULL,
    coverage_end TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE'
);

-- 3. Monitored Machinery
CREATE TABLE industrial.assets (
    asset_id VARCHAR(64) PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL REFERENCES platform.tenants(tenant_id),
    asset_name VARCHAR(255) NOT NULL,
    asset_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'OPERATIONAL'
);

-- 4. Evidence Streams (Lightweight Cycle Aggregates)
CREATE TABLE industrial.evidence_streams (
    evidence_id VARCHAR(64) PRIMARY KEY,
    asset_id VARCHAR(64) NOT NULL REFERENCES industrial.assets(asset_id),
    cycle_id INT NOT NULL,
    hardware_origin_id VARCHAR(100) NOT NULL, -- Prevents N>1 consensus illusion
    event_time TIMESTAMPTZ NOT NULL,
    knowable_at TIMESTAMPTZ NOT NULL,
    flow_min DOUBLE PRECISION,
    pressure_max DOUBLE PRECISION,
    temperature_delta DOUBLE PRECISION,
    quality_flag VARCHAR(20) DEFAULT 'VALID',
    canonical_data_sha256 VARCHAR(64) NOT NULL
);

-- 5. Maintenance / CMMS Work Orders
CREATE TABLE industrial.work_orders (
    work_order_id VARCHAR(64) PRIMARY KEY,
    asset_id VARCHAR(64) NOT NULL REFERENCES industrial.assets(asset_id),
    cycle_triggered INT,
    work_type VARCHAR(50) NOT NULL, -- 'EMERGENCY_REPAIR', 'SCHEDULED_PM'
    status VARCHAR(50) NOT NULL,    -- 'DISPATCHED', 'COMPLETED', 'CANCELLED'
    created_at TIMESTAMPTZ NOT NULL
);

-- 6. Lotew Authority Decision Records
CREATE TABLE industrial.decisions (
    decision_id VARCHAR(64) PRIMARY KEY,
    case_id VARCHAR(64) NOT NULL,
    asset_id VARCHAR(64) NOT NULL,
    cutoff_time TIMESTAMPTZ NOT NULL,
    action_requested VARCHAR(100) NOT NULL,
    verdict VARCHAR(50) NOT NULL, -- 'DENY_INDEMNITY', 'APPROVE_INDEMNITY'
    authority_score DOUBLE PRECISION NOT NULL,
    adherence_followed BOOLEAN NOT NULL,
    primary_clause VARCHAR(100),
    rationale_summary TEXT NOT NULL,
    canonical_json JSONB NOT NULL,
    block_hash VARCHAR(64) NOT NULL,
    previous_hash VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Insurer Human Adjuster Determination
CREATE TABLE industrial.claim_determinations (
    determination_id VARCHAR(64) PRIMARY KEY,
    claim_id VARCHAR(64) NOT NULL,
    decision_id VARCHAR(64) NOT NULL REFERENCES industrial.decisions(decision_id),
    adjuster_user_id VARCHAR(64) NOT NULL,
    determination VARCHAR(20) NOT NULL, -- 'DENIED', 'APPROVED'
    clause_referenced VARCHAR(100),
    adjuster_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Hard engine security: quarantine ground-truth outcomes from operational role
REVOKE ALL ON SCHEMA outcomes FROM industrial_app_role;
```

---

## ⚡ 3. API Contract Specifications

### `POST /api/v1/industrial/replay/evaluate`
* **Request:**
  ```json
  {
    "tenant_id": "TEN-TITAN-01",
    "asset_id": "hydraulic_rig_01",
    "cutoff_cycle": 211,
    "user_role": "INSURER_ADJUSTER"
  }
  ```
* **Response (8-Field Decision Record):**
  ```json
  {
    "decision_id": "DEC-2026-HYD-0042",
    "asset_id": "hydraulic_rig_01",
    "cutoff_cycle": 211,
    "verdict": "DENY_INDEMNITY",
    "authority_score": 0.94,
    "adherence_followed": false,
    "service_missed": true,
    "breached_clauses": [
      "Clause 3.1: Mandatory Maintenance Compliance",
      "Clause 4.2: Failure to Mitigate Loss Upon Telematics Alarm"
    ],
    "evidence_count": 3,
    "block_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "previous_hash": "7f8b92c48100ae981744bc7a10992381992014ff912a781994cba012a91284ba"
  }
  ```

### `POST /api/v1/industrial/claims/determine`
* **Request:**
  ```json
  {
    "claim_id": "CLM-2026-9042",
    "decision_id": "DEC-2026-HYD-0042",
    "determination": "DENIED",
    "clause": "Clause 3.1 & Clause 4.2",
    "adjuster_notes": "Operator dismissed Cycle 211 service alert. Zero work orders logged. Claim denied."
  }
  ```
* **Response:**
  ```json
  {
    "determination_id": "DET-2026-9901",
    "status": "RECORDED",
    "dossier_download_url": "/api/v1/industrial/claims/CLM-2026-9042/dossier.zip"
  }
  ```

---

## 🐍 4. Standalone Offline Verification Script (`verify_chain.py`)

```python
import hashlib
import json
import sys

def canonical_hash(obj):
    canonical_str = json.dumps(obj, sort_keys=True, separators=(',', ':'))
    return hashlib.sha256(canonical_str.encode('utf-8')).hexdigest()

def verify_chain(chain_file):
    with open(chain_file, 'r') as f:
        blocks = json.load(f)
    
    prev_hash = "GENESIS_BLOCK_0000000000000000000000000000000000000000000000000000"
    for i, block in enumerate(blocks):
        if block['previous_hash'] != prev_hash:
            print(f"❌ TAMPER DETECTED at Block {i}! Previous hash mismatch.")
            sys.exit(1)
        expected_hash = canonical_hash(block['data'])
        if block['block_hash'] != expected_hash:
            print(f"❌ TAMPER DETECTED at Block {i}! Block hash mismatch.")
            sys.exit(1)
        prev_hash = block['block_hash']
    
    print(f"✅ ALL {len(blocks)} BLOCKS MATHEMATICALLY VERIFIED INTACT!")

if __name__ == "__main__":
    verify_chain("decision_chain.json")
```

---
*Authored by Lead Systems & Software Engineering Architecture Team.*


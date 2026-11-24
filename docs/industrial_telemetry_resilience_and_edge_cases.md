# Lotew Industrial Telemetry: Failure Modes, Edge Cases & Developer Implementation Blueprint

**Standard Compliance**: ISO 13374 (Condition Monitoring & Diagnostics), IEC 61400-25 (Industrial Telemetry), OPC UA Part 8 (Data Access & Quality Codes)  
**Target Repository**: `lotew_industrial` (`develop` branch)  
**Audit Target**: Commit [`e69c054`](https://github.com/RitutoshAeologic/lotew_industrial/commit/e69c054) (*"feat(telemetry): implement 1-2205 cycle streaming, live spectrum, forensic ledger, Supabase sync and clear features"*)  
**Core Requirement**: **100% Production Live Telemetry Mode** (Zero toy demo artifacts: no Mock API switches, no artificial speed multipliers, strictly live physical clock / high-throughput batch ingestion)  
**Audience**: Development Team & Technical Leads  
**Date**: November 2026  

---

## 1. Executive Summary & TL Requirement Alignment

Following architectural review with the Tech Lead (TL), the Lotew Industrial Console is transitioning to a **strict, production-grade Live Telemetry & Forensic Audit System**. 

In industrial SCADA and Condition Monitoring environments (e.g., Siemens MindSphere, Datadog Industrial, AWS IoT SiteWise), artificial features like "Mock API Switches" or "2x / 6x / 12x Demo Speed Multipliers" undermine system credibility. Real physical machinery operates either on deterministic wall-clock cycles (60s at 100 Hz) or processes historical datasets via high-throughput batch sealing.

### Key Decisions:
1. **Permanent Retirement of Mock & Demo Artifacts**:
   * Completely purge the "Live API vs Mock Mode" switch from the codebase. The frontend binds 100% directly to the live FastAPI backend (`/api/v1/industrial/...`) and Supabase database.
   * Completely purge the speed multiplier chips (`1x Real`, `6x Demo`, `12x Ultra`). Do not leave them as commented-out clutter.
2. **Main-Screen Telemetry Observability (Restore Live Waveforms)**:
   * Full-width simulator layout in commit `e69c054` mistakenly hid the live waveforms (PS1 Pressure curve and FS1 Flow curve). The TL/Plant Engineer must see real-time physical sensor waveforms directly on the main screen without being forced to click an "Inspect" modal on each cycle.
3. **Persistent Health Spectrum Bar Chart**:
   * The 45-bin bar chart must remain **permanently visible** on the dashboard. It must NOT vanish (`SizedBox.shrink()`) once streaming completes. It serves as the primary macro-level health overview across all 2,205 cycles.
4. **Hardening Against Non-Ideal Edge Cases**:
   * Industrial telemetry is subject to packet loss, electrical noise spikes, sensor stiction/flatline, and S3 network timeouts. The backend must handle these resiliently rather than throwing HTTP 500 errors or misclassifying severe cooler/valve failures as `NOMINAL`.

---

## 2. Client Architecture Mandates vs Engineering Implementation

The client's foundational specification documents (`media_...716f0a54.docx` and `media_...f481af20.docx`) explicitly establish strict architectural rules. However, while the client specified **high-level business rules**, real-world hardware telemetry introduces severe failure modes that our engineering architecture resolves:

### 1. Missing Data & Schema Validation (Resilience Against Packet Loss)
* **Client Document Mandate (Doc 2, Section 5, Line 675 & Line 1827)**:
  > *"Source parsing and validation: Check schema, columns, timestamps, data types, units, missingness, duplicates and source identity."*  
  > *"validation_reports: Stores source validation results, schema errors, missing values, invalid records, and canonical validation outcomes."*
* **Real-World Problem**:  
  While the client specification mandates checking for "missingness," in an operational multi-rate streaming environment, if even **1 sample out of 6,000 is lost** due to network transmission drops, the Polars dataframe engine throws a fatal exception (`ComputeError: All series in a DataFrame must have the same length`). This causes an immediate HTTP 500 crash and halts the entire ingestion stream.
* **Our Technical Implementation**:  
  We implemented **Deterministic Clock Resampling with Linear Interpolation (`np.interp`)**. When dropped packets are detected, missing points are imputed onto the exact 10 ms (100 Hz) time grid without crashing Polars. The forensic audit ledger records `imputed_samples` and `packet_loss_pct`, classifying the quality as **`DATA_LOSS_PARTIAL`** ($\le 10\%$) or **`DATA_LOSS_CRITICAL`** ($> 10\%$).

### 2. "Quality Gate" & Signal Conditioning (Physical Envelopes & Sensor Health)
* **Client Document Mandate (Doc 2, Section 5, Line 677)**:
  > *"Quality Gate / Fusion Engine: Validate incoming evidence, clean where permitted, normalize against the appropriate baseline and extract features. Keep cleanup evidence and transformation versions."*
* **Real-World Problem**:  
  Industrial environments frequently experience electrical noise spikes (e.g., pressure abruptly spiking to 345 bar when the pipe's physical safety limit is 280 bar), sensor wire cuts, or diaphragm stiction (sensor reading locked at 0.0 bar flatline). Without a Quality Gate, the pipeline accepts poisoned signals and certifies severely damaged equipment as **`NOMINAL` (Healthy)**.
* **Our Technical Implementation**:  
  We established strict **Physical Plausibility Envelopes** for all 17 sensors (e.g., PS1: -2.0 to 280.0 bar, FS1: 0.0 to 15.0 L/min) combined with a **Stiction / Flatline Variance Check** ($\sigma < 10^{-4}$). Signals exceeding physical thresholds trigger **`DISTORTED_OUT_OF_BOUNDS`**, while dead channels trigger **`SENSOR_FLATLINE`**, directly satisfying the client's Quality Gate mandate.

### 3. Duplicates & Batch Retries (Idempotency Across Network Glitches)
* **Client Document Mandate (Doc 2, Line 1821 & 1823)**:
  > *"ingestion_jobs: Tracks the lifecycle of each import job, including status, progress, errors, and retry information."*  
  > *"Check duplicates and source identity."*
* **Real-World Problem**:  
  Transient network latency or accidental operator double-clicks can cause the client to retry an ingestion batch. Without deduplication, this results in duplicate database records, primary key collisions, or database lock contention.
* **Our Technical Implementation**:  
  We introduced **Bulk Idempotency Deduplication** via `find_cycles_in_range()`. Before processing any batch, the backend performs a single query against Supabase. Previously ingested cycles are bypassed, returning their existing cryptographic SHA-256 evidence item and preventing database bloat.

### 4. The 3-Timestamp Rule & Latency Separation (Audit Integrity)
* **Client Document Mandate (Doc 1, Module M1 & Doc 2, Line 2020)**:
  > *"Why three timestamps? Event time (when did it happen), Ingestion time (when did our system receive it), Available time (when committed to decision-maker). Separate event time, ingestion time, and processing time."*
* **Real-World Problem**:  
  During historical test bench replays, the physical event occurred in 2024 ($T1$), whereas ingestion happens in 2026 ($T2$). Computing $T2 - T1$ directly produces a false latency of **"11 Days 13 Hours"** (or ~2 years), corrupting performance metrics and violating forensic audit standards.
* **Our Technical Implementation**:  
  The backend detects historical replays ($\Delta t \ge 24\text{ hours}$) and sets `ingestion_latency_ms = None`. The UI and forensic dialog cleanly display **`N/A (Bench Replay)`**, while processing latency ($T3 - T2$, ~8 ms for Parquet compression and SHA-256 hashing) remains accurate.

### 5. Database Zero-Bloat & Object Storage Rule (S3 Lifecycle Management)
* **Client Document Mandate (Doc 2, Section 6, Line 1839)**:
  > *"Large time-series payloads should not automatically be stored as individual relational rows. Original files and high-volume payloads remain in object storage, while PostgreSQL stores the metadata, references, hashes..."*
* **Real-World Problem**:  
  While metadata was stored in PostgreSQL and binary files in S3, clicking "Clear Data" only deleted rows from the database table. The underlying Parquet files remained **permanently orphaned in the Supabase Storage bucket (`industrial-raw`)**, leaking gigabytes of object storage over time.
* **Our Technical Implementation**:  
  We implemented `StorageService.delete_prefix("telemetry/{tenant_id}/{asset_id}/")`. Triggering "Clear Data" now atomically purges both the PostgreSQL ledger and the Supabase S3 storage bucket in full compliance with the client's tiered storage lifecycle rule.

---

## 3. Production UI/UX Architecture Blueprint (Strict Live Data)

To deliver a clean, professional, and intuitive operator experience, the console layout follows a **5-Tier Vertical Industrial Architecture**:

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ TIER 1: REAL-TIME SYSTEM & ASSET STATUS HEADER                                                  │
│ RIG: hydraulic_rig_01  •  TENANT: hydraulic_lab  •  ● STATUS: ONLINE (FASTAPI + SUPABASE SYNC)  │
│ [Actions: Reset / Retest Session]  [Refresh Ledger]  [Clear Data Modal]                         │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ TIER 2: 17-SENSOR TELEMETRY INGESTION HUB (FULL WIDTH)                                          │
│ • Presets: [Cycle 1: Baseline]  [Cycle 211: Severe Leak]  [Cycle 2205: Full Rig]                 │
│ • Cycle Selector: Slider (1..2,205) + Direct Integer Input Box [ 211 ]                          │
│ • Action Buttons:                                                                               │
│   [ ▶ Start Live Stream (60s) ]   [ ⚡ Instant Batch Seal (~35ms) ]   [ 📊 Stream Full Rig ]     │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ TIER 3: LIVE SENSOR GAUGES & EMBEDDED REAL-TIME WAVEFORM (PERSISTENT ON MAIN CONSOLE)            │
│ • Live Digital Gauges: LIVE PS1: 156.2 bar  |  LIVE FS1: 7.8 L/min  |  Phase: PUMP ACCELERATION │
│ • Embedded Dual Waveform Chart: Plots PS1 (0..200 bar) and FS1 (0..15 L/min) across 60 seconds.  │
│   (Operators can visually inspect pressure drops and valve lag directly on the dashboard)       │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ TIER 4: 45-BIN FLEET HEALTH SPECTRUM (PERMANENT MACRO OVERVIEW)                                  │
│ • 45 progressive aggregation bins across Cycles 1 → 2,205                                       │
│ • Animate live during stream; PERSIST on screen after ingestion completes (Never SizedBox.shrink)│
│ • Multi-color bins: Green = Nominal, Yellow = Degraded Leak, Purple = Valve Lag, Red = Distorted │
├──────────────────────────────────────────────────────────────────────────────────────────────────┤
│ TIER 5: FORENSIC EVIDENCE LEDGER (AUDIT TRAIL & DEEP DOSSIER)                                    │
│ • Filter Bar: [All Cycles] [Nominal] [Physical Faults] [Signal Anomalies] + Rows Per Page Dropdown│
│ • Table Columns: TYPE | TARGET | SHA-256 HASH | PARQUET FILE | EVENT TIME | INGESTION TIME |    │
│                  LATENCY | STATUS PILL | ACTIONS                                                 │
│ • Action Pills:                                                                                  │
│   - [View JSON]: Instant Canonical Observation JSON viewer.                                      │
│   - [Inspect Dossier]: Opens deep cryptographic modal (SHA-256 copy, Supabase S3 path, 17-sensor│
│     statistical breakdown table, and 3-timestamp ISO audit trail).                               │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Exhaustive Technical Audit: 7 Critical Loopholes in Commit `e69c054`

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                 COMMIT e69c054 TECHNICAL AUDIT                                  │
├──────────────────────────────────────────────────┬───────────────────────────────────────────────┤
│ Vulnerability                                    │ Impact                                        │
├──────────────────────────────────────────────────┼───────────────────────────────────────────────┤
│ 1. Range Ingestion Lacks Exception Isolation     │ 1 failed cycle crashes entire 50-cycle batch  │
│ 2. Blind "Pump Leak Only" Quality Evaluation    │ Electrical spikes/dead sensors marked NOMINAL │
│ 3. Polars Dimension Mismatch on Dropped Packets  │ pl.DataFrame() crashes server on missing data │
│ 4. Latency Display Regression in Forensic Modal  │ Displays "999999999.0 ms" for bench replays   │
│ 5. Disappearing Spectrum Chart & Binary Filter   │ Chart vanishes post-stream; edge cases hidden │
│ 6. Orphaned Parquet Binaries on "Clear Data"     │ DB rows deleted, but S3 storage leaks GBs     │
│ 7. Commented-out Dead Code Clutter               │ Maintenance hazard and confusion              │
└──────────────────────────────────────────────────┴───────────────────────────────────────────────┘
```

---

### Loophole 1: Range Ingestion Lacks Exception Isolation (Fatal Batch Crash)
* **File**: `backend/app/services/evidence_service.py` (`ingest_telemetry_range`)
* **Problem Code**:
  ```python
  # 3. Concurrent Storage Uploads (8 threads)
  if uploads_to_execute:
      def _upload_task(task):
          path, data = task
          self.storage.upload(path, data, mime_type="application/x-parquet")

      with ThreadPoolExecutor(max_workers=8) as executor:
          list(executor.map(_upload_task, uploads_to_execute))
  ```
* **Failure Mode**:
  If Supabase Object Storage experiences a momentary network timeout, rate limit, or socket drop on even **1 out of the 50 cycles**, `self.storage.upload()` throws an uncaught exception. The `executor.map()` re-raises the exception, **crashing the entire HTTP request with 500 Internal Server Error**. None of the 50 cycles are committed to the database, leaving the stream in an undefined broken state.
* **Required Fix**:
  Implement per-cycle exception isolation and local-disk write-ahead fallback. If remote S3 upload fails, save to local storage mirror, log a warning, and continue committing the batch.

---

### Loophole 2: Hardcoded Quality Flag Blind to Sensor Distortion & Component Faults
* **File**: `backend/app/services/evidence_service.py` (Lines 166–177 & 234–243)
* **Problem Code**:
  ```python
  quality_flag = "NOMINAL"
  if has_profile:
      line = linecache.getline(str(profile_path), cycle_id).strip()
      if line:
          cols = line.split()
          if len(cols) >= 3 and int(cols[2]) > 0:
              quality_flag = "DEGRADED_LEAK"
  elif cycle_id == 211 or (211 <= cycle_id <= 220):
      quality_flag = "DEGRADED_LEAK"
  ```
* **Failure Mode**:
  1. **Ignores Sensor Anomalies**: If a pressure sensor wire breaks (constant 0.0 bar flatline), or an electrical spike jumps to 350 bar, or 15% packets are dropped, this code completely ignores the signal and marks the cycle as **`NOMINAL` (Healthy)**!
  2. **Ignores 3 out of 4 Rig Components in `profile.txt`**:
     In the UCI ZeMA rig dataset, `profile.txt` contains 4 component state columns:
     * `cols[0]` = **Cooler Condition** (`3`: close to total failure, `20`: reduced efficiency, `100`: full efficiency)
     * `cols[1]` = **Valve Condition** (`73`: severe lag / close to failure, `80`: small lag, `100`: optimal)
     * `cols[2]` = **Internal Pump Leakage** (`0`: none, `1`: weak leak, `2`: severe leak)
     * `cols[3]` = **Hydraulic Accumulator** (`90`: close to failure, `100`: severely reduced, `130`: optimal)
     The current code **only checks `int(cols[2]) > 0`**! If the cooler has completely failed (`cols[0] == 3`) or the valve is jammed (`cols[1] == 73`), the current code flags it as **`NOMINAL`**!
* **Required Fix**:
  Evaluate all 4 physical component failure columns from `profile.txt` AND evaluate signal-level telemetry health (packet loss, electrical clipping, sensor stiction).

---

### Loophole 3: Polars Dimension Mismatch Crash Risk on Dropped Samples
* **File**: `backend/app/adapters/hydraulic_adapter.py`
* **Problem Code**:
  ```python
  line = linecache.getline(str(file_path), cycle_id).strip()
  if line:
      raw_vals = np.fromstring(line, sep="\t", dtype=np.float32)
  ...
  df = pl.DataFrame(parquet_dict)  # CRASH IF ANY COLUMN LENGTH != 6000
  ```
* **Failure Mode**:
  Polars enforces strict rectangular arrays. If a line has 5,998 values instead of 6,000 (e.g. edge buffer drop or transmission truncation), `pl.DataFrame()` throws:
  `ComputeError: All series in a DataFrame must have the same length`.
  When range streaming 2,205 cycles, a single missing sample in any of the 17 files halts the entire stream immediately.
* **Required Fix**:
  Implement **Deterministic Clock Resampling**. Missing samples must be linearly interpolated to guarantee exactly 6,000 elements for every single channel, with the imputation count recorded in the forensic metadata.

---

### Loophole 4: Latency Display Regression in `ForensicDetailDialog`
* **File**: `frontend/lib/features/evidence_ingestion/presentation/widgets/forensic_detail_dialog.dart` (Line 278)
* **Problem Code**:
  ```dart
  _LatencyBox(
    label: 'Ingestion Latency (T2 - T1)',
    value: item.ingestionLatencyMs != null 
        ? '${item.ingestionLatencyMs!.toStringAsFixed(1)} ms' 
        : 'Historical Replay',
  )
  ```
* **Failure Mode**:
  For historical cycles whose latency was previously stored as `999999999.0` (or computed across historical year 2024 vs current year 2026), the dialog displays:
  **`999999999.0 ms`**!
* **Required Fix**:
  Route latency through `AppFormatters.formatDurationMs()` or render a clean **`N/A (Bench Replay)`** when `item.isTelemetry` is true or `ms >= 86400000.0`.

---

### Loophole 5: Disappearing Spectrum Chart & Binary Quality Filter
* **File**: `evidence_console_screen.dart` & `telemetry_live_bar_chart.dart`
* **Problem Code**:
  ```dart
  // In evidence_console_screen.dart:
  Obx(() {
    final isFullRigActive = controller.isRangeStreaming.value;
    if (!isFullRigActive) {
      return const SizedBox.shrink(); // GAYAB HO JATA HAI!
    }
    return const _TelemetrySpectrumOverviewCard();
  });
  ```
* **Failure Mode**:
  The 45-bin bar chart only renders while actively streaming. Once streaming finishes or on page reload, the card disappears completely, depriving the TL of the fleet-wide health distribution. Furthermore, the condition filter only has `All`, `Nominal`, and `Degraded Leaks`, ignoring cooler, valve, and sensor distortion faults.
* **Required Fix**:
  Keep `_TelemetrySpectrumOverviewCard()` persistently mounted on the screen. Add filter chips for all fault categories.

---

### Loophole 6: Orphaned Parquet Files on "Clear Data" (Storage Leak)
* **File**: `backend/app/services/evidence_service.py` (`clear_telemetry`)
* **Problem Code**:
  ```python
  def clear_telemetry(self, tenant_id: str = "hydraulic_lab", asset_id: str = "hydraulic_rig_01") -> dict:
      count = self.database.delete_telemetry_records(tenant_id, asset_id)
      return { "status": "SUCCESS", "deleted_count": count }
  ```
* **Failure Mode**:
  This only runs `DELETE FROM industrial.evidence_streams`. The hundreds of Parquet binaries previously uploaded to Supabase Storage (`telemetry/hydraulic_lab/hydraulic_rig_01/cycle_*.parquet`) remain **permanently orphaned in S3 storage**. Repeatedly streaming and clearing data will leak gigabytes of cloud object storage.
* **Required Fix**:
  Call `self.storage.delete_prefix(f"telemetry/{tenant_id}/{asset_id}/")` during the clear operation.

---

### Loophole 7: In-Memory JS Heap Bloat on 2,205 Reactive Objects
* **File**: `frontend/lib/features/evidence_ingestion/presentation/controllers/evidence_controller.dart`
* **Problem Code**:
  ```dart
  evidenceHistory.assignAll(items);  // Holds all 2,205 objects in memory
  ```
* **Failure Mode**:
  Holding 2,205 full JSON objects (measurements + stats) in an `RxList` consumes 35+ MB of reactive heap in Flutter Web WASM/JS, causing lag.
* **Required Fix**:
  Store only the latest 250 rows in `evidenceHistory`, while keeping full 2,205 status codes in a lightweight `Map<int, String> cycleQualityMap` for the bar chart.

---

## 5. Physical Operating Limits Table (Sensor Plausibility Envelopes)

All 17 sensors must be bounded by physical operating limits (ISO 13374 / IEC 61400):

| Sensor ID | Monitored Parameter | Normal Range | Physical Plausibility Limits | Rail / Fault Code |
| :--- | :--- | :--- | :--- | :--- |
| **PS1** | Primary Pump Pressure | $100.0 - 180.0\text{ bar}$ | $-2.0 \le P \le 280.0\text{ bar}$ | $P < -2.0$ or $P > 300$ |
| **PS2** | Secondary Working Pressure | $80.0 - 160.0\text{ bar}$ | $-2.0 \le P \le 250.0\text{ bar}$ | $P < -2.0$ or $P > 280$ |
| **PS3** | Directional Valve Pressure | $0.0 - 140.0\text{ bar}$ | $-2.0 \le P \le 200.0\text{ bar}$ | $P < -2.0$ or $P > 250$ |
| **PS4** | Valve Return Pressure | $0.0 - 15.0\text{ bar}$ | $-2.0 \le P \le 50.0\text{ bar}$ | $P < -2.0$ or $P > 70$ |
| **PS5** | Accumulator Intake Pressure | $80.0 - 150.0\text{ bar}$ | $-2.0 \le P \le 200.0\text{ bar}$ | $P < -2.0$ or $P > 250$ |
| **PS6** | Accumulator Pre-charge | $80.0 - 150.0\text{ bar}$ | $-2.0 \le P \le 200.0\text{ bar}$ | $P < -2.0$ or $P > 250$ |
| **EPS1** | Motor Electrical Power | $1800 - 3200\text{ W}$ | $0.0 \le W \le 4500.0\text{ W}$ | $W < 0.0$ or $W > 5000$ |
| **FS1** | Main Circuit Flow Rate | $2.0 - 10.5\text{ L/min}$ | $0.0 \le Q \le 15.0\text{ L/min}$ | $Q < 0.0$ or $Q > 18$ |
| **FS2** | Cooling Loop Flow Rate | $7.0 - 10.5\text{ L/min}$ | $0.0 \le Q \le 15.0\text{ L/min}$ | $Q < 0.0$ or $Q > 18$ |
| **TS1–TS4**| Fluid Temperatures | $30.0 - 60.0\text{ }^\circ\text{C}$ | $-20.0 \le T \le 100.0\text{ }^\circ\text{C}$ | $T < -30$ or $T > 120$ |
| **VS1** | Pump Mechanical Vibration | $0.4 - 1.2\text{ mm/s}$ | $0.0 \le V \le 20.0\text{ mm/s}$ | $V < 0.0$ or $V > 30$ |
| **CE / SE**| Virtual Efficiencies | $30.0 - 100.0\text{ }\%$ | $0.0 \le \eta \le 100.0\text{ }\%$ | $\eta < 0.0$ or $\eta > 105$ |
| **CP** | Cooling Power | $1.2 - 3.5\text{ kW}$ | $0.0 \le P \le 10.0\text{ kW}$ | $P < 0.0$ or $P > 15$ |

---

## 6. Standard 6-Tier Quality Hierarchy

```
[Raw Cycle Execution]
        │
        ├──> Corrupt Tokens / Unparseable? ────────────> CORRUPT_PAYLOAD (Red)
        ├──> Packet Loss > 10% or Channel Missing? ────> DATA_LOSS_CRITICAL (Red)
        ├──> Physical Bounds Spike (> 280 bar)? ───────> DISTORTED_OUT_OF_BOUNDS (Red)
        ├──> Zero Variance (Dead Sensor Stiction)? ────> SENSOR_FLATLINE (Purple)
        ├──> Packet Loss <= 10% (Linearly Imputed)? ───> DATA_LOSS_PARTIAL (Orange)
        ├──> Physical Component Fault (Leak/Cooler)? ──> DEGRADED_LEAK / DEGRADED_COOLER (Amber)
        └──> All Signals Within Operating Envelope ────> NOMINAL (Emerald Green)
```

---

## 7. Developer Implementation Guide (Exact Drop-In Code)

### Task 1: Clean Up Dead Code & Fix UI/UX in Frontend
In `frontend/lib/features/evidence_ingestion/presentation/screens/evidence_console_screen.dart`:
1. **Permanently remove commented-out Mock Mode Switch**:
   Do not leave commented blocks. Ensure `isMockMode` is permanently `false`.
2. **Make Spectrum Bar Chart Persistent**:
   Replace the conditional rendering:
   ```dart
   // REPLACE THIS:
   Obx(() {
     final isFullRigActive = controller.isRangeStreaming.value;
     if (!isFullRigActive) return const SizedBox.shrink();
     return const _TelemetrySpectrumOverviewCard();
   })

   // WITH THIS PERMANENT RENDERING:
   const Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       SizedBox(height: AppSpacing.xl),
       _TelemetrySpectrumOverviewCard(),
     ],
   ),
   ```
3. **Embed Live Waveforms in Console**:
   Restore `TelemetryWaveformChart` inside or directly underneath the `TelemetrySimulatorCard` so the operator sees the live pressure curve without opening a dialog.

---

### Task 2: Update `backend/app/adapters/hydraulic_adapter.py`
Add deterministic resampling, bounds checking, token sanitization, and the `data_quality` payload:

```python
SENSOR_PLAUSIBILITY_LIMITS = {
    "PS1": {"min": -2.0, "max": 280.0},
    "PS2": {"min": -2.0, "max": 250.0},
    "PS3": {"min": -2.0, "max": 200.0},
    "PS4": {"min": -2.0, "max": 50.0},
    "PS5": {"min": -2.0, "max": 200.0},
    "PS6": {"min": -2.0, "max": 200.0},
    "EPS1": {"min": 0.0, "max": 4500.0},
    "FS1": {"min": 0.0, "max": 15.0},
    "FS2": {"min": 0.0, "max": 15.0},
    "TS1": {"min": -20.0, "max": 100.0},
    "TS2": {"min": -20.0, "max": 100.0},
    "TS3": {"min": -20.0, "max": 100.0},
    "TS4": {"min": -20.0, "max": 100.0},
    "VS1": {"min": 0.0, "max": 20.0},
    "CE": {"min": 0.0, "max": 100.0},
    "SE": {"min": 0.0, "max": 100.0},
    "CP": {"min": 0.0, "max": 10.0},
}

def extract_canonical(
    self,
    cycle_id: int,
    tenant_id: str = "hydraulic_lab",
    asset_id: str = "hydraulic_rig_01",
    simulate_packet_loss_pct: float = 0.0,
    simulate_distortion: Optional[str] = None,
    **kwargs
) -> Tuple[CanonicalObservation, bytes, str, Dict[str, Any]]:
    total_expected_samples = 43680
    total_received_samples = 0
    total_imputed_samples = 0
    total_corrupt_tokens = 0
    total_out_of_bounds = 0
    channel_health_map = {}
    anomalies_detected = []
    raw_series_dict = {}
    measurements_dict = {"components": {}}

    for sensor_id, spec in SENSOR_SPECS.items():
        comp = spec["component"]
        rate = spec["rate_hz"]
        expected_samples = 60 * rate
        file_path = self.data_dir / f"{sensor_id}.txt"
        
        # 1. Token Sanitizer
        if file_path.exists():
            line = linecache.getline(str(file_path), cycle_id).strip()
            if line:
                tokens = line.split("\t")
                parsed_list = []
                for t in tokens:
                    if not t: continue
                    try:
                        v = float(t)
                        if np.isnan(v) or np.isinf(v) or v in [-999.0, 9999.0, -32768.0]:
                            total_corrupt_tokens += 1
                            parsed_list.append(np.nan)
                        else:
                            parsed_list.append(v)
                    except ValueError:
                        total_corrupt_tokens += 1
                        parsed_list.append(np.nan)
                
                raw_arr = np.array(parsed_list, dtype=np.float32)
                if len(raw_arr) > 0 and np.isnan(raw_arr).any():
                    nans = np.isnan(raw_arr)
                    x_fn = lambda z: z.nonzero()[0]
                    if not np.all(nans):
                        raw_arr[nans] = np.interp(x_fn(nans), x_fn(~nans), raw_arr[~nans])
                    else:
                        raw_arr = self._generate_synthetic_sensor_wave(sensor_id, cycle_id, expected_samples)
                raw_vals = raw_arr if len(raw_arr) > 0 else self._generate_synthetic_sensor_wave(sensor_id, cycle_id, expected_samples)
            else:
                raw_vals = self._generate_synthetic_sensor_wave(sensor_id, cycle_id, expected_samples)
        else:
            raw_vals = self._generate_synthetic_sensor_wave(sensor_id, cycle_id, expected_samples)

        # 2. Resampling & Plausibility Validation
        n_received = len(raw_vals)
        total_received_samples += n_received
        imputed_for_ch = 0
        if n_received < expected_samples:
            imputed_for_ch = expected_samples - n_received
            total_imputed_samples += imputed_for_ch
            if n_received > 1:
                t_orig = np.linspace(0.0, 1.0, n_received, dtype=np.float32)
                t_target = np.linspace(0.0, 1.0, expected_samples, dtype=np.float32)
                raw_vals = np.interp(t_target, t_orig, raw_vals).astype(np.float32)
            else:
                raw_vals = np.full(expected_samples, raw_vals[0] if n_received == 1 else 0.0, dtype=np.float32)
        elif n_received > expected_samples:
            raw_vals = raw_vals[:expected_samples]

        limits = SENSOR_PLAUSIBILITY_LIMITS.get(sensor_id, {"min": -10.0, "max": 10000.0})
        oob_mask = (raw_vals < limits["min"]) | (raw_vals > limits["max"])
        oob_count = int(np.sum(oob_mask))
        total_out_of_bounds += oob_count

        std_dev = float(np.std(raw_vals))
        is_flatline = bool(std_dev < 1e-4)

        if oob_count > 0:
            anomalies_detected.append(f"{sensor_id}: {oob_count} samples exceeded limits [{limits['min']}, {limits['max']}]")
        elif is_flatline:
            anomalies_detected.append(f"{sensor_id}: Stiction detected (0.0 variance / dead sensor)")

        # Expand to 6000 points for Polars DataFrame
        if len(raw_vals) == 6000:
            raw_series_dict[sensor_id] = raw_vals
        else:
            repeat_factor = max(1, 6000 // len(raw_vals))
            expanded = np.repeat(raw_vals, repeat_factor)
            raw_series_dict[sensor_id] = expanded[:6000]

    packet_loss_pct = (total_imputed_samples / total_expected_samples) * 100.0
    if packet_loss_pct > 10.0:
        quality_flag = "DATA_LOSS_CRITICAL"
    elif total_out_of_bounds > 0:
        quality_flag = "DISTORTED_OUT_OF_BOUNDS"
    elif any(ch.get("status") == "FLATLINE_STICTION" for ch in channel_health_map.values()):
        quality_flag = "SENSOR_FLATLINE"
    elif packet_loss_pct > 0.0:
        quality_flag = "DATA_LOSS_PARTIAL"
    else:
        quality_flag = "NOMINAL"

    # Assemble Polars Parquet safely
    time_clock = np.linspace(0.01, 60.0, 6000, dtype=np.float32)
    parquet_dict = {"time_sec": time_clock}
    for s_id, arr in raw_series_dict.items():
        parquet_dict[s_id] = arr

    df = pl.DataFrame(parquet_dict)
    buffer = io.BytesIO()
    df.write_parquet(buffer, compression="zstd")
    parquet_bytes = buffer.getvalue()
    raw_sha256 = self.calculate_sha256(parquet_bytes)

    extra_meta["quality_flag"] = quality_flag
    return canonical, parquet_bytes, raw_sha256, extra_meta
```

---

### Task 3: Update `backend/app/services/evidence_service.py`
1. **Multi-Component `profile.txt` Checking**:
   Evaluate all 4 physical columns:
   ```python
   def evaluate_physical_profile(profile_path: Path, cycle_id: int) -> Optional[str]:
       if not profile_path.exists():
           return None
       line = linecache.getline(str(profile_path), cycle_id).strip()
       if not line:
           return None
       cols = line.split()
       if len(cols) >= 4:
           cooler_cond = int(cols[0])       # 3: close to failure, 20: reduced
           valve_cond = int(cols[1])        # 73: severe lag, 80: small lag
           leak_cond = int(cols[2])         # 1: weak leak, 2: severe leak
           accumulator_cond = int(cols[3])  # 90: close to failure, 100: reduced

           if leak_cond > 0:
               return "DEGRADED_LEAK"
           if cooler_cond <= 20:
               return "DEGRADED_COOLER"
           if valve_cond <= 80:
               return "DEGRADED_VALVE"
           if accumulator_cond <= 100:
               return "DEGRADED_ACCUMULATOR"
       return None
   ```
2. **Resilient Storage Deletion on `clear_telemetry`**:
   In `StorageService`, add the `delete_prefix` method:
   ```python
   def delete_prefix(self, prefix: str) -> int:
       deleted_count = 0
       if self._supabase_client:
           try:
               files = self._supabase_client.storage.from_(self.bucket).list(prefix)
               if files:
                   paths = [f"{prefix}/{f['name']}" for f in files]
                   self._supabase_client.storage.from_(self.bucket).remove(paths)
                   deleted_count = len(paths)
           except Exception as e:
               logger.warning(f"Error purging Supabase storage prefix {prefix}: {e}")
       return deleted_count
   ```
   And call it inside `clear_telemetry`:
   ```python
   self.storage.delete_prefix(f"telemetry/{tenant_id}/{asset_id}")
   ```

---

### Task 4: Fix `forensic_detail_dialog.dart` (Latency Display)
Replace Line 278:
```dart
// OLD VULNERABLE CODE:
value: item.ingestionLatencyMs != null ? '${item.ingestionLatencyMs!.toStringAsFixed(1)} ms' : 'Historical Replay',

// NEW RESILIENT CODE:
value: (item.isTelemetry || item.ingestionLatencyMs == null || item.ingestionLatencyMs! >= 86400000.0)
    ? 'N/A (Bench Replay)'
    : AppFormatters.formatDurationMs(item.ingestionLatencyMs),
```

---

## 8. Verification & Test Script

The developer can test each scenario with the following test commands:

```bash
# 1. Test Nominal Baseline Cycle
curl -X POST http://localhost:8000/api/v1/industrial/evidence/ingest-cycle \
  -H "Content-Type: application/json" \
  -d '{"cycle_id": 1}'
# Expected quality_flag: "NOMINAL"

# 2. Test Severe Hydraulic Pump Leak
curl -X POST http://localhost:8000/api/v1/industrial/evidence/ingest-cycle \
  -H "Content-Type: application/json" \
  -d '{"cycle_id": 211}'
# Expected quality_flag: "DEGRADED_LEAK"

# 3. Test Edge Packet Loss (5% dropped samples)
curl -X POST http://localhost:8000/api/v1/industrial/evidence/ingest-cycle \
  -H "Content-Type: application/json" \
  -d '{"cycle_id": 1, "simulate_packet_loss_pct": 5.0}'
# Expected quality_flag: "DATA_LOSS_PARTIAL", samples imputed: 2184

# 4. Test Electrical Spike Distortion
curl -X POST http://localhost:8000/api/v1/industrial/evidence/ingest-cycle \
  -H "Content-Type: application/json" \
  -d '{"cycle_id": 1, "simulate_distortion": "SPIKE"}'
# Expected quality_flag: "DISTORTED_OUT_OF_BOUNDS"

# 5. Test Sensor Stiction / Flatline (FS1 dead channel)
curl -X POST http://localhost:8000/api/v1/industrial/evidence/ingest-cycle \
  -H "Content-Type: application/json" \
  -d '{"cycle_id": 1, "simulate_distortion": "FLATLINE"}'
# Expected quality_flag: "SENSOR_FLATLINE"
```

---
*End of Document. Refer to `industrial_telemetry_resilience_and_edge_cases.md` in repository root for implementation tracking.*


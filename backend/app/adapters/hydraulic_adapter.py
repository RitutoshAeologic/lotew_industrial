"""
UCI Hydraulic Multi-Rate Telemetry Adapter.
Processes 17 simultaneous sensors at 100 Hz, 10 Hz, and 1 Hz across 60-second operational cycles.
Compresses raw waveforms into Apache Parquet (ZSTD) and extracts CanonicalObservation v1.
Enforces the Anchor Epoch time-synchronization formula:
    event_time = Anchor Epoch + (cycle_id - 1) * 60 seconds
"""

from datetime import datetime, timedelta, timezone
import io
import linecache
from pathlib import Path
import time
from typing import Any, Dict, Optional, Tuple

import numpy as np
import polars as pl

from ..models.canonical import CanonicalObservation, TimestampsBlock
from .base import BaseIndustryAdapter

# 17 UCI Hydraulic Test Bench Sensors
SENSOR_SPECS = {
    # 100 Hz Sensors (6,000 samples per 60s cycle)
    "PS1": {"component": "pump", "rate_hz": 100, "unit": "bar", "name": "Primary Pump Pressure"},
    "PS2": {"component": "pump", "rate_hz": 100, "unit": "bar", "name": "Secondary Working Pressure"},
    "PS3": {"component": "valve", "rate_hz": 100, "unit": "bar", "name": "Directional Valve Pressure"},
    "PS4": {"component": "valve", "rate_hz": 100, "unit": "bar", "name": "Valve Return Pressure"},
    "PS5": {"component": "accumulator", "rate_hz": 100, "unit": "bar", "name": "Accumulator Intake Pressure"},
    "PS6": {"component": "accumulator", "rate_hz": 100, "unit": "bar", "name": "Accumulator Pre-charge Pressure"},
    "EPS1": {"component": "accumulator", "rate_hz": 100, "unit": "W", "name": "Electric Motor Power"},

    # 10 Hz Sensors (600 samples per 60s cycle)
    "FS1": {"component": "pump", "rate_hz": 10, "unit": "L/min", "name": "Main Circuit Flow Rate"},
    "FS2": {"component": "valve", "rate_hz": 10, "unit": "L/min", "name": "Secondary Circuit Flow Rate"},

    # 1 Hz Sensors (60 samples per 60s cycle)
    "SE": {"component": "valve", "rate_hz": 1, "unit": "%", "name": "Valve Switching Efficiency"},
    "TS1": {"component": "cooler", "rate_hz": 1, "unit": "degC", "name": "Oil Temperature upstream Cooler"},
    "TS2": {"component": "cooler", "rate_hz": 1, "unit": "degC", "name": "Oil Temperature downstream Cooler"},
    "TS3": {"component": "cooler", "rate_hz": 1, "unit": "degC", "name": "Oil Temperature upstream Tank"},
    "TS4": {"component": "cooler", "rate_hz": 1, "unit": "degC", "name": "Oil Temperature downstream Tank"},
    "CE": {"component": "cooler", "rate_hz": 1, "unit": "%", "name": "Cooling Efficiency Virtual Sensor"},
    "CP": {"component": "cooler", "rate_hz": 1, "unit": "kW", "name": "Cooling Power Virtual Sensor"},
    "VS1": {"component": "vibration", "rate_hz": 1, "unit": "mm/s", "name": "Pump Vibration Level"},
}

# Physical Operating Limits (ISO 13374 / IEC 61400) Plausibility Envelopes
SENSOR_PLAUSIBILITY_LIMITS = {
    "PS1": {"min": -2.0, "max": 280.0, "unit": "bar"},
    "PS2": {"min": -2.0, "max": 250.0, "unit": "bar"},
    "PS3": {"min": -2.0, "max": 200.0, "unit": "bar"},
    "PS4": {"min": -2.0, "max": 50.0, "unit": "bar"},
    "PS5": {"min": -2.0, "max": 200.0, "unit": "bar"},
    "PS6": {"min": -2.0, "max": 200.0, "unit": "bar"},
    "EPS1": {"min": 0.0, "max": 4500.0, "unit": "W"},
    "FS1": {"min": 0.0, "max": 22.0, "unit": "L/min"},
    "FS2": {"min": 0.0, "max": 20.0, "unit": "L/min"},
    "TS1": {"min": -20.0, "max": 100.0, "unit": "degC"},
    "TS2": {"min": -20.0, "max": 100.0, "unit": "degC"},
    "TS3": {"min": -20.0, "max": 100.0, "unit": "degC"},
    "TS4": {"min": -20.0, "max": 100.0, "unit": "degC"},
    "VS1": {"min": 0.0, "max": 20.0, "unit": "mm/s"},
    "CE": {"min": 0.0, "max": 100.0, "unit": "%"},
    "SE": {"min": 0.0, "max": 100.0, "unit": "%"},
    "CP": {"min": 0.0, "max": 10.0, "unit": "kW"},
}

# Dynamic channels expected to fluctuate during active machine execution
DYNAMIC_SENSORS = {"PS1", "PS2", "EPS1", "FS1", "FS2"}


class HydraulicRigAdapter(BaseIndustryAdapter):
    """
    Simultaneous 17-Sensor Lockstep Reader & Parquet Compressor.
    Extracts Median, MAD, Min, Max per sensor stream, grouping by component.
    """

    def __init__(self, data_dir: Path, anchor_epoch: str = "2024-01-01T00:00:00.000Z"):
        self.data_dir = data_dir
        self.anchor_epoch = anchor_epoch
        # Parse anchor epoch with UTC timezone
        clean_epoch = anchor_epoch.replace("Z", "+00:00")
        self.anchor_dt = datetime.fromisoformat(clean_epoch)

    def calculate_cycle_event_time(self, cycle_id: int) -> datetime:
        """
        Deterministic Anchor Epoch Formula:
            event_time = Anchor Epoch + (cycle_id - 1) * 60 seconds
        """
        return self.anchor_dt + timedelta(seconds=(cycle_id - 1) * 60)

    def extract_canonical(
        self,
        cycle_id: int,
        tenant_id: str = "hydraulic_lab",
        asset_id: str = "hydraulic_rig_01",
        simulate_packet_loss_pct: float = 0.0,
        simulate_distortion: Optional[str] = None,
        **kwargs
    ) -> Tuple[CanonicalObservation, bytes, str, Dict[str, Any]]:
        t_start = time.perf_counter()
        ingestion_time = datetime.now(timezone.utc)

        if not (1 <= cycle_id <= 2205):
            raise ValueError(f"Cycle ID {cycle_id} out of bounds. Must be between 1 and 2205.")

        event_time = self.calculate_cycle_event_time(cycle_id)

        # PREVIOUS SIMPLE EXTRACTION (Preserved as comment per instructions):
        # raw_series_dict = {}
        # measurements_dict: Dict[str, Any] = {"components": {}}
        # is_synthetic = False
        # for sensor_id, spec in SENSOR_SPECS.items():
        #     comp = spec["component"]
        #     rate = spec["rate_hz"]
        #     unit = spec["unit"]
        #     expected_samples = 60 * rate
        #     file_path = self.data_dir / f"{sensor_id}.txt"
        #     if file_path.exists():
        #         line = linecache.getline(str(file_path), cycle_id).strip()
        #         if line:
        #             raw_vals = np.fromstring(line, sep="\t", dtype=np.float32)
        #         else:
        #             raw_vals = self._generate_synthetic_sensor_wave(sensor_id, cycle_id, expected_samples)
        #             is_synthetic = True
        #     else:
        #         raw_vals = self._generate_synthetic_sensor_wave(sensor_id, cycle_id, expected_samples)
        #         is_synthetic = True
        #     med = float(np.median(raw_vals))
        #     mad = float(np.median(np.abs(raw_vals - med)))
        #     min_val = float(np.min(raw_vals))
        #     max_val = float(np.max(raw_vals))
        #     if comp not in measurements_dict["components"]:
        #         measurements_dict["components"][comp] = {}
        #     measurements_dict["components"][comp][sensor_id] = {
        #         "median": round(med, 4), "mad": round(mad, 4), "min": round(min_val, 4), "max": round(max_val, 4),
        #         "rate_hz": rate, "unit": unit, "samples_count": len(raw_vals),
        #     }
        #     n_samples = len(raw_vals)
        #     if n_samples == 6000:
        #         raw_series_dict[sensor_id] = raw_vals
        #     elif n_samples > 0:
        #         repeat_factor = max(1, 6000 // n_samples)
        #         expanded = np.repeat(raw_vals, repeat_factor)
        #         if len(expanded) < 6000:
        #             expanded = np.pad(expanded, (0, 6000 - len(expanded)), mode="edge")
        #         raw_series_dict[sensor_id] = expanded[:6000]

        # NEW RESILIENT EXTRACTION & DETERMINISTIC CLOCK RESAMPLING:
        raw_series_dict = {}
        measurements_dict: Dict[str, Any] = {"components": {}}
        is_synthetic = False

        total_expected_samples = 43680
        total_received_samples = 0
        total_imputed_samples = 0
        total_corrupt_tokens = 0
        total_out_of_bounds = 0
        channel_health_map = {}
        anomalies_detected = []

        for sensor_id, spec in SENSOR_SPECS.items():
            comp = spec["component"]
            rate = spec["rate_hz"]
            unit = spec["unit"]
            expected_samples = 60 * rate

            file_path = self.data_dir / f"{sensor_id}.txt"
            raw_vals: np.ndarray

            # 1. Token Sanitizer (filters NaN, Inf, and PLC error codes)
            if file_path.exists():
                line = linecache.getline(str(file_path), cycle_id).strip()
                if line:
                    tokens = line.split("\t")
                    parsed_list = []
                    for t in tokens:
                        if not t:
                            continue
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
                            is_synthetic = True
                    raw_vals = raw_arr if len(raw_arr) > 0 else self._generate_synthetic_sensor_wave(sensor_id, cycle_id, expected_samples)
                    if len(raw_arr) == 0:
                        is_synthetic = True
                else:
                    raw_vals = self._generate_synthetic_sensor_wave(sensor_id, cycle_id, expected_samples)
                    is_synthetic = True
            else:
                raw_vals = self._generate_synthetic_sensor_wave(sensor_id, cycle_id, expected_samples)
                is_synthetic = True

            # 2. Simulated Edge Cases (if requested)
            if simulate_packet_loss_pct > 0.0:
                drop_count = int(len(raw_vals) * (simulate_packet_loss_pct / 100.0))
                if drop_count > 0:
                    keep_idx = np.sort(np.random.choice(len(raw_vals), max(1, len(raw_vals) - drop_count), replace=False))
                    raw_vals = raw_vals[keep_idx]

            if simulate_distortion == "SPIKE" and sensor_id == "PS1":
                spike_idx = min(2500, len(raw_vals) - 1)
                raw_vals = raw_vals.copy()
                raw_vals[spike_idx] = 345.8
                anomalies_detected.append("Electrical noise spike on PS1 (345.8 bar)")

            if simulate_distortion == "FLATLINE" and sensor_id == "FS1":
                raw_vals = np.zeros_like(raw_vals, dtype=np.float32)
                anomalies_detected.append("Sensor flatline / stiction on FS1 (0.0 L/min constant)")

            # 3. Deterministic Clock Resampling (guarantees exact expected_samples)
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

            # 4. Plausibility Bounds & Stiction Checking
            limits = SENSOR_PLAUSIBILITY_LIMITS.get(sensor_id, {"min": -10.0, "max": 10000.0})
            oob_mask = (raw_vals < limits["min"]) | (raw_vals > limits["max"])
            oob_count = int(np.sum(oob_mask))
            total_out_of_bounds += oob_count

            std_dev = float(np.std(raw_vals))
            is_flatline = bool(sensor_id in DYNAMIC_SENSORS and std_dev < 1e-4)

            ch_status = "HEALTHY"
            if oob_count > 0:
                ch_status = "OUT_OF_BOUNDS_SPIKE"
                anomalies_detected.append(f"{sensor_id}: {oob_count} samples exceeded limits [{limits['min']}, {limits['max']}]")
            elif is_flatline:
                ch_status = "FLATLINE_STICTION"
                anomalies_detected.append(f"{sensor_id}: Stiction detected (0.0 variance / dead sensor)")
            elif imputed_for_ch > 0:
                ch_status = f"PACKET_LOSS_{imputed_for_ch}_IMPUTED"
                anomalies_detected.append(f"{sensor_id}: {imputed_for_ch} missing samples linearly imputed")

            channel_health_map[sensor_id] = {
                "component": comp,
                "status": ch_status,
                "rate_hz": rate,
                "expected_samples": expected_samples,
                "received_samples": n_received,
                "imputed_samples": imputed_for_ch,
                "out_of_bounds_count": oob_count,
                "std_dev": round(std_dev, 4),
            }

            # 5. Robust statistical features
            med = float(np.median(raw_vals))
            mad = float(np.median(np.abs(raw_vals - med)))
            min_val = float(np.min(raw_vals))
            max_val = float(np.max(raw_vals))

            if comp not in measurements_dict["components"]:
                measurements_dict["components"][comp] = {}

            measurements_dict["components"][comp][sensor_id] = {
                "median": round(med, 4),
                "mad": round(mad, 4),
                "min": round(min_val, 4),
                "max": round(max_val, 4),
                "rate_hz": rate,
                "unit": unit,
                "samples_count": len(raw_vals),
                "std_dev": round(std_dev, 4),
                "channel_status": ch_status,
            }

            # 6. Align for Parquet table (all expanded to 6,000 points on 100 Hz clock)
            n_samples = len(raw_vals)
            if n_samples == 6000:
                raw_series_dict[sensor_id] = raw_vals
            elif n_samples > 0:
                repeat_factor = max(1, 6000 // n_samples)
                expanded = np.repeat(raw_vals, repeat_factor)
                if len(expanded) < 6000:
                    expanded = np.pad(expanded, (0, 6000 - len(expanded)), mode="edge")
                raw_series_dict[sensor_id] = expanded[:6000]

        # 7. Signal Quality Determination (Signal Level)
        packet_loss_pct = (total_imputed_samples / total_expected_samples) * 100.0
        if total_corrupt_tokens > 100:
            quality_flag = "CORRUPT_PAYLOAD"
        elif packet_loss_pct > 10.0:
            quality_flag = "DATA_LOSS_CRITICAL"
        elif total_out_of_bounds > 0:
            quality_flag = "DISTORTED_OUT_OF_BOUNDS"
        elif any(ch.get("status") == "FLATLINE_STICTION" for ch in channel_health_map.values()):
            quality_flag = "SENSOR_FLATLINE"
        elif packet_loss_pct > 0.0:
            quality_flag = "DATA_LOSS_PARTIAL"
        else:
            quality_flag = "NOMINAL"

        measurements_dict["data_quality"] = {
            "overall_status": quality_flag,
            "packet_loss_pct": round(packet_loss_pct, 2),
            "total_samples_expected": total_expected_samples,
            "total_samples_received": total_received_samples,
            "total_samples_imputed": total_imputed_samples,
            "corrupted_tokens_count": total_corrupt_tokens,
            "out_of_bounds_count": total_out_of_bounds,
            "anomalies_count": len(anomalies_detected),
            "anomalies_summary": anomalies_detected[:6],
            "channel_health": channel_health_map,
        }

        # Step 1.5: Downsampled 60s Waveforms for Live UI Visualization (1 sample/sec)
        ps1_raw = raw_series_dict.get("PS1")
        fs1_raw = raw_series_dict.get("FS1")
        if ps1_raw is not None and fs1_raw is not None:
            measurements_dict["waveform_downsampled_60s"] = {
                "time_sec": list(range(1, 61)),
                "PS1_pressure_bar": [round(float(v), 2) for v in ps1_raw[::100][:60]],
                "FS1_flow_lmin": [round(float(v), 2) for v in fs1_raw[::100][:60]],
            }

        # Step 2: Build Polars DataFrame and compress to Parquet (ZSTD)
        time_clock = np.linspace(0.01, 60.0, 6000, dtype=np.float32)
        parquet_dict = {"time_sec": time_clock}
        for sensor_id, arr in raw_series_dict.items():
            parquet_dict[sensor_id] = arr

        df = pl.DataFrame(parquet_dict)
        buffer = io.BytesIO()
        df.write_parquet(buffer, compression="zstd")
        parquet_bytes = buffer.getvalue()

        # Step 3: Compute SHA-256 fingerprint
        raw_sha256 = self.calculate_sha256(parquet_bytes)

        available_time = datetime.now(timezone.utc)
        t_end = time.perf_counter()

        processing_latency_ms = round((t_end - t_start) * 1000.0, 3)
        # For historical backfill (anchor epoch in 2024 vs current year), elapsed delta > 24h.
        # Set ingestion_latency_ms = None for historical replay to represent N/A.
        delta_sec = (ingestion_time - event_time).total_seconds()
        ingestion_latency_ms = round(delta_sec * 1000.0, 3) if 0 <= delta_sec <= 86400 else None

        timestamps = TimestampsBlock(
            event_time=event_time,
            ingestion_time=ingestion_time,
            available_time=available_time,
            ingestion_latency_ms=ingestion_latency_ms,
            processing_latency_ms=processing_latency_ms,
        )

        canonical = CanonicalObservation(
            tenant_id=tenant_id,
            source={
                "type": "TELEMETRY_CYCLE",
                "format": "PARQUET",
                "cycle_id": cycle_id,
                "raw_sha256": raw_sha256,
                "compression": "zstd",
                "sensors_count": len(SENSOR_SPECS),
                "total_samples": 43680,
                "is_synthetic": is_synthetic,
            },
            asset={
                "tenant_id": tenant_id,
                "asset_id": asset_id,
                "component_id": "system",
            },
            timestamps=timestamps,
            measurements=measurements_dict,
            metadata={
                "cycle_id": cycle_id,
                "cycle_duration_seconds": 60,
                "rig_specification": "UCI Hydraulic Test Bench (ZeMA)",
            }
        )

        extra_meta = {
            "is_synthetic": is_synthetic,
            "parquet_size_bytes": len(parquet_bytes),
            "quality_flag": quality_flag,
            "data_quality": measurements_dict.get("data_quality", {}),
        }

        return canonical, parquet_bytes, raw_sha256, extra_meta

    def _generate_synthetic_sensor_wave(self, sensor_id: str, cycle_id: int, count: int) -> np.ndarray:
        """Fallback synthetic generator if sensor text files are not present."""
        is_severe_leak = (cycle_id >= 211 and cycle_id <= 220)
        base = 151.0 if not is_severe_leak else 110.0
        if sensor_id in ["PS1", "PS2", "PS3", "PS4"]:
            return (base + np.random.randn(count) * 2.0).astype(np.float32)
        elif sensor_id in ["PS5", "PS6"]:
            return (115.0 + np.random.randn(count) * 1.5).astype(np.float32)
        elif sensor_id.startswith("FS"):
            return (7.5 + np.random.randn(count) * 0.5).astype(np.float32)
        elif sensor_id.startswith("TS"):
            return (35.0 + np.random.randn(count) * 0.8).astype(np.float32)
        elif sensor_id == "EPS1":
            return (2450.0 + np.random.randn(count) * 30.0).astype(np.float32)
        elif sensor_id == "VS1":
            return (0.8 + np.random.randn(count) * 0.05).astype(np.float32)
        elif sensor_id in ["CE", "SE"]:
            return (65.0 + np.random.randn(count) * 2.0).astype(np.float32)
        elif sensor_id == "CP":
            return (2.1 + np.random.randn(count) * 0.1).astype(np.float32)
        return (np.random.randn(count) * 2.0 + 20.0).astype(np.float32)

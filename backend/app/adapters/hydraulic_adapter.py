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
        **kwargs
    ) -> Tuple[CanonicalObservation, bytes, str, Dict[str, Any]]:
        t_start = time.perf_counter()
        ingestion_time = datetime.now(timezone.utc)

        if not (1 <= cycle_id <= 2205):
            raise ValueError(f"Cycle ID {cycle_id} out of bounds. Must be between 1 and 2205.")

        event_time = self.calculate_cycle_event_time(cycle_id)

        # Step 1: Read all 17 sensors for this cycle (or generate synthetic if files missing)
        raw_series_dict = {}
        measurements_dict: Dict[str, Any] = {"components": {}}
        is_synthetic = False

        for sensor_id, spec in SENSOR_SPECS.items():
            comp = spec["component"]
            rate = spec["rate_hz"]
            unit = spec["unit"]
            expected_samples = 60 * rate

            file_path = self.data_dir / f"{sensor_id}.txt"
            raw_vals: np.ndarray

            if file_path.exists():
                # linecache uses 1-based line indexing
                line = linecache.getline(str(file_path), cycle_id).strip()
                if line:
                    raw_vals = np.fromstring(line, sep="\t", dtype=np.float32)
                else:
                    raw_vals = self._generate_synthetic_sensor_wave(sensor_id, cycle_id, expected_samples)
                    is_synthetic = True
            else:
                raw_vals = self._generate_synthetic_sensor_wave(sensor_id, cycle_id, expected_samples)
                is_synthetic = True

            # Robust statistical features
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
            }

            # Align for Parquet table (all expanded to 6,000 points on 100 Hz clock)
            n_samples = len(raw_vals)
            if n_samples == 6000:
                raw_series_dict[sensor_id] = raw_vals
            elif n_samples > 0:
                repeat_factor = max(1, 6000 // n_samples)
                expanded = np.repeat(raw_vals, repeat_factor)
                if len(expanded) < 6000:
                    expanded = np.pad(expanded, (0, 6000 - len(expanded)), mode="edge")
                raw_series_dict[sensor_id] = expanded[:6000]

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
        # Set ingestion_latency_ms = 0.0 for historical replay to avoid NUMERIC(12, 3) overflow.
        delta_sec = (ingestion_time - event_time).total_seconds()
        ingestion_latency_ms = round(delta_sec * 1000.0, 3) if 0 <= delta_sec <= 86400 else 0.0

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
        }

        return canonical, parquet_bytes, raw_sha256, extra_meta

    def _generate_synthetic_sensor_wave(self, sensor_id: str, cycle_id: int, count: int) -> np.ndarray:
        """Fallback synthetic generator if sensor text files are not present."""
        is_severe_leak = (cycle_id >= 211 and cycle_id <= 220)
        base = 151.0 if not is_severe_leak else 110.0
        if sensor_id.startswith("PS"):
            return (base + np.random.randn(count) * 2.0).astype(np.float32)
        elif sensor_id.startswith("FS"):
            return (7.5 + np.random.randn(count) * 0.5).astype(np.float32)
        elif sensor_id.startswith("TS"):
            return (35.0 + np.random.randn(count) * 0.8).astype(np.float32)
        elif sensor_id == "EPS1":
            return (2450.0 + np.random.randn(count) * 30.0).astype(np.float32)
        return (np.random.randn(count) * 5.0 + 50.0).astype(np.float32)

"""
Unit Tests for Hydraulic Multi-Rate Telemetry Adapter.
Verifies Anchor Epoch calculation, 17-sensor lockstep parsing, and Parquet compression.
"""

from datetime import datetime, timezone
from pathlib import Path
import pytest

from app.adapters.hydraulic_adapter import HydraulicRigAdapter, SENSOR_SPECS
from app.core.config import get_settings


def test_anchor_epoch_time_calculation():
    """Validates deterministic Anchor Epoch formula."""
    settings = get_settings()
    adapter = HydraulicRigAdapter(
        data_dir=settings.get_hydraulic_data_path(),
        anchor_epoch="2024-01-01T00:00:00.000Z"
    )

    # Cycle 1: Anchor + 0s
    t1 = adapter.calculate_cycle_event_time(1)
    assert t1.isoformat() == "2024-01-01T00:00:00+00:00"

    # Cycle 2: Anchor + 60s
    t2 = adapter.calculate_cycle_event_time(2)
    assert t2.isoformat() == "2024-01-01T00:01:00+00:00"

    # Cycle 211 (Severe Pump Leakage): Anchor + 210 * 60s = 12600s = 3.5 hours = 03:30:00
    t211 = adapter.calculate_cycle_event_time(211)
    assert t211.isoformat() == "2024-01-01T03:30:00+00:00"


def test_hydraulic_cycle_extraction_cycle_1():
    """Extracts cycle 1 and checks 17 sensors and component groups."""
    settings = get_settings()
    adapter = HydraulicRigAdapter(
        data_dir=settings.get_hydraulic_data_path(),
        anchor_epoch=settings.ANCHOR_EPOCH
    )

    canonical, parquet_bytes, sha256, extra = adapter.extract_canonical(
        cycle_id=1,
        tenant_id="hydraulic_lab",
        asset_id="hydraulic_rig_01"
    )

    assert len(parquet_bytes) > 0
    assert len(sha256) == 64  # Valid SHA-256 hex string
    assert canonical.tenant_id == "hydraulic_lab"
    assert canonical.asset["component_id"] == "system"

    # Verify components grouped in measurements
    components = canonical.measurements["components"]
    assert "pump" in components
    assert "cooler" in components
    assert "valve" in components
    assert "accumulator" in components

    # Check pump sensors
    pump = components["pump"]
    assert "PS1" in pump
    assert "PS2" in pump
    assert "FS1" in pump
    assert pump["PS1"]["rate_hz"] == 100
    assert pump["PS1"]["unit"] == "bar"
    assert pump["FS1"]["rate_hz"] == 10
    assert pump["FS1"]["unit"] == "L/min"

    # Check cooler sensors
    cooler = components["cooler"]
    assert "TS1" in cooler
    assert "CE" in cooler
    assert "CP" in cooler
    assert cooler["TS1"]["unit"] == "degC"


def test_hydraulic_cycle_bounds_validation():
    """Cycle out-of-bounds must raise ValueError."""
    settings = get_settings()
    adapter = HydraulicRigAdapter(
        data_dir=settings.get_hydraulic_data_path(),
        anchor_epoch=settings.ANCHOR_EPOCH
    )

    with pytest.raises(ValueError):
        adapter.extract_canonical(cycle_id=0)

    with pytest.raises(ValueError):
        adapter.extract_canonical(cycle_id=2206)


def test_parquet_binary_integrity():
    """Validates that compressed Parquet bytes can be decompressed back to 6,000 rows x 18 cols."""
    import io
    import polars as pl

    settings = get_settings()
    adapter = HydraulicRigAdapter(
        data_dir=settings.get_hydraulic_data_path(),
        anchor_epoch=settings.ANCHOR_EPOCH
    )

    canonical, parquet_bytes, sha256, extra = adapter.extract_canonical(cycle_id=10)

    df_read = pl.read_parquet(io.BytesIO(parquet_bytes))
    assert df_read.height == 6000
    assert "time_sec" in df_read.columns
    for sensor in ["PS1", "PS2", "PS3", "PS4", "PS5", "PS6", "EPS1", "FS1", "FS2", "SE", "TS1", "TS2", "TS3", "TS4", "CE", "CP", "VS1"]:
        assert sensor in df_read.columns

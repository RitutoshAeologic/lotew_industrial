"""
Generic Industrial CSV Telemetry Adapter.
Processes continuous multi-sensor CSV logs (e.g. Metro do Porto compressor, SCANIA fleet, plant SCADA).
Compresses raw CSV into Apache Parquet (ZSTD) and extracts CanonicalObservation v1.
"""

from datetime import datetime, timezone
import io
import time
from typing import Any, Dict, Optional, Tuple

import numpy as np
import polars as pl

from ..models.canonical import CanonicalObservation, TimestampsBlock
from .base import BaseIndustryAdapter


class CsvTelemetryAdapter(BaseIndustryAdapter):
    """
    Parses any multi-column sensor CSV telemetry file.
    - Polars-powered high performance parsing
    - Calculates robust statistics (Median, MAD, Min, Max) per sensor channel
    - ZSTD Parquet compression for tiered storage
    """

    def extract_canonical(
        self,
        file_bytes: bytes,
        file_name: str,
        tenant_id: str,
        asset_id: str,
        component_id: Optional[str] = None,
        **kwargs
    ) -> Tuple[CanonicalObservation, bytes, str, Dict[str, Any]]:
        t_start = time.perf_counter()
        ingestion_time = datetime.now(timezone.utc)

        # 1. Cryptographic SHA-256 of original CSV bytes
        raw_sha256 = self.calculate_sha256(file_bytes)

        # 2. Read CSV via Polars
        try:
            df = pl.read_csv(io.BytesIO(file_bytes), ignore_errors=True)
        except Exception as e:
            raise ValueError(f"Invalid or corrupted CSV file: {str(e)}")

        if df.height == 0:
            raise ValueError("Uploaded CSV file contains no data rows.")

        # 3. Detect Timestamp / Time column
        time_cols = [c for c in df.columns if any(k in c.lower() for k in ["time", "date", "timestamp", "clock"])]
        event_time = ingestion_time
        if time_cols:
            first_time_col = time_cols[0]
            try:
                # Attempt to parse first row as datetime
                first_val = str(df[first_time_col][0])
                clean_val = first_val.replace("Z", "+00:00")
                event_time = datetime.fromisoformat(clean_val)
                if event_time.tzinfo is None:
                    event_time = event_time.replace(tzinfo=timezone.utc)
            except Exception:
                event_time = ingestion_time

        # 4. Extract statistical summaries for all numeric channels
        measurements_dict: Dict[str, Any] = {"channels": {}}
        numeric_cols = []

        for col_name in df.columns:
            if col_name in time_cols:
                continue
            col_series = df[col_name]
            # Check if numeric
            if col_series.dtype in [pl.Float32, pl.Float64, pl.Int32, pl.Int64, pl.UInt32, pl.UInt64]:
                numeric_cols.append(col_name)
                # Drop nulls for statistics
                valid_vals = col_series.drop_nulls().to_numpy()
                if len(valid_vals) > 0:
                    med = float(np.median(valid_vals))
                    mad = float(np.median(np.abs(valid_vals - med)))
                    min_val = float(np.min(valid_vals))
                    max_val = float(np.max(valid_vals))

                    measurements_dict["channels"][col_name] = {
                        "median": round(med, 4),
                        "mad": round(mad, 4),
                        "min": round(min_val, 4),
                        "max": round(max_val, 4),
                        "samples_count": len(valid_vals),
                    }

        # 5. Compress to Parquet (ZSTD)
        parquet_buf = io.BytesIO()
        df.write_parquet(parquet_buf, compression="zstd")
        parquet_bytes = parquet_buf.getvalue()

        # Parquet SHA-256 for persistent object storage
        parquet_sha256 = self.calculate_sha256(parquet_bytes)

        available_time = datetime.now(timezone.utc)
        t_end = time.perf_counter()

        processing_latency_ms = round((t_end - t_start) * 1000.0, 3)
        ingestion_latency_ms = round(max(0.0, (ingestion_time - event_time).total_seconds() * 1000.0), 3)

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
                "type": "CSV_TELEMETRY",
                "format": "PARQUET",
                "original_file_name": file_name,
                "original_csv_sha256": raw_sha256,
                "parquet_sha256": parquet_sha256,
                "row_count": df.height,
                "channel_count": len(numeric_cols),
                "compression": "zstd",
            },
            asset={
                "tenant_id": tenant_id,
                "asset_id": asset_id,
                "component_id": component_id or "system",
            },
            timestamps=timestamps,
            measurements=measurements_dict,
            metadata={
                "original_format": "CSV",
                "parsed_columns": df.columns,
            }
        )

        extra_meta = {
            "row_count": df.height,
            "channel_count": len(numeric_cols),
            "parquet_size_bytes": len(parquet_bytes),
        }

        return canonical, parquet_bytes, parquet_sha256, extra_meta

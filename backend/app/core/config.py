"""
Application Configuration for Lotew Industrial Backend.
Includes the canonical Anchor Epoch, storage settings, and tenancy definitions.
"""

from functools import lru_cache
from pathlib import Path
from typing import List

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ── Application Metadata ───────────────────────────────────────────────────
    APP_NAME: str = "Lotew Industrial Core Engine"
    APP_VERSION: str = "1.0.0"
    APP_DESCRIPTION: str = "Standalone high-integrity industrial telemetry and documentary evidence ingestion service."
    ENVIRONMENT: str = "development"
    DEBUG: bool = True

    # ── Server ────────────────────────────────────────────────────────────────
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    API_V1_PREFIX: str = "/api/v1/industrial"

    # ── CORS ──────────────────────────────────────────────────────────────────
    CORS_ORIGINS: str = Field(
        default="http://localhost:3000,http://localhost:8080,http://localhost:5000,http://127.0.0.1:3000,*",
        validation_alias="CORS_ORIGINS",
    )

    @property
    def cors_origins_list(self) -> List[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]

    # ── Non-Negotiable Time Architecture (Anchor Epoch) ───────────────────────
    # Synchronizes discrete 60-second operational cycles with real-world maintenance logs
    ANCHOR_EPOCH: str = "2024-01-01T00:00:00.000Z"
    CYCLE_DURATION_SECONDS: int = 60
    TOTAL_AVAILABLE_CYCLES: int = 2205

    # ── Storage Tiering (Supabase & Local Parquet Fallback) ────────────────────
    STORAGE_BUCKET: str = "industrial-raw"
    LOCAL_STORAGE_DIR: str = "storage/industrial-raw"
    SUPABASE_URL: str = Field(default="", validation_alias="SUPABASE_URL")
    SUPABASE_KEY: str = Field(default="", validation_alias="SUPABASE_KEY")
    DATABASE_URL: str = Field(default="", validation_alias="DATABASE_URL")

    # ── Dataset Location ──────────────────────────────────────────────────────
    # Searches relative to project root or workspace
    HYDRAULIC_DATA_DIR: str = Field(
        default="",
        validation_alias="HYDRAULIC_DATA_DIR"
    )

    def get_hydraulic_data_path(self) -> Path:
        """Resolve the path to the 17 UCI hydraulic sensor files."""
        if self.HYDRAULIC_DATA_DIR:
            p = Path(self.HYDRAULIC_DATA_DIR)
            if p.exists():
                return p

        # Check candidate locations
        candidates = [
            Path(__file__).resolve().parents[4] / "data" / "hydraulic",
            Path(__file__).resolve().parents[3] / "data" / "hydraulic",
            Path.cwd() / "data" / "hydraulic",
            Path("/Users/ritutosh/StudioProjects/lotew_backend/data/hydraulic"),
        ]
        for candidate in candidates:
            if candidate.exists() and (candidate / "PS1.txt").exists():
                return candidate

        return Path("data/hydraulic")


@lru_cache()
def get_settings() -> Settings:
    return Settings()


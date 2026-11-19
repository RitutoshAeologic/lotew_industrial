"""
Lotew Industrial Core Backend Application.
Standalone FastAPI service for multi-rate telemetry and documentary evidence ingestion.
Complies 100% with platform separation and zero-database-bloat rules.
"""

from contextlib import asynccontextmanager
from datetime import datetime, timezone
import logging
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .api.v1.evidence import router as evidence_router
from .core.config import get_settings
from .models.canonical import HealthResponse

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("lotew.industrial.main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    data_path = settings.get_hydraulic_data_path()
    has_dataset = (data_path / "PS1.txt").exists() if data_path else False

    logger.info("=" * 70)
    logger.info("🚀 INITIALIZING LOTEW INDUSTRIAL CORE ENGINE (lotew-industrial)")
    logger.info(f"   • Service: {settings.APP_NAME} v{settings.APP_VERSION}")
    logger.info(f"   • Anchor Epoch: {settings.ANCHOR_EPOCH}")
    logger.info(f"   • Dataset Path: {data_path.resolve() if data_path else 'None'}")
    logger.info(f"   • Dataset Present: {'✓ YES (2,205 cycles)' if has_dataset else '⚠ FALLBACK SYNTHETIC'}")
    logger.info(f"   • Object Storage: Supabase '{settings.STORAGE_BUCKET}' with local fallback")
    logger.info("=" * 70)
    yield
    logger.info("Shutting down Lotew Industrial Core Engine.")


settings = get_settings()

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description=settings.APP_DESCRIPTION,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── Cross-Origin Resource Sharing (CORS) ──────────────────────────────────────
# Enables Flutter Web running on Chrome to communicate without browser SOP restrictions
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(evidence_router)


# ── Health Endpoints ──────────────────────────────────────────────────────────
@app.get("/health", response_model=HealthResponse, tags=["Health"])
@app.get("/api/v1/industrial/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    data_path = settings.get_hydraulic_data_path()
    has_dataset = (data_path / "PS1.txt").exists() if data_path else False

    return HealthResponse(
        status="HEALTHY",
        service=settings.APP_NAME,
        version=settings.APP_VERSION,
        dataset_available=has_dataset,
        cycles_count=2205 if has_dataset else 0,
        storage_mode="SUPABASE_AND_LOCAL" if settings.SUPABASE_URL else "LOCAL_MIRROR",
        timestamp=datetime.now(timezone.utc),
    )


# ── Static Flutter Web Serving (Unified Single-Origin Deployment) ──────────────
frontend_dist = Path(__file__).resolve().parent.parent.parent / "frontend" / "build" / "web"
if frontend_dist.exists() and (frontend_dist / "index.html").exists():
    app.mount("/", StaticFiles(directory=str(frontend_dist), html=True), name="frontend")
    logger.info(f"   • Flutter Web Distribution mounted at root: {frontend_dist}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host=settings.HOST, port=settings.PORT, reload=True)


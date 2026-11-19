"""
Object Storage Service for High-Rate Parquet and PDF Documentary Evidence.
Uploads to Supabase Storage Bucket ('industrial-raw') with transparent local filesystem fallback.
"""

import logging
from pathlib import Path
from typing import Optional

from ..core.config import Settings, get_settings

logger = logging.getLogger("lotew.industrial.storage")


class StorageService:
    """
    Tiered Storage Manager.
    Raw multi-megabyte sensor streams and PDF binaries NEVER enter PostgreSQL directly.
    They are stored in Object Storage; only metadata and Canonical JSON reside in Postgres.
    """

    def __init__(self, settings: Optional[Settings] = None):
        self.settings = settings or get_settings()
        self.bucket = self.settings.STORAGE_BUCKET
        self.local_root = Path(self.settings.LOCAL_STORAGE_DIR)
        self.local_root.mkdir(parents=True, exist_ok=True)

        self._supabase_client = None
        if self.settings.SUPABASE_URL and self.settings.SUPABASE_KEY:
            try:
                from supabase import create_client
                self._supabase_client = create_client(
                    self.settings.SUPABASE_URL,
                    self.settings.SUPABASE_KEY
                )
                logger.info("Supabase storage client initialized successfully.")
            except Exception as e:
                logger.warning(f"Failed to initialize Supabase storage client: {e}. Falling back to local storage.")

    def upload(self, storage_path: str, data: bytes, mime_type: str = "application/octet-stream") -> str:
        """
        Uploads binary bytes to object storage.
        Returns:
            storage_path (relative path within bucket)
        """
        # Always write to local storage as an immutable local mirror
        local_file = self.local_root / storage_path
        local_file.parent.mkdir(parents=True, exist_ok=True)
        local_file.write_bytes(data)

        # Upload to Supabase Storage if available
        if self._supabase_client:
            try:
                self._supabase_client.storage.from_(self.bucket).upload(
                    path=storage_path,
                    file=data,
                    file_options={"content-type": mime_type, "upsert": "true"}
                )
                logger.info(f"Uploaded {storage_path} ({len(data)} bytes) to Supabase Storage bucket '{self.bucket}'.")
            except Exception as e:
                logger.warning(f"Supabase upload failed for {storage_path}: {e}. Local file preserved.")

        return storage_path

    def read(self, storage_path: str) -> Optional[bytes]:
        """Reads file bytes from storage."""
        if self._supabase_client:
            try:
                res = self._supabase_client.storage.from_(self.bucket).download(storage_path)
                if res:
                    return res
            except Exception as e:
                logger.warning(f"Failed reading from Supabase storage: {e}. Checking local mirror.")

        local_file = self.local_root / storage_path
        if local_file.exists():
            return local_file.read_bytes()

        return None


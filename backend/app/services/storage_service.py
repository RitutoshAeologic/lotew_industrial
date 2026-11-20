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
        supabase_url = self.settings.clean_supabase_url
        supabase_key = self.settings.active_supabase_key
        if supabase_url and supabase_key:
            try:
                from supabase import create_client
                self._supabase_client = create_client(
                    supabase_url,
                    supabase_key
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

    def delete_prefix(self, prefix: str) -> int:
        """
        Purges all object storage files matching prefix from both Supabase and local mirror.
        Prevents orphaned Parquet binaries from accumulating in cloud storage.
        """
        import shutil

        deleted_remote_count = 0
        clean_folder = prefix.strip("/")

        # 1. Purge from Supabase Storage
        if self._supabase_client:
            try:
                while True:
                    items = self._supabase_client.storage.from_(self.bucket).list(clean_folder, {"limit": 100})
                    if not items:
                        break
                    file_paths = []
                    for item in items:
                        name = item.get("name")
                        if name:
                            file_paths.append(f"{clean_folder}/{name}")
                    if not file_paths:
                        break
                    self._supabase_client.storage.from_(self.bucket).remove(file_paths)
                    deleted_remote_count += len(file_paths)
                    logger.info(f"Deleted batch of {len(file_paths)} files from Supabase bucket '{self.bucket}' under '{clean_folder}'.")
                    if len(items) < 100:
                        break
            except Exception as e:
                logger.warning(f"Failed deleting prefix '{prefix}' from Supabase Storage: {e}")

        # 2. Purge from local mirror directory
        deleted_local_count = 0
        local_dir = self.local_root / clean_folder
        if local_dir.exists():
            if local_dir.is_dir():
                for f in local_dir.rglob("*"):
                    if f.is_file():
                        deleted_local_count += 1
                shutil.rmtree(local_dir, ignore_errors=True)
            elif local_dir.is_file():
                deleted_local_count += 1
                local_dir.unlink()
            logger.info(f"Purged local mirror directory '{local_dir}' ({deleted_local_count} files).")

        return max(deleted_remote_count, deleted_local_count)


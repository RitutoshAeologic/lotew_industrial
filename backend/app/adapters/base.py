"""
Base Industry Adapter Interface.
Every adapter (Telemetry, PDF, SCADA) implements this contract.
"""

from abc import ABC, abstractmethod
import hashlib
from typing import Any, Dict, Tuple

from ..models.canonical import CanonicalObservation


class BaseIndustryAdapter(ABC):
    """
    Contract for parsing multi-modal evidence into:
    1. CanonicalObservation v1 (JSON statistical summary)
    2. Raw binary bytes (for Parquet / PDF Object Storage)
    3. SHA-256 fingerprint (for forensic tamper verification)
    """

    @abstractmethod
    def extract_canonical(self, **kwargs) -> Tuple[CanonicalObservation, bytes, str, Dict[str, Any]]:
        """
        Extracts structured observation.
        Returns:
            Tuple of (CanonicalObservation, raw_bytes, raw_sha256, extra_metadata)
        """
        pass

    @staticmethod
    def calculate_sha256(data: bytes) -> str:
        """Calculates deterministic SHA-256 hex digest of raw binary bytes."""
        return hashlib.sha256(data).hexdigest()


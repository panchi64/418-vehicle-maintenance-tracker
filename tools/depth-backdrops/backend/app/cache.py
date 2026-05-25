"""SHA256-keyed depth map cache on disk."""
from __future__ import annotations

import hashlib
import os
import re
import tempfile
from pathlib import Path

CACHE_DIR = Path(__file__).resolve().parent.parent / ".cache"
SHA_RE = re.compile(r"[0-9a-f]{64}")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def is_valid_sha(sha: str) -> bool:
    return bool(SHA_RE.fullmatch(sha))


def cache_path(sha: str) -> Path:
    if not is_valid_sha(sha):
        raise ValueError(f"Invalid sha: {sha!r}")
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    return CACHE_DIR / f"{sha}.png"


def has(sha: str) -> bool:
    try:
        return cache_path(sha).exists()
    except ValueError:
        return False


def get(sha: str) -> bytes | None:
    try:
        p = cache_path(sha)
    except ValueError:
        return None
    if p.exists():
        return p.read_bytes()
    return None


def put(sha: str, data: bytes) -> None:
    """Write atomically — partial writes never become live cache entries."""
    p = cache_path(sha)
    fd, tmp_path = tempfile.mkstemp(prefix=f".{sha}.", suffix=".png.tmp", dir=str(CACHE_DIR))
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp_path, p)
    except Exception:
        try:
            os.unlink(tmp_path)
        except FileNotFoundError:
            pass
        raise


def evict(sha: str) -> None:
    try:
        p = cache_path(sha)
    except ValueError:
        return
    if p.exists():
        p.unlink()

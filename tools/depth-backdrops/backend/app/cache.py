"""SHA256-keyed depth map cache on disk, namespaced by model slug."""
from __future__ import annotations

import hashlib
import os
import re
import tempfile
from pathlib import Path

CACHE_DIR = Path(__file__).resolve().parent.parent / ".cache"
SHA_RE = re.compile(r"[0-9a-f]{64}")
SLUG_RE = re.compile(r"[a-z0-9][a-z0-9\-]{0,63}")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def is_valid_sha(sha: str) -> bool:
    return bool(SHA_RE.fullmatch(sha))


def _is_valid_slug(slug: str) -> bool:
    return bool(SLUG_RE.fullmatch(slug))


def cache_path(sha: str, model_slug: str) -> Path:
    if not is_valid_sha(sha):
        raise ValueError(f"Invalid sha: {sha!r}")
    if not _is_valid_slug(model_slug):
        raise ValueError(f"Invalid model slug: {model_slug!r}")
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    return CACHE_DIR / f"{model_slug}__{sha}.png"


def has(sha: str, model_slug: str) -> bool:
    try:
        return cache_path(sha, model_slug).exists()
    except ValueError:
        return False


def get(sha: str, model_slug: str) -> bytes | None:
    try:
        p = cache_path(sha, model_slug)
    except ValueError:
        return None
    if p.exists():
        return p.read_bytes()
    return None


def put(sha: str, data: bytes, model_slug: str) -> None:
    """Write atomically — partial writes never become live cache entries."""
    p = cache_path(sha, model_slug)
    fd, tmp_path = tempfile.mkstemp(prefix=f".{model_slug}__{sha}.", suffix=".png.tmp", dir=str(CACHE_DIR))
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


def evict_all(sha: str) -> None:
    """Remove this source's cached depth for every model variant."""
    if not is_valid_sha(sha):
        return
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    for p in CACHE_DIR.glob(f"*__{sha}.png"):
        try:
            p.unlink()
        except FileNotFoundError:
            pass

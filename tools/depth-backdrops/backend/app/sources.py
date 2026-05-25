"""On-disk source image registry."""
from __future__ import annotations

import io
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

from .cache import is_valid_sha

SOURCES_DIR = Path(__file__).resolve().parent.parent.parent / "sources"
THUMB_DIR = Path(__file__).resolve().parent.parent / ".cache" / "thumbs"
THUMB_MAX = 256
ALLOWED_EXT = {".jpg", ".jpeg", ".png", ".webp"}


@dataclass(frozen=True)
class Source:
    sha: str
    filename: str  # on-disk name (`<sha><ext>`)
    original_filename: str  # user's original upload name
    width: int
    height: int
    bytes: int

    def to_dict(self) -> dict:
        return {
            "sha": self.sha,
            "filename": self.filename,
            "originalFilename": self.original_filename,
            "width": self.width,
            "height": self.height,
            "bytes": self.bytes,
        }


def _name_sidecar(sha: str) -> Path:
    return SOURCES_DIR / f"{sha}.name"


def _read_original_name(sha: str, fallback: str) -> str:
    sidecar = _name_sidecar(sha)
    if sidecar.exists():
        name = sidecar.read_text(encoding="utf-8").strip()
        if name:
            return name
    return fallback


def _measure(path: Path) -> tuple[int, int]:
    with Image.open(path) as im:
        return im.size


def list_sources() -> list[Source]:
    SOURCES_DIR.mkdir(parents=True, exist_ok=True)
    out: list[Source] = []
    for p in sorted(SOURCES_DIR.iterdir()):
        if p.suffix.lower() not in ALLOWED_EXT or not p.is_file():
            continue
        sha = p.stem
        if not is_valid_sha(sha):
            continue
        w, h = _measure(p)
        out.append(
            Source(
                sha=sha,
                filename=p.name,
                original_filename=_read_original_name(sha, p.name),
                width=w,
                height=h,
                bytes=p.stat().st_size,
            )
        )
    return out


def get_path(sha: str) -> Path | None:
    if not is_valid_sha(sha):
        return None
    SOURCES_DIR.mkdir(parents=True, exist_ok=True)
    for ext in ALLOWED_EXT:
        p = SOURCES_DIR / f"{sha}{ext}"
        if p.exists():
            return p
    return None


def save(data: bytes, original_name: str, sha: str) -> Source:
    if not is_valid_sha(sha):
        raise ValueError(f"Invalid sha: {sha!r}")
    SOURCES_DIR.mkdir(parents=True, exist_ok=True)
    ext = Path(original_name).suffix.lower()
    if ext not in ALLOWED_EXT:
        raise ValueError(f"Unsupported extension: {ext}")
    path = SOURCES_DIR / f"{sha}{ext}"
    if not path.exists():
        path.write_bytes(data)
    # always refresh sidecar — the most recent upload's name wins
    safe_name = Path(original_name).name  # strip any directory components
    _name_sidecar(sha).write_text(safe_name, encoding="utf-8")
    w, h = _measure(path)
    return Source(
        sha=sha,
        filename=path.name,
        original_filename=safe_name,
        width=w,
        height=h,
        bytes=path.stat().st_size,
    )


def delete(sha: str) -> bool:
    p = get_path(sha)
    if p is None:
        return False
    try:
        p.unlink()
    except FileNotFoundError:
        return False
    sidecar = _name_sidecar(sha)
    if sidecar.exists():
        try:
            sidecar.unlink()
        except FileNotFoundError:
            pass
    thumb = THUMB_DIR / f"{sha}.jpg"
    if thumb.exists():
        try:
            thumb.unlink()
        except FileNotFoundError:
            pass
    return True


def thumbnail_bytes(sha: str) -> bytes | None:
    if not is_valid_sha(sha):
        return None
    THUMB_DIR.mkdir(parents=True, exist_ok=True)
    thumb_path = THUMB_DIR / f"{sha}.jpg"
    if thumb_path.exists():
        return thumb_path.read_bytes()

    src = get_path(sha)
    if src is None:
        return None

    with Image.open(src) as im:
        im = im.convert("RGB")
        im.thumbnail((THUMB_MAX, THUMB_MAX), Image.Resampling.LANCZOS)
        buf = io.BytesIO()
        im.save(buf, format="JPEG", quality=82)
        data = buf.getvalue()
    thumb_path.write_bytes(data)
    return data

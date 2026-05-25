"""FastAPI app for depth backdrop generation."""
from __future__ import annotations

import base64
import re
from pathlib import Path

from fastapi import FastAPI, HTTPException, Response, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from pydantic import BaseModel, Field

from . import cache, presets, sources
from .depth import current_model_slug, encode_depth_png, get_model

OUT_DIR = Path(__file__).resolve().parent.parent.parent / "out"

# 100 MB cap — Forza screenshots are typically <10 MB; this leaves headroom for 8K PNGs.
MAX_UPLOAD_BYTES = 100 * 1024 * 1024

# Recognised image extensions and their canonical MIME types.
MIME_BY_EXT = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
}

SHA_RE = re.compile(r"[0-9a-f]{64}")

app = FastAPI(title="Depth Backdrops", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def _require_sha(sha: str) -> str:
    if not SHA_RE.fullmatch(sha):
        raise HTTPException(400, "Invalid sha (expected 64 lowercase hex chars).")
    return sha


# ---------------------------------------------------------------------------
# Pydantic models — mirror the frontend's zod schema in
# frontend/src/presets/schema.ts. Keep both in sync.
# ---------------------------------------------------------------------------


HEX_COLOR = r"^#[0-9A-Fa-f]{6}$"
PRESET_NAME = r"^[a-z0-9][a-z0-9\-_]{0,63}$"


class DepthParams(BaseModel):
    inMin: float = Field(ge=0, le=1)
    inMax: float = Field(ge=0, le=1)
    gamma: float = Field(ge=0.1, le=5)
    contrast: float = Field(ge=0, le=4)
    invert: bool


class GridParams(BaseModel):
    size: int = Field(ge=1, le=256)
    gap: int = Field(default=0, ge=0, le=256)


class ColorParams(BaseModel):
    near: str = Field(pattern=HEX_COLOR)
    far: str = Field(pattern=HEX_COLOR)
    valueRange: tuple[float, float]


class Params(BaseModel):
    depth: DepthParams
    grid: GridParams
    color: ColorParams

    model_config = {"extra": "ignore"}  # tolerate older presets that still ship frame/output


class PresetSourceRef(BaseModel):
    filename: str
    sha256: str = Field(min_length=64, max_length=64, pattern=r"^[0-9a-f]{64}$")


class ModelRef(BaseModel):
    id: str
    version: str


class Preset(BaseModel):
    version: int = Field(ge=1, le=1)
    name: str = Field(pattern=PRESET_NAME)
    source: PresetSourceRef | None = None
    model: ModelRef
    params: Params


class ExportRequest(BaseModel):
    preset: str = Field(pattern=PRESET_NAME)
    sha: str = Field(min_length=64, max_length=64, pattern=r"^[0-9a-f]{64}$")
    png_base64: str


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@app.get("/healthz")
def healthz() -> dict:
    return {"ok": True}


@app.get("/sources")
def list_sources() -> dict:
    return {"sources": [s.to_dict() for s in sources.list_sources()]}


@app.post("/sources", status_code=201)
async def upload_source(file: UploadFile) -> dict:
    # Stream in chunks so we can abort before exhausting RAM.
    chunks: list[bytes] = []
    total = 0
    chunk_size = 1024 * 1024
    while True:
        chunk = await file.read(chunk_size)
        if not chunk:
            break
        total += len(chunk)
        if total > MAX_UPLOAD_BYTES:
            raise HTTPException(
                413, f"Upload too large (max {MAX_UPLOAD_BYTES // (1024 * 1024)} MB)."
            )
        chunks.append(chunk)
    data = b"".join(chunks)
    if not data:
        raise HTTPException(400, "Empty upload.")
    sha = cache.sha256_bytes(data)
    try:
        src = sources.save(data, file.filename or "upload.bin", sha)
    except ValueError as e:
        raise HTTPException(400, str(e))
    return src.to_dict()


@app.delete("/sources/{sha}", status_code=204)
def delete_source(sha: str) -> Response:
    _require_sha(sha)
    if not sources.delete(sha):
        raise HTTPException(404, "Source not found.")
    cache.evict_all(sha)
    return Response(status_code=204)


@app.get("/sources/{sha}/thumb")
def source_thumb(sha: str) -> Response:
    _require_sha(sha)
    data = sources.thumbnail_bytes(sha)
    if data is None:
        raise HTTPException(404, "Source not found.")
    return Response(content=data, media_type="image/jpeg")


@app.get("/sources/{sha}/image")
def source_image(sha: str) -> Response:
    _require_sha(sha)
    p = sources.get_path(sha)
    if p is None:
        raise HTTPException(404, "Source not found.")
    media = MIME_BY_EXT.get(p.suffix.lower(), "application/octet-stream")
    try:
        body = p.read_bytes()
    except FileNotFoundError:
        raise HTTPException(404, "Source not found.")
    return Response(content=body, media_type=media)


@app.get("/depth")
def depth_map(sha: str) -> Response:
    _require_sha(sha)
    slug = current_model_slug()
    hit = cache.get(sha, slug)
    if hit is not None:
        return Response(content=hit, media_type="image/png")

    src_path = sources.get_path(sha)
    if src_path is None:
        raise HTTPException(404, "Source not found.")

    try:
        with Image.open(src_path) as im:
            depth = get_model().predict(im)
    except FileNotFoundError:
        raise HTTPException(404, "Source not found.")
    png = encode_depth_png(depth)
    cache.put(sha, png, slug)
    return Response(content=png, media_type="image/png")


@app.get("/presets")
def list_presets() -> dict:
    out = []
    for name in presets.list_names():
        try:
            out.append(presets.read(name))
        except Exception:
            continue
    return {"presets": out}


@app.get("/presets/{name}")
def get_preset(name: str) -> dict:
    try:
        return presets.read(name)
    except FileNotFoundError:
        raise HTTPException(404, f"Preset {name!r} not found.")
    except ValueError as e:
        raise HTTPException(400, str(e))


@app.put("/presets/{name}")
def put_preset(name: str, body: Preset) -> dict:
    if body.name != name:
        raise HTTPException(400, "Preset body name must match URL.")
    try:
        presets.write(name, body.model_dump(mode="json", exclude_none=True))
    except ValueError as e:
        raise HTTPException(400, str(e))
    return {"ok": True}


@app.delete("/presets/{name}", status_code=204)
def delete_preset(name: str) -> Response:
    try:
        ok = presets.delete(name)
    except ValueError as e:
        raise HTTPException(400, str(e))
    if not ok:
        raise HTTPException(404, f"Preset {name!r} not found.")
    return Response(status_code=204)


@app.post("/export")
def export(body: ExportRequest) -> dict:
    """Persist a rendered PNG produced by the frontend."""
    target_dir = OUT_DIR / body.preset
    target_dir.mkdir(parents=True, exist_ok=True)
    target = target_dir / f"{body.sha}.png"
    try:
        target.write_bytes(base64.b64decode(body.png_base64, validate=True))
    except Exception as e:
        raise HTTPException(400, f"Bad PNG payload: {e}")
    return {"path": str(target)}

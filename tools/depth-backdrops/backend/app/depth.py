"""Core ML inference for monocular depth on Apple Silicon."""
from __future__ import annotations

import os
import re
import threading
from pathlib import Path

import coremltools as ct
import numpy as np
from PIL import Image


MODEL_DIR = Path(__file__).resolve().parent.parent / "models"
DEFAULT_MODEL_FILENAME = "DepthPro.mlpackage"


def _slugify(s: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-") or "model"


class DepthModel:
    """Wraps a Core ML depth model. Loads once, runs many.

    Supports both single-input models (Depth Anything V2: just an image) and
    two-input models (Depth Pro: image + originalWidth scalar). Inputs are
    introspected from the model spec at load time.
    """

    def __init__(self, model_path: Path) -> None:
        if not model_path.exists():
            raise FileNotFoundError(
                f"Core ML model not found at {model_path}. "
                "Run scripts/download_model.py first."
            )

        self._model = ct.models.MLModel(
            str(model_path),
            compute_units=ct.ComputeUnit.CPU_AND_NE,
        )
        self.slug = _slugify(model_path.stem)

        spec = self._model.get_spec()
        image_inputs = [i for i in spec.description.input if i.type.HasField("imageType")]
        if not image_inputs:
            raise ValueError(f"{model_path.name}: no image input found in spec.")
        img = image_inputs[0]
        self._image_input_name = img.name
        self._input_size = (int(img.type.imageType.width), int(img.type.imageType.height))

        # Non-image inputs (e.g. Depth Pro's `originalWidth` scalar). Capture each
        # one's required shape so we can pass a correctly-ranked ndarray —
        # Depth Pro insists on rank 4.
        self._scalar_inputs: list[tuple[str, tuple[int, ...]]] = []
        for i in spec.description.input:
            if i.type.HasField("imageType"):
                continue
            shape: tuple[int, ...]
            if i.type.HasField("multiArrayType"):
                raw_shape = tuple(int(d) for d in i.type.multiArrayType.shape)
                shape = raw_shape or (1,)
            else:
                shape = (1,)
            self._scalar_inputs.append((i.name, shape))
        self._output_name = spec.description.output[0].name

    @property
    def input_size(self) -> tuple[int, int]:
        return self._input_size

    def predict(self, image: Image.Image) -> np.ndarray:
        """Return an 8-bit depth map at the source image's resolution.

        Model is run at its native fixed input size, then resized back to the
        source's dimensions. 8-bit is sufficient because the frontend pixel-grid
        quantization discards any finer precision.
        """
        src_w, src_h = image.size
        rgb = image.convert("RGB").resize(self._input_size, Image.Resampling.LANCZOS)

        inputs: dict[str, object] = {self._image_input_name: rgb}
        for name, shape in self._scalar_inputs:
            # Depth Pro asks for `originalWidth` so it can estimate focal length.
            # Unknown scalars fall back to 0.
            if "width" in name.lower():
                value = float(src_w)
            elif "height" in name.lower():
                value = float(src_h)
            else:
                value = 0.0
            inputs[name] = np.full(shape, value, dtype=np.float32)

        out = self._model.predict(inputs)
        depth_arr = np.asarray(out[self._output_name], dtype=np.float32).squeeze()
        depth_arr = _equalize(depth_arr)

        resized = Image.fromarray(
            (depth_arr * 255.0).astype(np.uint8), mode="L"
        ).resize((src_w, src_h), Image.Resampling.BILINEAR)
        return np.asarray(resized, dtype=np.uint8)


def _equalize(depth_arr: np.ndarray) -> np.ndarray:
    """Histogram-equalize depth into [0, 1].

    DepthPro outputs inverse depth; a sky-and-foreground scene spans
    several orders of magnitude, so linear min/max (or percentile) clipping
    either crushes the sky or saturates the foreground. Rank-based
    equalization gives every brightness equal pixel count, so the sky,
    mid-ground, and foreground each get their own readable band of values.
    """
    depth_arr = np.nan_to_num(depth_arr, nan=0.0, posinf=0.0, neginf=0.0)
    flat = depth_arr.ravel()
    sorted_vals = np.sort(flat)
    # `searchsorted(..., side='right')` gives 1..N (the count of values <=
    # each element) — exactly the rank we want, before scaling to [0, 1].
    ranks = np.searchsorted(sorted_vals, flat, side="right").astype(np.float32)
    ranks /= float(len(flat))
    return ranks.reshape(depth_arr.shape)


_singleton: DepthModel | None = None
_singleton_lock = threading.Lock()


def _resolve_model_path() -> Path:
    return MODEL_DIR / os.environ.get("DEPTH_MODEL", DEFAULT_MODEL_FILENAME)


def current_model_slug() -> str:
    """The slug used to namespace cache entries by model."""
    return _slugify(_resolve_model_path().stem)


def get_model() -> DepthModel:
    global _singleton
    if _singleton is None:
        with _singleton_lock:
            if _singleton is None:
                _singleton = DepthModel(_resolve_model_path())
    return _singleton


def encode_depth_png(depth_u8: np.ndarray) -> bytes:
    """8-bit grayscale PNG bytes."""
    import io

    buf = io.BytesIO()
    Image.fromarray(depth_u8, mode="L").save(buf, format="PNG", optimize=False)
    return buf.getvalue()

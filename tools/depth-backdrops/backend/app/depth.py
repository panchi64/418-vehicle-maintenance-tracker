"""Core ML inference for Depth Anything V2 on Apple Silicon."""
from __future__ import annotations

import os
import threading
from pathlib import Path

import coremltools as ct
import numpy as np
from PIL import Image


MODEL_DIR = Path(__file__).resolve().parent.parent / "models"
DEFAULT_MODEL_FILENAME = "DepthAnythingV2SmallF16.mlpackage"


class DepthModel:
    """Wraps a Core ML depth model. Loads once, runs many."""

    def __init__(self, model_path: Path) -> None:
        if not model_path.exists():
            raise FileNotFoundError(
                f"Core ML model not found at {model_path}. "
                "Run scripts/download_model.sh first."
            )

        self._model = ct.models.MLModel(
            str(model_path),
            compute_units=ct.ComputeUnit.CPU_AND_NE,
        )

        spec = self._model.get_spec()
        self._input_name = spec.description.input[0].name
        self._output_name = spec.description.output[0].name

        image_input = spec.description.input[0].type.imageType
        self._input_size = (int(image_input.width), int(image_input.height))

    @property
    def input_size(self) -> tuple[int, int]:
        return self._input_size

    def predict(self, image: Image.Image) -> np.ndarray:
        """Return an 8-bit depth map at the source image's resolution.

        The model is run at its native fixed input size; the result is resized back
        to the source image's dimensions with bilinear interpolation so downstream
        pixel grids land on coherent terrain features. 8-bit is sufficient because
        the frontend's pixel-grid quantization discards finer precision anyway.
        """
        src_w, src_h = image.size
        rgb = image.convert("RGB").resize(self._input_size, Image.Resampling.LANCZOS)

        out = self._model.predict({self._input_name: rgb})
        depth = out[self._output_name]
        depth_arr = np.asarray(depth, dtype=np.float32).squeeze()

        dmin, dmax = float(depth_arr.min()), float(depth_arr.max())
        if dmax > dmin:
            depth_arr = (depth_arr - dmin) / (dmax - dmin)
        else:
            depth_arr = np.zeros_like(depth_arr)

        resized = Image.fromarray(
            (depth_arr * 255.0).astype(np.uint8), mode="L"
        ).resize((src_w, src_h), Image.Resampling.BILINEAR)
        return np.asarray(resized, dtype=np.uint8)


_singleton: DepthModel | None = None
_singleton_lock = threading.Lock()


def get_model() -> DepthModel:
    global _singleton
    if _singleton is None:
        with _singleton_lock:
            if _singleton is None:
                filename = os.environ.get("DEPTH_MODEL", DEFAULT_MODEL_FILENAME)
                _singleton = DepthModel(MODEL_DIR / filename)
    return _singleton


def encode_depth_png(depth_u8: np.ndarray) -> bytes:
    """8-bit grayscale PNG bytes."""
    import io

    buf = io.BytesIO()
    Image.fromarray(depth_u8, mode="L").save(buf, format="PNG", optimize=False)
    return buf.getvalue()

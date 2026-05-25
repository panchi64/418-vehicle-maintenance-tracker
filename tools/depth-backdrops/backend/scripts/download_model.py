"""Download a Core ML depth model from HuggingFace.

Defaults to Apple's DepthPro (~1.9 GB) — the sharpest monocular depth model
available for Apple Silicon. Override with --model to fetch a different one.

Usage:
    uv run python -m scripts.download_model               # DepthPro (default)
    uv run python -m scripts.download_model --model da-v2 # Depth Anything V2 Small
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from huggingface_hub import snapshot_download

TARGET = Path(__file__).resolve().parent.parent / "models"

REGISTRY: dict[str, dict[str, str | list[str]]] = {
    "depth-pro": {
        "repo": "coreml-projects/DepthPro-coreml",
        "patterns": ["DepthPro.mlpackage/**"],
        "size": "~1.9 GB",
    },
    "da-v2": {
        "repo": "apple/coreml-depth-anything-v2-small",
        "patterns": ["DepthAnythingV2SmallF16.mlpackage/**"],
        "size": "~25 MB",
    },
}


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--model",
        choices=sorted(REGISTRY),
        default="depth-pro",
        help="Which model to fetch.",
    )
    args = p.parse_args()
    spec = REGISTRY[args.model]
    TARGET.mkdir(parents=True, exist_ok=True)
    print(f"Downloading {args.model} ({spec['size']}) from {spec['repo']} → {TARGET}")
    snapshot_download(
        repo_id=str(spec["repo"]),
        local_dir=str(TARGET),
        allow_patterns=spec["patterns"],  # type: ignore[arg-type]
    )
    pkgs = sorted(TARGET.glob("*.mlpackage"))
    if not pkgs:
        print("ERROR: no .mlpackage downloaded.", file=sys.stderr)
        return 1
    print("Available models in", TARGET, ":", ", ".join(p.name for p in pkgs))
    return 0


if __name__ == "__main__":
    sys.exit(main())

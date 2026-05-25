"""Download Apple's Depth Anything V2 Small Core ML model from HuggingFace.

Usage: uv run python -m scripts.download_model
"""
from __future__ import annotations

import sys
from pathlib import Path

from huggingface_hub import snapshot_download

REPO = "apple/coreml-depth-anything-v2-small"
TARGET = Path(__file__).resolve().parent.parent / "models"


def main() -> int:
    TARGET.mkdir(parents=True, exist_ok=True)
    print(f"Downloading {REPO} → {TARGET}")
    snapshot_download(
        repo_id=REPO,
        local_dir=str(TARGET),
        allow_patterns=["*.mlpackage/**", "*.mlpackage"],
    )
    pkgs = list(TARGET.glob("*.mlpackage"))
    if not pkgs:
        print("ERROR: no .mlpackage downloaded.", file=sys.stderr)
        return 1
    print(f"Ready: {pkgs[0].name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

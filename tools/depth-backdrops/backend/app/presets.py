"""Preset JSON CRUD."""
from __future__ import annotations

import json
import re
from pathlib import Path

PRESETS_DIR = Path(__file__).resolve().parent.parent.parent / "presets"
NAME_RE = re.compile(r"^[a-z0-9][a-z0-9\-_]{0,63}$")


def _path(name: str) -> Path:
    if not NAME_RE.match(name):
        raise ValueError(
            f"Invalid preset name: {name!r}. Use lowercase letters, digits, hyphens, underscores."
        )
    PRESETS_DIR.mkdir(parents=True, exist_ok=True)
    return PRESETS_DIR / f"{name}.json"


def list_names() -> list[str]:
    PRESETS_DIR.mkdir(parents=True, exist_ok=True)
    return sorted(p.stem for p in PRESETS_DIR.glob("*.json"))


def read(name: str) -> dict:
    p = _path(name)
    if not p.exists():
        raise FileNotFoundError(name)
    return json.loads(p.read_text())


def write(name: str, data: dict) -> None:
    p = _path(name)
    p.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def delete(name: str) -> bool:
    p = _path(name)
    if not p.exists():
        return False
    p.unlink()
    return True

#!/usr/bin/env python3
"""Regenerates Biombo's colour sets from scripts/palette.json.

Every palette role becomes one colour set in BiomboShared/Palette.xcassets/
(compiled into the app and the widget extension) with four appearances:
Any (light), Dark, High Contrast and Dark + High Contrast. The app's
AccentColor is written from the `tint` role. Colour sets no longer in the
palette are removed.

  python3 apps/biombo/ios/scripts/generate_palette.py
  python3 apps/biombo/ios/scripts/generate_palette.py --import-tokens path/to/tokens.json

--import-tokens first rewrites palette.json from a design-tokens export
(`color.tokens[]` with light / dark / light-hc / dark-hc values, where a value
may alias another role as "{name}"). Stdlib only.
"""

import argparse
import json
import re
import shutil
from pathlib import Path

HERE = Path(__file__).resolve().parent
PALETTE = HERE / "palette.json"
CATALOG = HERE.parent / "Biombo" / "Resources" / "Assets.xcassets"
PALETTE_CATALOG = HERE.parent / "BiomboShared" / "Palette.xcassets"
MODES = ("light", "dark", "light-hc", "dark-hc")
APPEARANCES = {
    "light": [],
    "dark": [{"appearance": "luminosity", "value": "dark"}],
    "light-hc": [{"appearance": "contrast", "value": "high"}],
    "dark-hc": [
        {"appearance": "luminosity", "value": "dark"},
        {"appearance": "contrast", "value": "high"},
    ],
}
ALIAS = re.compile(r"^\{([a-z0-9-]+)\}$")


def import_tokens(tokens_path: Path) -> dict:
    tokens = {t["name"]: t["value"] for t in json.loads(tokens_path.read_text())["color"]["tokens"]}

    def resolve(value, mode, depth=0):
        if depth > 8:
            raise ValueError(f"alias loop at {value}")
        if isinstance(value, dict):
            return resolve(value[mode], mode, depth + 1)
        match = ALIAS.match(value)
        return resolve(tokens[match.group(1)], mode, depth + 1) if match else value

    return {name: {mode: resolve(value, mode) for mode in MODES} for name, value in tokens.items()}


def components(css: str) -> dict:
    css = css.strip().lower()
    if css.startswith("#"):
        hexes = css[1:]
        r, g, b = (int(hexes[i : i + 2], 16) for i in (0, 2, 4))
        alpha = 1.0
    else:
        match = re.match(r"rgba?\(([^)]+)\)", css)
        if not match:
            raise ValueError(f"unsupported colour {css}")
        parts = [p.strip() for p in match.group(1).split(",")]
        r, g, b = (int(p) for p in parts[:3])
        alpha = float(parts[3]) if len(parts) == 4 else 1.0
    return {
        "red": f"0x{r:02X}",
        "green": f"0x{g:02X}",
        "blue": f"0x{b:02X}",
        "alpha": f"{alpha:.3f}",
    }


def colorset(values: dict) -> dict:
    colors = []
    for mode in MODES:
        entry = {"color": {"color-space": "srgb", "components": components(values[mode])}, "idiom": "universal"}
        if APPEARANCES[mode]:
            entry["appearances"] = APPEARANCES[mode]
        colors.append(entry)
    return {"colors": colors, "info": {"author": "xcode", "version": 1}}


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--import-tokens", type=Path, help="design-tokens JSON to import into palette.json first")
    args = parser.parse_args()

    if args.import_tokens:
        write_json(PALETTE, import_tokens(args.import_tokens))

    palette = json.loads(PALETTE.read_text())
    folder = PALETTE_CATALOG
    if folder.exists():
        for stale in folder.glob("*.colorset"):
            if stale.stem not in palette:
                shutil.rmtree(stale)
    write_json(folder / "Contents.json", {"info": {"author": "xcode", "version": 1}})
    for name, values in palette.items():
        write_json(folder / f"{name}.colorset" / "Contents.json", colorset(values))
    write_json(CATALOG / "AccentColor.colorset" / "Contents.json", colorset(palette["tint"]))
    print(f"Wrote {len(palette)} colour sets + AccentColor to {folder.relative_to(HERE.parent)}")


if __name__ == "__main__":
    main()

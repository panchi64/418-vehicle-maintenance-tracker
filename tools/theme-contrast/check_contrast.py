# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Contrast gate for Checkpoint's Themes.json.

Every theme ships four color sets — light, dark, and an Increase Contrast
variant of each. This checks every theme x variant against WCAG 2.x contrast
ratios and exits non-zero if anything fails.

    uv run tools/theme-contrast/check_contrast.py            # table + exit code
    uv run tools/theme-contrast/check_contrast.py --verbose  # also list each failure

Colors with alpha are composited before measuring: foreground tokens over the
ground they sit on, `surfaceInstrument` (the card fill) over `backgroundPrimary`.
Each ratio is the *minimum* across the four grounds a token can land on —
backgroundPrimary, backgroundElevated, backgroundSubtle, and a card.

Thresholds (normal / high contrast):
    textPrimary                   >= 7    / >= 7
    textSecondary, textTertiary   >= 4.5  / >= 7
    status colors                 >= 3    / >= 4.5
    accent                        >= 3    / >= 4.5
    label on accent (primary btn) >= 4.5  / >= 7    (surfaceInstrument over accent)
    gridLine (card borders)          -    / >= 3
    status separation (OKLab dE)  >= 0.08 / >= 0.08 (min pairwise, on backgroundPrimary)
and every high-contrast ratio must be >= the same ratio in its base variant.
"""

from __future__ import annotations

import argparse
import itertools
import json
import math
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
THEMES = REPO / "apps/checkpoint/ios/checkpoint/Resources/Themes.json"

TOKENS = [
    "backgroundPrimary", "backgroundElevated", "backgroundSubtle", "surfaceInstrument",
    "glow", "gridLine", "textPrimary", "textSecondary", "textTertiary", "borderSubtle",
    "accent", "accentMuted", "statusOverdue", "statusDueSoon", "statusGood", "statusNeutral",
]
STATUS = ["statusOverdue", "statusDueSoon", "statusGood", "statusNeutral"]
BASE_VARIANTS = ["light", "dark"]
HC_OF = {"lightHighContrast": "light", "darkHighContrast": "dark"}
VARIANTS = ["light", "lightHighContrast", "dark", "darkHighContrast"]

RGBA = tuple[float, float, float, float]


def parse(hex_: str) -> RGBA:
    h = hex_.lstrip("#")
    if len(h) not in (6, 8):
        raise ValueError(f"bad hex {hex_!r}")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    a = int(h[6:8], 16) / 255 if len(h) == 8 else 1.0
    return (r, g, b, a)


def over(fg: RGBA, bg: RGBA) -> RGBA:
    """Source-over composite onto an opaque ground."""
    a = fg[3]
    return (fg[0] * a + bg[0] * (1 - a), fg[1] * a + bg[1] * (1 - a), fg[2] * a + bg[2] * (1 - a), 1.0)


def _lin(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def luminance(c: RGBA) -> float:
    return 0.2126 * _lin(c[0]) + 0.7152 * _lin(c[1]) + 0.0722 * _lin(c[2])


def ratio(a: RGBA, b: RGBA) -> float:
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def oklab(c: RGBA) -> tuple[float, float, float]:
    r, g, b = (_lin(x) for x in c[:3])
    l_ = math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
    m_ = math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
    s_ = math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
    return (
        0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
    )


def resolve(theme: dict) -> dict[str, dict[str, str]]:
    """Mirror of ThemeAppearances' decode: bases are complete, HC sets are overrides."""
    colors = theme["colors"]
    out: dict[str, dict[str, str]] = {}
    for base in BASE_VARIANTS:
        missing = [t for t in TOKENS if t not in colors[base]]
        if missing:
            raise SystemExit(f"{theme['id']}.{base} is missing {missing}")
        out[base] = dict(colors[base])
    for hc, base in HC_OF.items():
        overrides = colors.get(hc, {})
        unknown = [k for k in overrides if k not in TOKENS]
        if unknown:
            raise SystemExit(f"{theme['id']}.{hc} has unknown tokens {unknown}")
        out[hc] = {**out[base], **overrides}
    for variant, tokens in out.items():
        unknown = [k for k in tokens if k not in TOKENS]
        if unknown:
            raise SystemExit(f"{theme['id']}.{variant} has unknown tokens {unknown}")
    return out


def measure(tokens: dict[str, str]) -> dict[str, float]:
    c = {k: parse(v) for k, v in tokens.items()}
    primary = over(c["backgroundPrimary"], (1, 1, 1, 1))
    grounds = [
        primary,
        over(c["backgroundElevated"], primary),
        over(c["backgroundSubtle"], primary),
        over(c["surfaceInstrument"], primary),
    ]

    def worst(token: str) -> float:
        return min(ratio(over(c[token], g), g) for g in grounds)

    accent = over(c["accent"], primary)
    label = over(over(c["surfaceInstrument"], primary), accent)
    labs = [oklab(over(c[s], primary)) for s in STATUS]
    separation = min(math.dist(a, b) for a, b in itertools.combinations(labs, 2))
    return {
        "textPrimary": worst("textPrimary"),
        "textSecondary": worst("textSecondary"),
        "textTertiary": worst("textTertiary"),
        "status": min(worst(s) for s in STATUS),
        "accent": worst("accent"),
        "onAccent": ratio(label, accent),
        "gridLine": worst("gridLine"),
        "separation": separation,
    }


# (normal, high contrast); None = reported, not gated.
THRESHOLDS: dict[str, tuple[float | None, float | None]] = {
    "textPrimary": (7.0, 7.0),
    "textSecondary": (4.5, 7.0),
    "textTertiary": (4.5, 7.0),
    "status": (3.0, 4.5),
    "accent": (3.0, 4.5),
    "onAccent": (4.5, 7.0),
    "gridLine": (None, 3.0),
    "separation": (0.08, 0.08),
}
# Measures that must not get worse under Increase Contrast.
MONOTONIC = ["textPrimary", "textSecondary", "textTertiary", "status", "accent", "onAccent", "gridLine"]
COLUMNS = [
    ("textPrimary", "text1"), ("textSecondary", "text2"), ("textTertiary", "text3"),
    ("status", "status"), ("accent", "accent"), ("onAccent", "onAcc"),
    ("gridLine", "grid"), ("separation", "statusΔE"),
]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--verbose", action="store_true")
    parser.add_argument("--themes", type=Path, default=THEMES)
    args = parser.parse_args()

    themes = json.loads(args.themes.read_text())
    failures: list[str] = []
    header = "| theme | variant | " + " | ".join(label for _, label in COLUMNS) + " | result |"
    rows = [header, "|" + "---|" * (len(COLUMNS) + 3)]

    for theme in themes:
        resolved = resolve(theme)
        measured = {v: measure(resolved[v]) for v in VARIANTS}
        for variant in VARIANTS:
            m = measured[variant]
            hc = variant in HC_OF
            row_fail: list[str] = []
            for key, (normal, high) in THRESHOLDS.items():
                limit = high if hc else normal
                if limit is not None and m[key] < limit:
                    row_fail.append(f"{key} {m[key]:.2f} < {limit}")
            if hc:
                base = measured[HC_OF[variant]]
                for key in MONOTONIC:
                    if m[key] + 1e-6 < base[key]:
                        row_fail.append(f"{key} {m[key]:.2f} below base {base[key]:.2f}")
            cells = [f"{m[k]:.3f}" if k == "separation" else f"{m[k]:.2f}" for k, _ in COLUMNS]
            rows.append(
                f"| {theme['id']} | {variant} | " + " | ".join(cells) + f" | {'FAIL' if row_fail else 'pass'} |"
            )
            failures += [f"{theme['id']}.{variant}: {f}" for f in row_fail]

    print("\n".join(rows))
    if failures:
        print(f"\n{len(failures)} failure(s)")
        if args.verbose:
            print("\n".join(f"  {f}" for f in failures))
        return 1
    print("\nAll themes pass.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

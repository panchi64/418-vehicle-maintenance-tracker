# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Contrast gate for Checkpoint's Themes.json and Biombo's tokens.json.

Every Checkpoint theme ships four color sets — light, dark, and an Increase
Contrast variant of each. This checks every theme x variant against WCAG 2.x
contrast ratios and exits non-zero if anything fails. Biombo's gate lives in
`biombo_contrast.py` (declared pairs, see its docstring). By default both run,
but Biombo is skipped while its tokens file doesn't exist yet.

    uv run tools/theme-contrast/check_contrast.py                     # both gates + exit code
    uv run tools/theme-contrast/check_contrast.py --verbose           # also list each failure
    uv run tools/theme-contrast/check_contrast.py --target checkpoint # one gate only
    uv run tools/theme-contrast/check_contrast.py --target biombo

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

import biombo_contrast
from wcag import oklab, over, parse, ratio

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
    parser.add_argument("--themes", type=Path, default=THEMES, help="Checkpoint Themes.json")
    parser.add_argument("--tokens", type=Path, default=biombo_contrast.TOKENS, help="Biombo tokens.json")
    parser.add_argument("--pairs", type=Path, default=biombo_contrast.PAIRS, help="Biombo pair list")
    parser.add_argument("--target", choices=["all", "checkpoint", "biombo"], default="all")
    args = parser.parse_args()

    code = 0
    if args.target in ("all", "checkpoint"):
        code |= check_checkpoint(args.themes, args.verbose)
    # Biombo's palette is still being explored; `all` skips it until its tokens land in the repo.
    if args.target == "biombo" or (args.target == "all" and args.tokens.exists()):
        if args.target == "all":
            print("\n## Biombo\n")
        code |= biombo_contrast.check(args.tokens, args.pairs, args.verbose)
    return code


def check_checkpoint(path: Path, verbose: bool) -> int:
    themes = json.loads(path.read_text())
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
        if verbose:
            print("\n".join(f"  {f}" for f in failures))
        return 1
    print("\nAll themes pass.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

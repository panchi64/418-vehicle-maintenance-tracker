"""Contrast gate for Biombo's tokens.json (apps/biombo/design/).

The tokens use the Design System artifact's LIST shape: `color.themes` names the
themes in order (light, dark, light-hc, dark-hc) and each colour token carries a
value per theme, where a missing theme inherits the first and `"{name}"` aliases
another token.

What gets measured is declared in `contrast-pairs.json` beside the tokens, not
hard-coded here:

    {
      "thresholds": {"text": [4.5, 7], "mark": [3, 3], ...},   # [normal, -hc]; null = not gated
      "grounds": {"chrome": ["surface-ground", "surface-sheet over map-water"]},
      "pairs": [{"fg": ["text-primary"], "on": ["@chrome"], "kind": "text"}],
      "exempt": {"map-road-minor": "why it is never measured"}
    }

A ground is a token or an `a over b over c` chain composited right to left; the
last link must be opaque. `@name` expands a named ground set. Translucent
foregrounds are composited over each ground before measuring.

An optional `separation` block enforces "colours that must be told apart also
differ in lightness":

    "separation": {"tokens": ["layer-gas-pin", ..., "accent"], "hue_window": 30, "min_dl": [20, 10]}

Any two of those tokens whose hues sit within `hue_window` degrees of each other
must differ by at least `min_dl` CIE L* ([normal, -hc]) in every theme.

It fails when any pair misses its threshold, when a gated pair in a -hc theme
measures below the same pair in its base theme, when two separated tokens
collide, or when a colour token is neither measured nor exempted with a reason.
"""

from __future__ import annotations

import colorsys
import json
from itertools import combinations
from pathlib import Path

from wcag import RGBA, luminance, over, parse, ratio

REPO = Path(__file__).resolve().parents[2]
TOKENS = REPO / "apps/biombo/design/tokens.json"
PAIRS = REPO / "apps/biombo/design/contrast-pairs.json"
HC_SUFFIX = "-hc"


def resolve_colors(tokens: dict) -> dict[str, dict[str, str]]:
    """Every colour token's literal value in every theme, aliases followed."""
    themes = [t["id"] for t in tokens["color"]["themes"]]
    raw = {t["name"]: t["value"] for t in tokens["color"]["tokens"]}

    def lookup(name: str, theme: str, depth: int = 0) -> str:
        if depth > 16 or name not in raw:
            raise SystemExit(f"alias chain broken at {name!r} ({theme})")
        v = raw[name]
        v = v if isinstance(v, str) else v.get(theme, v.get(themes[0]))
        if v is None:
            raise SystemExit(f"{name} has no value for {theme} or {themes[0]}")
        if v.startswith("{") and v.endswith("}"):
            return lookup(v[1:-1], theme, depth + 1)
        return v

    return {theme: {name: lookup(name, theme) for name in raw} for theme in themes}


def ground(expr: str, colors: dict[str, str]) -> RGBA:
    links = [s.strip() for s in expr.split(" over ")]
    base = parse(colors[links[-1]])
    if base[3] < 1:
        raise SystemExit(f"ground {expr!r} ends on a translucent token")
    for link in reversed(links[:-1]):
        base = over(parse(colors[link]), base)
    return base


def expand(items: list[str], sets: dict[str, list[str]]) -> list[str]:
    out: list[str] = []
    for item in items:
        out += expand(sets[item[1:]], sets) if item.startswith("@") else [item]
    return out


def measure(colors: dict[str, str], spec: dict) -> list[tuple[str, str, str, float]]:
    """(kind, fg, ground, ratio) for every declared pair in one theme."""
    sets = spec.get("grounds", {})
    rows = []
    for pair in spec["pairs"]:
        for fg in expand(pair["fg"], sets):
            for g in expand(pair["on"], sets):
                bg = ground(g, colors)
                rows.append((pair["kind"], fg, g, ratio(over(parse(colors[fg]), bg), bg)))
    return rows


def lstar(c: RGBA) -> float:
    y = luminance(c)
    return 116 * y ** (1 / 3) - 16 if y > 216 / 24389 else y * 24389 / 27


def collisions(colors: dict[str, str], sep: dict, hc: bool) -> list[str]:
    """Pairs of separated tokens that share a hue neighbourhood but not a lightness gap."""
    window, min_dl = sep["hue_window"], sep["min_dl"][1 if hc else 0]
    marks = {}
    for name in sep["tokens"]:
        c = parse(colors[name])
        marks[name] = (colorsys.rgb_to_hls(*c[:3])[0] * 360, lstar(c))
    out = []
    for (a, (ha, la)), (b, (hb, lb)) in combinations(marks.items(), 2):
        dh = abs(ha - hb) % 360
        if min(dh, 360 - dh) < window and abs(la - lb) < min_dl:
            out.append(f"separation {a} (L*{la:.0f}) vs {b} (L*{lb:.0f}): {abs(la - lb):.1f} < {min_dl}")
    return out


def referenced(spec: dict) -> set[str]:
    sets = spec.get("grounds", {})
    names: set[str] = set()
    for pair in spec["pairs"]:
        names.update(expand(pair["fg"], sets))
        for g in expand(pair["on"], sets):
            names.update(s.strip() for s in g.split(" over "))
    return names


def check(tokens_path: Path, pairs_path: Path, verbose: bool) -> int:
    tokens = json.loads(tokens_path.read_text())
    spec = json.loads(pairs_path.read_text())
    resolved = resolve_colors(tokens)
    themes = list(resolved)
    thresholds = spec["thresholds"]
    failures: list[str] = []

    for theme, colors in resolved.items():
        for name, value in colors.items():
            try:
                parse(value)
            except ValueError as e:
                failures.append(f"{theme}: {name}: {e}")

    unknown = sorted(n for n in referenced(spec) | set(spec.get("exempt", {})) if n not in resolved[themes[0]])
    if unknown:
        raise SystemExit(f"contrast-pairs.json names unknown tokens: {unknown}")
    unmeasured = sorted(set(resolved[themes[0]]) - referenced(spec) - set(spec.get("exempt", {})))
    failures += [f"{n}: neither measured nor exempted" for n in unmeasured]

    measured = {theme: measure(colors, spec) for theme, colors in resolved.items()}
    rows = ["| theme | pairs | worst text | worst mark | result |", "|---|---|---|---|---|"]
    for theme in themes:
        hc = theme.endswith(HC_SUFFIX)
        base = measured.get(theme.removesuffix(HC_SUFFIX)) if hc else None
        theme_fail: list[str] = []
        for i, (kind, fg, g, r) in enumerate(measured[theme]):
            limit = thresholds[kind][1 if hc else 0]
            if limit is not None and r < limit:
                theme_fail.append(f"{kind} {fg} on {g}: {r:.2f} < {limit}")
            gated = any(t is not None for t in thresholds[kind])
            if gated and base is not None and r + 1e-6 < base[i][3]:
                theme_fail.append(f"{kind} {fg} on {g}: {r:.2f} below base {base[i][3]:.2f}")
        if "separation" in spec:
            theme_fail += collisions(resolved[theme], spec["separation"], hc)
        text = [r for k, _, _, r in measured[theme] if k.startswith("text")]
        marks = [r for k, _, _, r in measured[theme] if k == "mark"]
        rows.append(
            f"| {theme} | {len(measured[theme])} | {min(text):.2f} | {min(marks):.2f} | "
            f"{'FAIL' if theme_fail else 'pass'} |"
        )
        failures += [f"{theme}: {f}" for f in theme_fail]

    print("\n".join(rows))
    if failures:
        print(f"\n{len(failures)} failure(s)")
        if verbose:
            print("\n".join(f"  {f}" for f in failures))
        return 1
    print("\nAll Biombo pairs pass.")
    return 0

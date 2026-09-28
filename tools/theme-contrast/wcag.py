"""WCAG 2.x colour math shared by the Checkpoint and Biombo contrast gates."""

from __future__ import annotations

import math
import re

RGBA = tuple[float, float, float, float]

_FUNC = re.compile(r"^rgba?\(\s*([^)]*)\)$")


def parse(value: str) -> RGBA:
    """Parse `#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa`, `rgb()` or `rgba()`."""
    v = value.strip().lower()
    if v.startswith("#"):
        h = v[1:]
        if len(h) in (3, 4):
            h = "".join(c * 2 for c in h)
        if len(h) not in (6, 8):
            raise ValueError(f"bad hex {value!r}")
        r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
        a = int(h[6:8], 16) / 255 if len(h) == 8 else 1.0
        return (r, g, b, a)
    m = _FUNC.match(v)
    if not m:
        raise ValueError(f"unsupported colour {value!r}")
    parts = [p for p in re.split(r"[\s,/]+", m.group(1)) if p]
    if len(parts) not in (3, 4):
        raise ValueError(f"bad rgb() {value!r}")
    r, g, b = (float(p) / 255 for p in parts[:3])
    a = 1.0
    if len(parts) == 4:
        a = float(parts[3][:-1]) / 100 if parts[3].endswith("%") else float(parts[3])
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

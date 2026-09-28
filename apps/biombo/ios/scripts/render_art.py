#!/usr/bin/env python3
"""Rasterizes Biombo's art boards into asset-catalog image sets.

The postcard plates, ink vignettes and painted island are drawn as SVG with
filters (turbulence, displacement, grain) that asset catalogs cannot render,
so they ship as PNGs. This script renders each board variant in a headless
Chromium and writes the image sets under Resources/Assets.xcassets/Art:

- Postal:   plate-<motif>     light, dark, and line-only for Increase Contrast
                              (light and dark), @2x and @3x.
- Vignette: vignette-<motif>  the same four appearances, @2x and @3x.
- Island:   painted-island    light and dark, one large geo-referenced PNG with
                              feathered edges (never shown in high contrast).

The boards are `.dc.html` files from the design canvas (not in the repo). A
tiny runtime below evaluates each board's `renderVals()` and `<sc-if>` blocks,
so the output follows the board exactly. Only the Python standard library and
a Chromium headless shell are needed.

    python3 apps/biombo/ios/scripts/render_art.py --boards <canvas/project dir>
        [--browser <chrome-headless-shell or Chrome binary>] [--only postal|vignette|island]

The island's geographic bounds are printed at the end; they must match
`PaintedIsland.bounds` in the app.
"""

import argparse
import html
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Biombo/Resources/Assets.xcassets/Art"

POSTAL_MOTIFS = ["gasolinera", "barrio-montana", "barrio-costa", "barrio-ciudad", "colmado", "cargador", "agua", "carretera"]
VIGNETTE_MOTIFS = ["cotorra", "coqui", "flamboyan", "garita", "palma", "farol", "olas", "candado"]

# (theme, file suffix, asset-catalog appearances)
APPEARANCES = [
    ("light", "light", []),
    ("dark", "dark", [{"appearance": "luminosity", "value": "dark"}]),
    ("light-hc", "hc-light", [{"appearance": "contrast", "value": "high"}]),
    ("dark-hc", "hc-dark", [{"appearance": "luminosity", "value": "dark"}, {"appearance": "contrast", "value": "high"}]),
]

# Plates render at half their 358×200 board size: enough for the 64pt strip
# and a 168pt plate, and far lighter than full size.
PLATE_POINTS = (179, 100)
VIGNETTE_POINTS = (120, 120)

# The island board projects lon/lat as x = 14 + (lon + 67.27)·SX,
# y = 285 + (18.52 − lat)·SY (the island group sits 110pt down), with
# SY = SX / cos-lat (scratchpad/dira/isla_real.py). The crop below keeps
# Puerto Rico, Vieques and Culebra with a sea margin.
ISLAND_SX = 176.6
ISLAND_SY = ISLAND_SX / 0.95
ISLAND_CROP_Y = (260, 420)
ISLAND_WIDTH_PX = 2048

RUNTIME = r"""
class DCLogic { constructor(props) { this.props = props; this.state = {}; } setState() {} }
const Component = (0, eval)('(' + COMPONENT + ')');
const vals = new Component(PROPS).renderVals();
const keys = Object.keys(vals);
const filled = TEMPLATE.replace(/\{\{\s*([\s\S]+?)\s*\}\}/g, (m, expr) => {
  const value = new Function(...keys, 'return (' + expr + ');')(...keys.map(k => vals[k]));
  return String(value);
});
const host = document.getElementById('host');
host.innerHTML = filled;
let pending;
while ((pending = host.querySelector('sc-if'))) {
  if (pending.getAttribute('value') === 'true') { pending.replaceWith(...pending.childNodes); } else { pending.remove(); }
}
host.querySelectorAll('dc-import').forEach(n => n.remove());
"""


def parse_board(path: Path):
    source = path.read_text(encoding="utf-8")
    style = re.search(r"<helmet><style>(.*?)</style></helmet>", source, re.S).group(1)
    template = re.search(r"</helmet>(.*?)</x-dc>", source, re.S).group(1)
    component = re.search(r"<script type=\"text/x-dc\"[^>]*>\s*(class Component.*?)</script>", source, re.S).group(1)
    return style, template, component.strip()


def page(board_dir: Path, board: str, props: dict, extra_css: str, wrapper_style: str) -> str:
    style, template, component = parse_board(board_dir / f"{board}.dc.html")
    tokens = (board_dir / "css/v2-tokens.css").as_uri()
    return f"""<!doctype html><html><head><meta charset="utf-8">
<link rel="stylesheet" href="{html.escape(tokens)}">
<style>{style}
html, body {{ margin: 0; background: transparent !important; overflow: hidden; }}
{extra_css}</style></head>
<body><div id="clip" style="{wrapper_style}"><div id="host"></div></div>
<script>const TEMPLATE = {json.dumps(template)}; const COMPONENT = {json.dumps(component)}; const PROPS = {json.dumps(props)};
{RUNTIME}</script></body></html>"""


def screenshot(browser: str, markup: str, size: tuple, scale: float, out: Path, workdir: Path):
    source = workdir / "board.html"
    source.write_text(markup, encoding="utf-8")
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            browser, "--headless", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
            "--default-background-color=00000000", f"--force-device-scale-factor={scale}",
            f"--window-size={size[0]},{size[1]}", "--virtual-time-budget=4000",
            f"--screenshot={out}", source.as_uri(),
        ],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    if not out.exists():
        sys.exit(f"render failed: {out.name}")


def write_imageset(folder: Path, images: list):
    folder.mkdir(parents=True, exist_ok=True)
    contents = {"images": images, "info": {"author": "xcode", "version": 1}}
    (folder / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")


def write_group(folder: Path):
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n", encoding="utf-8")


def render_set(browser, board_dir, workdir, board, name, props, board_size, points, extra_css=""):
    """One motif in four appearances at @2x and @3x."""
    folder = ART / board.split("-")[1] / f"{name}.imageset"
    if folder.exists():
        shutil.rmtree(folder)
    images = []
    for theme, suffix, appearances in APPEARANCES:
        for scale in (2, 3):
            filename = f"{name}-{suffix}@{scale}x.png"
            factor = points[0] * scale / board_size[0]
            markup = page(board_dir, board, {**props, "theme": theme}, extra_css, "")
            screenshot(browser, markup, board_size, factor, folder / filename, workdir)
            entry = {"filename": filename, "idiom": "universal", "scale": f"{scale}x"}
            if appearances:
                entry["appearances"] = appearances
            images.append(entry)
    write_imageset(folder, images)
    print(f"  {folder.name}")


def render_postal(browser, board_dir, workdir):
    # The app clips and edges the plate itself, so the raster has square corners and no hairline.
    css = ".v2p-plate { border-radius: 0 !important; } .v2p-hairline { display: none !important; }"
    for motif in POSTAL_MOTIFS:
        render_set(browser, board_dir, workdir, "V2-Postal", f"plate-{motif}", {"motif": motif}, (358, 200), PLATE_POINTS, css)


def render_vignettes(browser, board_dir, workdir):
    for motif in VIGNETTE_MOTIFS:
        render_set(browser, board_dir, workdir, "V2-Vignette", f"vignette-{motif}", {"motif": motif, "filled": True}, (120, 120), VIGNETTE_POINTS)


def render_island(browser, board_dir, workdir):
    top, bottom = ISLAND_CROP_Y
    height = bottom - top
    scale = ISLAND_WIDTH_PX / 390
    # Paint only: labels, town dots and the plain coast are drawn by the app and MapKit.
    css = """
.v2i text, .v2i-m-dot, .v2i-coast { display: none !important; }
#clip { position: relative; width: 390px; overflow: hidden;
  -webkit-mask-image: linear-gradient(to right, transparent, #000 7%, #000 93%, transparent),
                      linear-gradient(to bottom, transparent, #000 16%, #000 84%, transparent);
  -webkit-mask-composite: source-in; mask-composite: intersect; }
#host { transform: translateY(-TOPpx); }
""".replace("TOP", str(top))
    folder = ART / "Island" / "painted-island.imageset"
    if folder.exists():
        shutil.rmtree(folder)
    images = []
    for theme, suffix, appearances in APPEARANCES[:2]:
        filename = f"painted-island-{suffix}.png"
        markup = page(board_dir, "V2-Island", {"theme": theme, "zoom": "island", "pintado": True}, css, f"height: {height}px;")
        screenshot(browser, markup, (390, height), scale, folder / filename, workdir)
        entry = {"filename": filename, "idiom": "universal", "scale": "1x"}
        if appearances:
            entry["appearances"] = appearances
        images.append(entry)
    write_imageset(folder, images)

    def lon(x):
        return (x - 14) / ISLAND_SX - 67.27

    def lat(y):
        return 18.52 - (y - 285) / ISLAND_SY

    print(f"  {folder.name}: north {lat(top):.4f}, south {lat(bottom):.4f}, west {lon(0):.4f}, east {lon(390):.4f}")


def find_browser(explicit):
    if explicit:
        return explicit
    candidates = sorted(Path.home().glob("Library/Caches/ms-playwright/chromium_headless_shell-*/chrome-headless-shell-mac-arm64/chrome-headless-shell"), reverse=True)
    candidates.append(Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"))
    for candidate in candidates:
        if candidate.exists():
            return str(candidate)
    sys.exit("No Chromium found; pass --browser.")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--boards", required=True, type=Path, help="the design canvas project folder with V2-*.dc.html")
    parser.add_argument("--browser", help="chrome-headless-shell or Chrome binary")
    parser.add_argument("--only", choices=["postal", "vignette", "island"])
    args = parser.parse_args()
    browser = find_browser(args.browser)

    write_group(ART)
    for group in ("Postal", "Vignette", "Island"):
        write_group(ART / group)
    with tempfile.TemporaryDirectory() as tmp:
        workdir = Path(tmp)
        if args.only in (None, "postal"):
            print("Postal plates")
            render_postal(browser, args.boards, workdir)
        if args.only in (None, "vignette"):
            print("Vignettes")
            render_vignettes(browser, args.boards, workdir)
        if args.only in (None, "island"):
            print("Painted island")
            render_island(browser, args.boards, workdir)


if __name__ == "__main__":
    main()

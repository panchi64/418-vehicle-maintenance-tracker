# Biombo — Design

**Status: exploratory, not formalized.** The visual direction is being worked out in private design artifacts. Don't encode tokens, palettes or component specs in the repo until the owner signs off.

Biombo's design is separate from Checkpoint's. `docs/AESTHETIC.md` and `docs/SURFACE_DOCTRINE.md` describe Checkpoint and do not govern Biombo.

## Current direction

- **Apple-native, warm civic.** It should feel like a first-party iOS app built on system materials and type. Palette and typography are exploratory and live only in the private design artifacts.
- **Mood reference:** the watercolor art on Puerto Rico's digital ID cards. Take the mood only, never the artwork, the seal or the government wordmark.
- **The blend being prototyped:**
  - Painted postcard plates on places and key moments.
  - A painted island map at wide zoom that turns plain at street zoom.
  - Ink line vignettes for small moments and progression.
  - No art in crisis mode, on data surfaces or in high-contrast themes.
- **No data dumps.** The information-design rules (answer first, row budgets, disclosure tiers, glance test) are product rules and live in `PRODUCT.md` §3.
- **Iconography** still needs work; it's low priority for now.

## Non-negotiables

- Never colour alone: status, layer and verification each carry a symbol or shape plus a word.
- Light, dark and Increase Contrast. Text ≥4.5:1, and ≥7:1 in the high-contrast themes.
- Dynamic Type through the accessibility sizes, with 44pt tap targets.
- Motion that respects Reduce Motion.
- Spanish-first, with a parallel English version and no concatenated strings.

The contrast gate can check a Biombo palette once one exists: `uv run tools/theme-contrast/check_contrast.py --target biombo --tokens <tokens.json> --pairs <contrast-pairs.json>`.

# tools/depth-backdrops

Internal tool that generates cerulean-tinted, pixel-quantized, depth-mapped backdrops for App Store screenshots (see `docs/marketing/APP_STORE_ASSETS.md`). The tool's job ends at "depth + pixel grid + color mix" at the source's native resolution — framing, device mockup compositing, and caption typography happen downstream in Figma.

Two processes:

- **`backend/`** — Python (uv) + FastAPI. Runs Depth Anything V2 Small via Core ML on the Apple Neural Engine. SHA256-keyed depth-map cache.
- **`frontend/`** — Vite + React + TypeScript. WebGL2 fragment shader does all the live styling (pixel grid + gap, value remap, near/far color mix). The shader output is the export, at the **source image's native dimensions** — no margin, no resizing. Add framing in post (Figma).

## Run

```
./dev.sh
# backend  → http://localhost:8000
# frontend → http://localhost:5173
```

`dev.sh` starts both processes and shuts them down together on Ctrl-C. Override ports with `BACKEND_PORT=… FRONTEND_PORT=… ./dev.sh`. On first run it downloads the Depth Anything V2 Small `.mlpackage` from Apple's HuggingFace mirror into `backend/models/` (~25 MB).

If you need the processes individually:
- Backend: `cd backend && uv run uvicorn app.main:app --reload --port 8000`
- Frontend: `cd frontend && bun run dev`
- Model download: `cd backend && uv run python -m scripts.download_model`

All Python commands go through `uv` — never call `python` or `pip` directly.

## Layout

- `sources/` (gitignored) — uploaded input images, named `<sha256>.<ext>`
- `presets/` (committed) — JSON snapshots of every shipped backdrop, the reproducibility audit trail
- `out/` (gitignored) — exported PNGs from batch runs
- `backend/.cache/` (gitignored) — depth maps keyed by source SHA256

## Workflow

1. Drop an image into the left panel (drag-and-drop or "Choose file"). The backend hashes it, writes it to `sources/<sha>.<ext>`, runs depth inference once, and caches the depth map. A loading overlay covers the preview while inference runs (first image ≈5 s for the model load, every subsequent ≈70 ms).
2. Tweak parameters in the right panel — everything updates the WebGL preview at 60 fps. Press `1`/`2`/`3` to toggle between source · depth · styled.
3. Type a name and click **Save as** to persist the current parameters to `presets/<name>.json`. Subsequent edits show a `*` marker; **Save** writes them back. Commit the JSON to lock the recipe.
4. **Export PNG** downloads the rendered frame at the **source image's native dimensions** (no resizing, no margin — add those in post). **Batch export to out/** runs every source through the active preset and writes to `out/<preset>/<sha>.png`, each at its own source dimensions.

## Parameter groups (right panel)

- **Depth** — `Range` clips the input depth before remap, `Gamma` curves it, `Contrast` pivots around 0.5, `Invert` flips near/far.
- **Pixel grid** — `Cell px` is the side length of each quantization cell. `Gap px` insets each cell so the spacing between dots shows the `Far` color (zero gap = solid grid).
- **Color** — `Near`/`Far` are the two endpoints the depth value is mixed between. `Mix range` compresses the mix to a narrow band so the backdrop stays subtle (default 0.05–0.18 keeps the whole image near the cerulean end with just enough variation to read as depth).

## Performance

- Cold model load + first inference: ~5 s (one-time per backend start).
- Warm inference on a new image: ~70 ms on M-series ANE.
- Cached inference: ~5 ms (served from `backend/.cache/`).
- Shader preview: 60 fps with all sliders moving — the depth map is loaded into a WebGL2 texture once per source change; slider edits only update uniforms.

## Reproducibility

A preset + the matching source file fully determine an output PNG. `presets/` is committed; `sources/` and `out/` are gitignored. Commit a preset alongside any App Store frame so the backdrop can be regenerated later from the same input.

## Brand tokens

Defined in `frontend/src/tokens.ts`. They mirror — but do not import from — `packages/DesignKit/Sources/DesignKit/Providers/AestheticBrutalistTheme.swift` and `apps/checkpoint/web/src/app.css`. Keep all three in sync if the brand palette changes.

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { api } from "./api";
import { DEFAULT_PARAMS, ParamsSchema, defaultPreset } from "./presets/schema";
import { BackdropRenderer } from "./shader/renderer";
import { Controls } from "./ui/Controls";
import { Preview, type DepthLoadState } from "./ui/Preview";
import { PresetBar } from "./ui/PresetBar";
import { SourceList } from "./ui/SourceList";
import type { Params, Preset, Source, ViewMode } from "./types";

const LS_PARAMS = "depth-backdrops/params";
const LS_ACTIVE_SOURCE = "depth-backdrops/source";
const LS_ACTIVE_PRESET = "depth-backdrops/preset";

function loadStoredParams(): Params {
  try {
    const raw = localStorage.getItem(LS_PARAMS);
    if (!raw) return DEFAULT_PARAMS;
    return ParamsSchema.parse(JSON.parse(raw));
  } catch {
    return DEFAULT_PARAMS;
  }
}

export default function App() {
  const [sources, setSources] = useState<Source[]>([]);
  const [presets, setPresets] = useState<Preset[]>([]);
  const [activeSha, setActiveSha] = useState<string | null>(
    () => localStorage.getItem(LS_ACTIVE_SOURCE),
  );
  const [activePresetName, setActivePresetName] = useState<string>(
    () => localStorage.getItem(LS_ACTIVE_PRESET) || "untitled",
  );
  const [params, setParams] = useState<Params>(loadStoredParams);
  const [view, setView] = useState<ViewMode>("styled");
  const [batchStatus, setBatchStatus] = useState<string | null>(null);
  const [depthState, setDepthState] = useState<DepthLoadState>({ kind: "idle" });
  const [error, setError] = useState<string | null>(null);
  const [dropping, setDropping] = useState(false);

  const rendererRef = useRef<BackdropRenderer | null>(null);
  // Refs so the source-load effect can read latest params/view/sources without
  // re-triggering depth inference on every slider tick.
  const paramsRef = useRef(params);
  const viewRef = useRef(view);
  const sourcesRef = useRef(sources);
  const modelWarmRef = useRef(false);
  useEffect(() => {
    paramsRef.current = params;
  }, [params]);
  useEffect(() => {
    viewRef.current = view;
  }, [view]);
  useEffect(() => {
    sourcesRef.current = sources;
  }, [sources]);

  // initial data
  useEffect(() => {
    api
      .listSources()
      .then(setSources)
      .catch((e) => setError(`listSources: ${e}`));
    api
      .listPresets()
      .then(setPresets)
      .catch((e) => setError(`listPresets: ${e}`));
  }, []);

  // autosave params
  useEffect(() => {
    localStorage.setItem(LS_PARAMS, JSON.stringify(params));
  }, [params]);

  useEffect(() => {
    if (activeSha) localStorage.setItem(LS_ACTIVE_SOURCE, activeSha);
    else localStorage.removeItem(LS_ACTIVE_SOURCE);
  }, [activeSha]);

  useEffect(() => {
    localStorage.setItem(LS_ACTIVE_PRESET, activePresetName);
  }, [activePresetName]);

  // load source + depth into shader when selection changes
  useEffect(() => {
    const r = rendererRef.current;
    if (!r) return;
    if (!activeSha) {
      r.clearSource();
      r.clearDepth();
      r.render(paramsRef.current, viewRef.current);
      setDepthState({ kind: "idle" });
      return;
    }
    let cancelled = false;
    let tickId: number | null = null;
    const source = sourcesRef.current.find((s) => s.sha === activeSha);
    const sourceName = source?.originalFilename ?? activeSha.slice(0, 8);
    const cached = source?.hasDepth ?? false;
    const warm = cached || modelWarmRef.current;
    const start = performance.now();
    setDepthState({ kind: "loading", sourceName, warm, elapsedMs: 0 });
    tickId = window.setInterval(() => {
      setDepthState((s) =>
        s.kind === "loading" ? { ...s, elapsedMs: performance.now() - start } : s,
      );
    }, 100);

    Promise.all([r.loadSource(api.imageUrl(activeSha)), r.loadDepth(api.depthUrl(activeSha))])
      .then(() => {
        if (cancelled) return;
        modelWarmRef.current = true;
        setDepthState({ kind: "idle" });
        setError(null);
        // mark this source as cached for future selections
        setSources((prev) =>
          prev.map((s) => (s.sha === activeSha ? { ...s, hasDepth: true } : s)),
        );
        r.render(paramsRef.current, viewRef.current);
      })
      .catch((e) => {
        if (cancelled) return;
        const msg = String(e);
        setDepthState({ kind: "error", message: msg });
        setError(`load ${activeSha.slice(0, 8)}: ${msg}`);
      })
      .finally(() => {
        if (tickId !== null) clearInterval(tickId);
      });

    return () => {
      cancelled = true;
      if (tickId !== null) clearInterval(tickId);
    };
  }, [activeSha]);

  // keyboard view toggle
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const t = e.target as HTMLElement | null;
      if (
        t instanceof HTMLInputElement ||
        t instanceof HTMLSelectElement ||
        t instanceof HTMLTextAreaElement ||
        t?.isContentEditable
      )
        return;
      if (e.key === "1") setView("source");
      else if (e.key === "2") setView("depth");
      else if (e.key === "3") setView("styled");
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  // window-wide drag-over visual
  useEffect(() => {
    const enter = (e: DragEvent) => {
      if (e.dataTransfer?.types.includes("Files")) setDropping(true);
    };
    const leave = (e: DragEvent) => {
      if (e.relatedTarget === null) setDropping(false);
    };
    const drop = () => setDropping(false);
    window.addEventListener("dragenter", enter);
    window.addEventListener("dragleave", leave);
    window.addEventListener("drop", drop);
    return () => {
      window.removeEventListener("dragenter", enter);
      window.removeEventListener("dragleave", leave);
      window.removeEventListener("drop", drop);
    };
  }, []);

  const handleUpload = useCallback(async (files: FileList) => {
    setError(null);
    let lastSha: string | null = null;
    for (const f of Array.from(files)) {
      try {
        const s = await api.uploadSource(f);
        lastSha = s.sha;
      } catch (e) {
        setError(`upload ${f.name}: ${e}`);
      }
    }
    try {
      const updated = await api.listSources();
      setSources(updated);
    } catch (e) {
      setError(`listSources: ${e}`);
    }
    if (lastSha) setActiveSha(lastSha);
  }, []);

  const handleDelete = useCallback(
    async (sha: string) => {
      try {
        await api.deleteSource(sha);
      } catch (e) {
        setError(`delete: ${e}`);
        return;
      }
      try {
        const updated = await api.listSources();
        setSources(updated);
        if (activeSha === sha) setActiveSha(updated[0]?.sha ?? null);
        setError(null);
      } catch (e) {
        setError(`listSources: ${e}`);
      }
    },
    [activeSha],
  );

  const activeSource = useMemo(
    () => sources.find((s) => s.sha === activeSha) ?? null,
    [sources, activeSha],
  );

  const outputSize = useMemo(
    () => (activeSource ? { width: activeSource.width, height: activeSource.height } : null),
    [activeSource],
  );

  const activePreset = useMemo(
    () => presets.find((p) => p.name === activePresetName) ?? null,
    [presets, activePresetName],
  );

  const dirty = useMemo(() => {
    if (!activePreset) return true;
    return JSON.stringify(activePreset.params) !== JSON.stringify(params);
  }, [activePreset, params]);

  const handleSaveAs = useCallback(
    async (name: string) => {
      const preset: Preset = {
        ...defaultPreset(name),
        source: activeSource
          ? { filename: activeSource.originalFilename, sha256: activeSource.sha }
          : undefined,
        params,
      };
      try {
        await api.putPreset(preset);
        setPresets(await api.listPresets());
        setActivePresetName(name);
        setError(null);
      } catch (e) {
        setError(`saveAs ${name}: ${e}`);
      }
    },
    [activeSource, params],
  );

  const handleSave = useCallback(async () => {
    if (!activePreset) return;
    const next: Preset = {
      ...activePreset,
      source: activeSource
        ? { filename: activeSource.originalFilename, sha256: activeSource.sha }
        : activePreset.source,
      params,
    };
    try {
      await api.putPreset(next);
      setPresets(await api.listPresets());
      setError(null);
    } catch (e) {
      setError(`save: ${e}`);
    }
  }, [activePreset, activeSource, params]);

  const handleLoad = useCallback(
    (name: string) => {
      const p = presets.find((x) => x.name === name);
      if (!p) return;
      setActivePresetName(name);
      setParams(p.params);
      if (p.source?.sha256) {
        if (sources.some((s) => s.sha === p.source!.sha256)) {
          setActiveSha(p.source.sha256);
        } else {
          setError(`preset's source (${p.source.filename}) is missing — keeping current image`);
        }
      }
    },
    [presets, sources],
  );

  const handleDeletePreset = useCallback(
    async (name: string) => {
      try {
        await api.deletePreset(name);
        setPresets(await api.listPresets());
        if (activePresetName === name) setActivePresetName("untitled");
        setError(null);
      } catch (e) {
        setError(`deletePreset ${name}: ${e}`);
      }
    },
    [activePresetName],
  );

  const handleExport = useCallback(async () => {
    if (!rendererRef.current || !activeSha) return;
    try {
      rendererRef.current.render(params, "styled");
      const blob = await rendererRef.current.snapshotPng();
      const name = activePreset?.name ?? "untitled";
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `${name}-${activeSha.slice(0, 8)}.png`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
      rendererRef.current.render(params, view);
      setError(null);
    } catch (e) {
      setError(`export: ${e}`);
    }
  }, [activeSha, activePreset, params, view]);

  const handleBatchExport = useCallback(async () => {
    if (!rendererRef.current) return;
    if (!activePreset) {
      setError("Save a named preset before batch exporting.");
      return;
    }
    const r = rendererRef.current;
    setBatchStatus("batch export…");
    setError(null);
    let done = 0;
    const failures: string[] = [];
    for (const s of sources) {
      try {
        r.setSize(s.width, s.height);
        await Promise.all([
          r.loadSource(api.imageUrl(s.sha)),
          r.loadDepth(api.depthUrl(s.sha)),
        ]);
        r.render(params, "styled");
        const blob = await r.snapshotPng();
        await api.exportPng(activePreset.name, s.sha, blob);
        done += 1;
        setBatchStatus(`batch export… ${done}/${sources.length}`);
      } catch (e) {
        failures.push(`${s.originalFilename}: ${e}`);
      }
    }
    setBatchStatus(
      failures.length === 0
        ? `exported ${done} → out/${activePreset.name}/`
        : `exported ${done}/${sources.length} → out/${activePreset.name}/ (${failures.length} failed)`,
    );
    if (failures.length > 0) setError(failures.join(" · "));

    try {
      if (activeSha && activeSource) {
        r.setSize(activeSource.width, activeSource.height);
        await Promise.all([
          r.loadSource(api.imageUrl(activeSha)),
          r.loadDepth(api.depthUrl(activeSha)),
        ]);
      } else {
        r.clearSource();
        r.clearDepth();
      }
      r.render(params, view);
    } catch (e) {
      setError((prev) => (prev ? `${prev} · restore: ${e}` : `restore: ${e}`));
    }
  }, [sources, activePreset, params, view, activeSha, activeSource]);

  return (
    <div className={`app${dropping ? " dropping" : ""}`}>
      <div className="topbar">
        <h1>Depth Backdrops</h1>
        <div className="right">
          <span className="preset-name">
            {activePresetName}
            {dirty ? " *" : ""}
          </span>
          {error && (
            <button
              className="status err"
              style={{ border: "none", padding: 0 }}
              title="click to dismiss"
              onClick={() => setError(null)}
            >
              ⚠ {error}
            </button>
          )}
        </div>
      </div>

      <div className="col left">
        <header>Sources</header>
        <SourceList
          sources={sources}
          selected={activeSha}
          onSelect={setActiveSha}
          onUpload={handleUpload}
          onDelete={handleDelete}
        />
      </div>

      <Preview
        params={params}
        view={view}
        setView={setView}
        rendererRef={rendererRef}
        outputSize={outputSize}
        hasSource={!!activeSha}
        depthState={depthState}
        batchStatus={batchStatus}
      />

      <div className="col right">
        <header>Preset</header>
        <PresetBar
          presets={presets}
          activeName={activePresetName}
          onLoad={handleLoad}
          onSaveAs={handleSaveAs}
          onSave={handleSave}
          onDelete={handleDeletePreset}
          dirty={dirty}
        />
        <Controls params={params} onChange={setParams} />
        <div className="export-bar">
          <button
            className="primary"
            onClick={handleExport}
            disabled={!activeSha || depthState.kind === "loading"}
            title={
              !activeSha
                ? "Select a source first"
                : depthState.kind === "loading"
                  ? "Waiting for depth map to finish"
                  : "Download the styled PNG"
            }
          >
            Export PNG
          </button>
          <button
            onClick={handleBatchExport}
            disabled={!activePreset || sources.length === 0 || depthState.kind === "loading"}
            title={
              !activePreset
                ? "Save a named preset first"
                : sources.length === 0
                  ? "No sources to export"
                  : "Render every source through this preset"
            }
          >
            Batch export to out/
          </button>
        </div>
      </div>
    </div>
  );
}

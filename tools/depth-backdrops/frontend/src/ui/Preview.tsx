import { useEffect, useRef, type RefObject } from "react";
import { BackdropRenderer } from "../shader/renderer";
import type { Params, ViewMode } from "../types";

export type DepthLoadState =
  | { kind: "idle" }
  | { kind: "loading"; sourceName: string; warm: boolean; elapsedMs: number }
  | { kind: "error"; message: string };

export function Preview({
  params,
  view,
  setView,
  rendererRef,
  outputSize,
  hasSource,
  depthState,
  batchStatus,
}: {
  params: Params;
  view: ViewMode;
  setView: (v: ViewMode) => void;
  rendererRef: RefObject<BackdropRenderer | null>;
  outputSize: { width: number; height: number } | null;
  hasSource: boolean;
  depthState: DepthLoadState;
  batchStatus: string | null;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (!canvasRef.current || rendererRef.current) return;
    rendererRef.current = new BackdropRenderer(canvasRef.current);
  }, [rendererRef]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !rendererRef.current) return;
    const targetW = outputSize?.width ?? 1;
    const targetH = outputSize?.height ?? 1;
    if (canvas.width !== targetW) canvas.width = targetW;
    if (canvas.height !== targetH) canvas.height = targetH;
    rendererRef.current.render(params, view);
  }, [params, view, outputSize, rendererRef]);

  const loading = depthState.kind === "loading";

  return (
    <div className="preview">
      <div className="view-mode">
        {(["source", "depth", "styled"] as const).map((v, i) => (
          <button
            key={v}
            className={v === view ? "active" : ""}
            onClick={() => setView(v)}
            title={`Key: ${i + 1}`}
          >
            {i + 1} {v}
          </button>
        ))}
      </div>
      {!hasSource && depthState.kind !== "loading" && (
        <div className="empty-state">
          Drop or pick an image in the left panel to start.
          <br />
          Keys 1 / 2 / 3 toggle source · depth · styled.
        </div>
      )}
      <canvas ref={canvasRef} />
      {loading && depthState.kind === "loading" && (
        <div className="loading-overlay">
          <div className="spinner" />
          <div className="loading-title">Computing depth map…</div>
          <div className="loading-meta">
            {depthState.sourceName} · {(depthState.elapsedMs / 1000).toFixed(1)} s
          </div>
          <div className="loading-hint">
            {depthState.warm
              ? "Subsequent images run in seconds."
              : "First run loads the depth model from disk — this is the slow one."}
          </div>
        </div>
      )}
      <div className="meta">
        {outputSize ? `${outputSize.width} × ${outputSize.height}` : "no source"}
        {" · "}grid {params.grid.size}px / gap {params.grid.gap}px
        {batchStatus ? ` · ${batchStatus}` : ""}
      </div>
    </div>
  );
}

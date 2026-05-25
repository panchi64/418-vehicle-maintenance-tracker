import { useEffect, useRef, type RefObject } from "react";
import { BackdropRenderer } from "../shader/renderer";
import type { Params, ViewMode } from "../types";

export function Preview({
  params,
  view,
  setView,
  rendererRef,
  hasSource,
  status,
}: {
  params: Params;
  view: ViewMode;
  setView: (v: ViewMode) => void;
  rendererRef: RefObject<BackdropRenderer | null>;
  hasSource: boolean;
  status: string | null;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (!canvasRef.current || rendererRef.current) return;
    rendererRef.current = new BackdropRenderer(canvasRef.current);
  }, [rendererRef]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !rendererRef.current) return;
    if (canvas.width !== params.output.width) canvas.width = params.output.width;
    if (canvas.height !== params.output.height) canvas.height = params.output.height;
    rendererRef.current.render(params, view);
  }, [params, view, rendererRef]);

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
      {!hasSource && (
        <div className="empty-state">
          Upload an image in the left panel to start.
          <br />
          Keys 1 / 2 / 3 toggle source · depth · styled.
        </div>
      )}
      <canvas ref={canvasRef} />
      <div className="meta">
        {params.output.width} × {params.output.height} · margin{" "}
        {params.frame.marginPct.toFixed(2)}% · grid {params.grid.size}px
        {status ? ` · ${status}` : ""}
      </div>
    </div>
  );
}

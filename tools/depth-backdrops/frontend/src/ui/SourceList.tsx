import { useRef, type DragEvent } from "react";
import { api } from "../api";
import type { Source } from "../types";

export function SourceList({
  sources,
  selected,
  onSelect,
  onUpload,
  onDelete,
}: {
  sources: Source[];
  selected: string | null;
  onSelect: (sha: string) => void;
  onUpload: (files: FileList) => void;
  onDelete: (sha: string) => void;
}) {
  const fileRef = useRef<HTMLInputElement>(null);

  const onDrop = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault();
    if (e.dataTransfer.files.length > 0) onUpload(e.dataTransfer.files);
  };
  const onDragOver = (e: DragEvent<HTMLDivElement>) => e.preventDefault();

  if (sources.length === 0) {
    return (
      <div
        className="source-list empty"
        onDrop={onDrop}
        onDragOver={onDragOver}
        data-testid="source-list-empty"
      >
        <div className="drop-hint">
          <strong>Drop an image here</strong>
          JPG, PNG, or WebP
          <div className="file-pick">
            <button onClick={() => fileRef.current?.click()}>Choose file</button>
            <input
              ref={fileRef}
              type="file"
              accept="image/jpeg,image/png,image/webp"
              hidden
              multiple
              onChange={(e) => e.target.files && onUpload(e.target.files)}
            />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="source-list" onDrop={onDrop} onDragOver={onDragOver}>
      {sources.map((s) => (
        <div
          key={s.sha}
          className={`source-thumb${selected === s.sha ? " selected" : ""}`}
          style={{ backgroundImage: `url(${api.thumbUrl(s.sha)})` }}
          title={`${s.filename} · ${s.width}×${s.height}`}
          onClick={() => onSelect(s.sha)}
        >
          <button
            className="delete"
            onClick={(e) => {
              e.stopPropagation();
              if (confirm(`Delete ${s.filename}?`)) onDelete(s.sha);
            }}
          >
            ×
          </button>
        </div>
      ))}
      <input
        ref={fileRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        hidden
        multiple
        onChange={(e) => e.target.files && onUpload(e.target.files)}
      />
      <div className="source-thumb" onClick={() => fileRef.current?.click()}>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            height: "100%",
            color: "var(--muted)",
            fontSize: 20,
          }}
        >
          +
        </div>
      </div>
    </div>
  );
}

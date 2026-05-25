import { useState } from "react";
import { PRESET_NAME_RE, type Preset } from "../types";

export function PresetBar({
  presets,
  activeName,
  onLoad,
  onSaveAs,
  onSave,
  onDelete,
  dirty,
}: {
  presets: Preset[];
  activeName: string;
  onLoad: (name: string) => void;
  onSaveAs: (name: string) => void;
  onSave: () => void;
  onDelete: (name: string) => void;
  dirty: boolean;
}) {
  const [newName, setNewName] = useState("");
  const known = new Set(presets.map((p) => p.name));
  const validNewName = PRESET_NAME_RE.test(newName);

  return (
    <div className="preset-bar">
      <select
        value={known.has(activeName) ? activeName : ""}
        onChange={(e) => e.target.value && onLoad(e.target.value)}
      >
        <option value="">— load preset —</option>
        {presets.map((p) => (
          <option key={p.name} value={p.name}>
            {p.name}
          </option>
        ))}
      </select>
      <input
        type="text"
        placeholder="new-preset-name"
        value={newName}
        onChange={(e) => setNewName(e.target.value)}
        title="lowercase letters, digits, hyphens, underscores"
      />
      <div className="actions">
        <button
          onClick={() => {
            if (!validNewName) return;
            onSaveAs(newName);
            setNewName("");
          }}
          disabled={!validNewName}
          title={
            !newName
              ? "enter a name"
              : !validNewName
                ? "lowercase letters, digits, hyphens, underscores; must start with a letter or digit"
                : ""
          }
        >
          Save as
        </button>
        <button onClick={onSave} disabled={!known.has(activeName)} className={dirty ? "primary" : ""}>
          {dirty ? "Save*" : "Saved"}
        </button>
        <button
          className="danger"
          disabled={!known.has(activeName)}
          onClick={() => {
            if (confirm(`Delete preset "${activeName}"?`)) onDelete(activeName);
          }}
        >
          Delete
        </button>
      </div>
    </div>
  );
}

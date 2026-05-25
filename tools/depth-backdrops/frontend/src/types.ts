export type Source = {
  sha: string;
  filename: string; // on-disk name (`<sha><ext>`)
  originalFilename: string; // user's original upload name
  width: number;
  height: number;
  bytes: number;
  hasDepth: boolean;
};

export const PRESET_NAME_RE = /^[a-z0-9][a-z0-9\-_]{0,63}$/;

export type ViewMode = "source" | "depth" | "styled";

export type Params = {
  depth: {
    inMin: number;
    inMax: number;
    gamma: number;
    contrast: number;
    invert: boolean;
  };
  grid: {
    size: number; // canvas pixels per grid cell
    gap: number; // canvas pixels of inset between cells
  };
  color: {
    near: string;
    far: string;
    valueRange: [number, number];
  };
};

export type Preset = {
  version: 1;
  name: string;
  source?: { filename: string; sha256: string };
  model: { id: string; version: string };
  params: Params;
};

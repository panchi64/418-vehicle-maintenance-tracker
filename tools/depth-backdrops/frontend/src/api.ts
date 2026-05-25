import type { Preset, Source } from "./types";

const BASE = "/api";

async function json<T>(res: Response): Promise<T> {
  if (!res.ok) throw new Error(`${res.status} ${res.statusText} ${await res.text()}`);
  return (await res.json()) as T;
}

export const api = {
  async listSources(): Promise<Source[]> {
    return (await json<{ sources: Source[] }>(await fetch(`${BASE}/sources`))).sources;
  },

  async uploadSource(file: File): Promise<Source> {
    const fd = new FormData();
    fd.append("file", file);
    return json<Source>(await fetch(`${BASE}/sources`, { method: "POST", body: fd }));
  },

  async deleteSource(sha: string): Promise<void> {
    const res = await fetch(`${BASE}/sources/${encodeURIComponent(sha)}`, {
      method: "DELETE",
    });
    if (!res.ok && res.status !== 204) throw new Error(await res.text());
  },

  thumbUrl(sha: string): string {
    return `${BASE}/sources/${encodeURIComponent(sha)}/thumb`;
  },

  imageUrl(sha: string): string {
    return `${BASE}/sources/${encodeURIComponent(sha)}/image`;
  },

  depthUrl(sha: string): string {
    return `${BASE}/depth?sha=${encodeURIComponent(sha)}`;
  },

  async listPresets(): Promise<Preset[]> {
    return (await json<{ presets: Preset[] }>(await fetch(`${BASE}/presets`))).presets;
  },

  async putPreset(preset: Preset): Promise<void> {
    const res = await fetch(`${BASE}/presets/${encodeURIComponent(preset.name)}`, {
      method: "PUT",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(preset),
    });
    if (!res.ok) throw new Error(await res.text());
  },

  async deletePreset(name: string): Promise<void> {
    const res = await fetch(`${BASE}/presets/${encodeURIComponent(name)}`, {
      method: "DELETE",
    });
    if (!res.ok && res.status !== 204) throw new Error(await res.text());
  },

  async exportPng(presetName: string, sha: string, blob: Blob): Promise<string> {
    const buf = await blob.arrayBuffer();
    const b64 = arrayBufferToBase64(buf);
    const out = await json<{ path: string }>(
      await fetch(`${BASE}/export`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ preset: presetName, sha, png_base64: b64 }),
      }),
    );
    return out.path;
  },
};

function arrayBufferToBase64(buf: ArrayBuffer): string {
  const bytes = new Uint8Array(buf);
  let s = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    s += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(s);
}

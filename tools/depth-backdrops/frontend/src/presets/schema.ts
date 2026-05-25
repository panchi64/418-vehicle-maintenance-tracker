import { z } from "zod";
import { CERULEAN, OFF_WHITE } from "../tokens";
import type { Params, Preset } from "../types";

const hex = z.string().regex(/^#[0-9A-Fa-f]{6}$/);

export const ParamsSchema = z.object({
  depth: z.object({
    inMin: z.number().min(0).max(1),
    inMax: z.number().min(0).max(1),
    gamma: z.number().min(0.1).max(5),
    contrast: z.number().min(0).max(4),
    invert: z.boolean(),
  }),
  grid: z.object({
    size: z.number().int().min(1).max(256),
    gap: z.number().int().min(0).max(256).default(0),
  }),
  color: z.object({
    near: hex,
    far: hex,
    valueRange: z.tuple([z.number().min(0).max(1), z.number().min(0).max(1)]),
  }),
  frame: z.object({
    marginPct: z.number().min(0).max(20),
    color: hex,
  }),
  output: z.object({
    width: z.number().int().min(64).max(8192),
    height: z.number().int().min(64).max(8192),
  }),
});

export const PresetSchema = z.object({
  version: z.literal(1),
  name: z.string().regex(/^[a-z0-9][a-z0-9\-_]{0,63}$/),
  source: z
    .object({ filename: z.string(), sha256: z.string().length(64) })
    .optional(),
  model: z.object({ id: z.string(), version: z.string() }),
  params: ParamsSchema,
});

export const DEFAULT_PARAMS: Params = {
  depth: { inMin: 0, inMax: 1, gamma: 1, contrast: 1, invert: false },
  grid: { size: 24, gap: 4 },
  color: {
    near: OFF_WHITE,
    far: CERULEAN,
    valueRange: [0.05, 0.18],
  },
  frame: { marginPct: 2.65, color: OFF_WHITE },
  output: { width: 1320, height: 2868 },
};

export const defaultPreset = (name = "untitled"): Preset => ({
  version: 1,
  name,
  model: { id: "depth-anything-v2-small", version: "1.0" },
  params: structuredClone(DEFAULT_PARAMS),
});

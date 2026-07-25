/*
 * Reads Checkpoint's real theme definitions.
 *
 * This imports apps/checkpoint/ios/checkpoint/Resources/Themes.json directly
 * (via the @checkpoint alias in vite.config.ts) rather than keeping a copy.
 * A copy would drift, and a sketchpad that renders colors the app doesn't ship
 * is worse than no sketchpad — it would validate layouts against fiction.
 *
 * The doctrine requires verifying any surface against more than one theme,
 * including a light-scheme one. All eight are switchable in the harness.
 */
import rawThemes from '@checkpoint/Resources/Themes.json'

export type FontDesign = 'monospaced' | 'rounded' | 'serif'
export type ColorScheme = 'dark' | 'light'

export interface ThemeDefinition {
  id: string
  displayName: string
  description: string
  tier: 'free' | 'pro' | 'rare'
  fontDesign: FontDesign
  colorScheme: ColorScheme
  previewColors: string[]
  backgroundPrimary: string
  backgroundElevated: string
  backgroundSubtle: string
  surfaceInstrument: string
  glow: string
  gridLine: string
  textPrimary: string
  textSecondary: string
  textTertiary: string
  borderSubtle: string
  accent: string
  accentMuted: string
  statusOverdue: string
  statusDueSoon: string
  statusGood: string
  statusNeutral: string
}

export const themes = rawThemes as ThemeDefinition[]

export const defaultTheme =
  themes.find((t) => t.id === 'default') ?? themes[0]

/** Every color key on a theme, i.e. everything that becomes a CSS variable. */
const COLOR_KEYS = [
  'backgroundPrimary',
  'backgroundElevated',
  'backgroundSubtle',
  'surfaceInstrument',
  'glow',
  'gridLine',
  'textPrimary',
  'textSecondary',
  'textTertiary',
  'borderSubtle',
  'accent',
  'accentMuted',
  'statusOverdue',
  'statusDueSoon',
  'statusGood',
  'statusNeutral',
] as const satisfies readonly (keyof ThemeDefinition)[]

/** `backgroundPrimary` -> `--background-primary` */
function cssVarName(key: string): string {
  return `--${key.replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`)}`
}

/**
 * Writes a theme onto the document root as CSS variables.
 *
 * Swift resolves colors through `ThemeManager.shared.current` at render time;
 * CSS variables are the closest equivalent, and they mean no component ever
 * names a hue.
 */
export function applyTheme(theme: ThemeDefinition, root: HTMLElement = document.documentElement): void {
  for (const key of COLOR_KEYS) {
    root.style.setProperty(cssVarName(key), theme[key])
  }
  root.dataset.fontDesign = theme.fontDesign
  root.dataset.colorScheme = theme.colorScheme
  root.style.colorScheme = theme.colorScheme
}

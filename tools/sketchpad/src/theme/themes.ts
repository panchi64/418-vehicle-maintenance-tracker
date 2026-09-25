/*
 * Reads Checkpoint's real theme definitions.
 *
 * This imports apps/checkpoint/ios/checkpoint/Resources/Themes.json directly
 * (via the @checkpoint alias in vite.config.ts) rather than keeping a copy.
 * A copy would drift, and a sketchpad that renders colors the app doesn't ship
 * is worse than no sketchpad — it would validate layouts against fiction.
 *
 * Every theme defines light and dark palettes, plus Increase Contrast
 * overrides for each. The app follows the system appearance, so a layout has
 * to hold in all of them; the harness switches appearance and contrast
 * independently of the theme.
 */
import rawThemes from '@checkpoint/Resources/Themes.json'

export type FontDesign = 'monospaced' | 'rounded' | 'serif'
export type ColorScheme = 'dark' | 'light'

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
] as const

export type ColorKey = (typeof COLOR_KEYS)[number]
export type ColorSet = Record<ColorKey, string>

export interface ThemeDefinition {
  id: string
  displayName: string
  description: string
  tier: 'free' | 'pro' | 'rare'
  fontDesign: FontDesign
  previewColors: string[]
  /**
   * `light` and `dark` are complete. The high-contrast sets are overrides on
   * their base appearance and list only what Increase Contrast changes —
   * mirrored from `ThemeAppearances` in ThemeDefinition.swift.
   */
  colors: {
    light: ColorSet
    dark: ColorSet
    lightHighContrast?: Partial<ColorSet>
    darkHighContrast?: Partial<ColorSet>
  }
}

export interface Appearance {
  scheme: ColorScheme
  highContrast: boolean
}

export const themes = rawThemes as ThemeDefinition[]

export const defaultTheme =
  themes.find((t) => t.id === 'default') ?? themes[0]

/** The appearance the browser reports — the same signal iOS gives the app. */
export function systemAppearance(): Appearance {
  const matches = (q: string) => window.matchMedia?.(q).matches ?? false
  return {
    scheme: matches('(prefers-color-scheme: light)') ? 'light' : 'dark',
    highContrast: matches('(prefers-contrast: more)'),
  }
}

/** The complete color set a theme renders with in one appearance. */
export function resolveColors(theme: ThemeDefinition, appearance: Appearance): ColorSet {
  const base = theme.colors[appearance.scheme]
  if (!appearance.highContrast) return base
  const overrides =
    appearance.scheme === 'light' ? theme.colors.lightHighContrast : theme.colors.darkHighContrast
  return { ...base, ...overrides }
}

/** `backgroundPrimary` -> `--background-primary` */
function cssVarName(key: string): string {
  return `--${key.replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`)}`
}

/**
 * Writes a theme onto the document root as CSS variables.
 *
 * Swift resolves colors through the active theme's palette at render time,
 * picking the light/dark/contrast value from the environment; CSS variables
 * are the closest equivalent, and they mean no component ever names a hue.
 */
export function applyTheme(
  theme: ThemeDefinition,
  appearance: Appearance,
  root: HTMLElement = document.documentElement,
): void {
  const colors = resolveColors(theme, appearance)
  for (const key of COLOR_KEYS) {
    root.style.setProperty(cssVarName(key), colors[key])
  }
  root.dataset.fontDesign = theme.fontDesign
  root.dataset.colorScheme = appearance.scheme
  root.dataset.highContrast = String(appearance.highContrast)
  root.style.colorScheme = appearance.scheme
}

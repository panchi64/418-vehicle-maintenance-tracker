/*
 * Text primitives, one per accessor in Typography.swift.
 *
 * Two things are deliberately separate props:
 *
 *   - which type style renders it  (`<Heading>` vs `<Body>`)
 *   - what rank it holds           (`rank="primary"`)
 *
 * SURFACE_DOCTRINE Part 1 says to rank content *before* styling it, because
 * ranking is a product decision and styling is how you express it. Keeping them
 * as one prop is what lets a screen end up with five things at heading size and
 * no answer to "which one matters". Here the rank is declared independently and
 * the harness audits it — see harness/Inspector.tsx.
 */
import type { JSX } from 'solid-js'
import { splitProps } from 'solid-js'

export type Rank = 'primary' | 'secondary' | 'tertiary'

export type ColorToken =
  | 'primary'
  | 'secondary'
  | 'tertiary'
  | 'accent'
  | 'accentMuted'
  | 'overdue'
  | 'dueSoon'
  | 'good'
  | 'neutral'
  | 'inherit'

const COLOR_VARS: Record<ColorToken, string> = {
  primary: 'var(--text-primary)',
  secondary: 'var(--text-secondary)',
  tertiary: 'var(--text-tertiary)',
  accent: 'var(--accent)',
  accentMuted: 'var(--accent-muted)',
  overdue: 'var(--status-overdue)',
  dueSoon: 'var(--status-due-soon)',
  good: 'var(--status-good)',
  neutral: 'var(--status-neutral)',
  inherit: 'inherit',
}

interface TextProps extends JSX.HTMLAttributes<HTMLSpanElement> {
  color?: ColorToken
  /** Declared hierarchy rank. Audited by the inspector, not styled directly. */
  rank?: Rank
  tracking?: number
  uppercase?: boolean
  as?: 'span' | 'div' | 'p'
  lines?: number
}

function make(styleVar: string, defaults: Partial<TextProps> = {}) {
  return (props: TextProps) => {
    const [local, rest] = splitProps(props, [
      'color',
      'rank',
      'tracking',
      'uppercase',
      'as',
      'lines',
      'style',
      'class',
      'children',
    ])

    const color = local.color ?? defaults.color ?? 'primary'
    const tracking = local.tracking ?? defaults.tracking
    const uppercase = local.uppercase ?? defaults.uppercase ?? false
    const lines = local.lines

    return (
      <span
        {...rest}
        class={local.class}
        data-rank={local.rank}
        style={{
          font: `var(${styleVar})`,
          color: COLOR_VARS[color],
          'letter-spacing': tracking != null ? `${tracking}px` : undefined,
          'text-transform': uppercase ? 'uppercase' : undefined,
          display: lines != null ? '-webkit-box' : (local.as === 'div' ? 'block' : undefined),
          '-webkit-line-clamp': lines != null ? String(lines) : undefined,
          '-webkit-box-orient': lines != null ? 'vertical' : undefined,
          overflow: lines != null ? 'hidden' : undefined,
          ...(typeof local.style === 'object' ? local.style : {}),
        }}
      >
        {local.children}
      </span>
    )
  }
}

/** 56 Light — a single dominant number. Never a substitute for hierarchy below it. */
export const Hero = make('--font-hero')
/** 32 Medium — primary headings. Uppercased, matching BrutalistTitleStyle. */
export const Title = make('--font-title', { uppercase: true })
/** 20 Medium — section titles, service names. */
export const Heading = make('--font-heading')
/** 15 Medium — the one primary datum of a section or form. */
export const Emphasis = make('--font-body-emphasis')
/** 15 Regular — ordinary values. */
export const Body = make('--font-body')
/** 13 Regular — supporting text. */
export const Secondary = make('--font-secondary', { color: 'secondary' })
/** 11 Medium caps, tracked — labels and eyebrows. */
export const Label = make('--font-label', {
  color: 'tertiary',
  uppercase: true,
  tracking: 1.5,
})
/** 11 Bold caps — emphasized labels. */
export const LabelBold = make('--font-label-bold', {
  color: 'tertiary',
  uppercase: true,
  tracking: 1.5,
})

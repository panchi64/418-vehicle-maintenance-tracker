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
import { mergeProps, splitProps } from 'solid-js'

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

export interface TextProps extends JSX.HTMLAttributes<HTMLSpanElement> {
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

/**
 * 56 Light — a single dominant number. Never a substitute for hierarchy below it.
 * Shrinks to fit the screen's width the way
 * `.minimumScaleFactor(0.5).lineLimit(1)` does in SwiftUI — at 2x on 375pt,
 * "$2,308" was 403pt wide in a 315pt column. A number must never wrap.
 */
const HeroBase = make('--font-hero')
export const Hero = (props: TextProps) =>
  HeroBase(
    mergeProps(
      {
        style: {
          // `cqi` resolves against Screen, which is an inline-size container.
          'font-size': 'min(calc(56px * var(--type-scale)), 22cqi)',
          'white-space': 'nowrap',
        } as JSX.CSSProperties,
      },
      props,
    ),
  )
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
/**
 * The section-tier header. Case, size, and tracking come from the harness's
 * "Section headers" switch (base.css `--section-*`), so ReadoutSection,
 * FormSection, and list group headers all flip together — the comparison is
 * only fair if every section header on the screen changes at once.
 */
export function SectionTitle(props: { children: JSX.Element; style?: JSX.CSSProperties }) {
  return (
    <span
      role="heading"
      aria-level={2}
      style={{
        font: 'var(--section-font)',
        'text-transform': 'var(--section-transform)',
        'letter-spacing': 'var(--section-tracking)',
        color: 'var(--section-color)',
        ...props.style,
      }}
    >
      {props.children}
    </span>
  )
}

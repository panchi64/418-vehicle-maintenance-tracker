/*
 * DepthDisclosure — the "More details" row that holds what makes an entry
 * COMPLETE rather than what makes it WORK (Decision rule 5).
 *
 * Extracted on its second use (service form, appointment form). The collapsed
 * row names its contents in a tertiary summary, so nothing hidden is a
 * surprise: an accent 15 trigger over a 13 summary, a heading-size chevron,
 * and a rule beneath, 54pt tall.
 */
import type { JSX } from 'solid-js'
import { createSignal, Show } from 'solid-js'
import { Body, Secondary } from './Text'

export function DepthDisclosure(props: {
  /** Shown only while collapsed: what is inside, with current values. */
  summary: string
  initiallyOpen?: boolean
  children: JSX.Element
}) {
  const [open, setOpen] = createSignal(props.initiallyOpen ?? false)

  return (
    <div>
      <button
        onClick={() => setOpen(!open())}
        aria-expanded={open()}
        style={{
          display: 'flex',
          'align-items': 'center',
          gap: 'var(--space-sm)',
          width: '100%',
          'min-height': '54px',
          'border-bottom': 'var(--border-width) solid var(--grid-line)',
        }}
      >
        <div style={{ display: 'flex', 'flex-direction': 'column', gap: '2px', flex: '1 1 auto', 'min-width': '0' }}>
          <Body color="accent">{open() ? 'Fewer details' : 'More details'}</Body>
          <Show when={!open()}>
            <Secondary color="tertiary" lines={1} as="div">
              {props.summary}
            </Secondary>
          </Show>
        </div>
        <span
          aria-hidden="true"
          style={{
            font: 'var(--font-heading)',
            color: 'var(--accent)',
            transform: open() ? 'rotate(180deg)' : 'none',
            transition: 'transform var(--anim-medium) ease-out',
          }}
        >
          ⌄
        </span>
      </button>

      <Show when={open()}>
        <div
          style={{
            display: 'flex',
            'flex-direction': 'column',
            gap: 'var(--space-md)',
            'padding-top': 'var(--space-md)',
            animation: 'fade-in var(--anim-medium) ease-out',
          }}
        >
          {props.children}
        </div>
      </Show>
    </div>
  )
}

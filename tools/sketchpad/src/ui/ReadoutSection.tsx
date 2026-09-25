/*
 * ReadoutSection — the section shell every readout uses.
 *
 * Mirrors Views/Components/Cards/ReadoutSection.swift, including the part that
 * matters most: `primary` is a required slot. You cannot construct a section
 * without deciding what its most important element is. That makes "one primary
 * per section" the path of least resistance instead of a convention to remember.
 */
import type { JSX } from 'solid-js'
import { Show } from 'solid-js'
import { Label, SectionTitle, Secondary } from './Text'

interface ReadoutSectionProps {
  title: string
  /** The single most important element. Required by design. */
  primary: JSX.Element
  /** Supporting content, which must recede from `primary`. */
  supporting?: JSX.Element
  action?: { label: string; onClick?: () => void }
  /** A quiet trailing value on the header line, e.g. a month's total. */
  trailing?: string
  /** Set when the section should read as a discrete card rather than open flow. */
  enclosed?: boolean
}

export function ReadoutSection(props: ReadoutSectionProps) {
  return (
    <section
      data-section={props.title}
      style={{
        display: 'flex',
        'flex-direction': 'column',
        gap: 'var(--space-sm)',
        padding: props.enclosed ? 'var(--card-padding)' : undefined,
        border: props.enclosed ? 'var(--border-width) solid var(--border-subtle)' : undefined,
        background: props.enclosed ? 'var(--surface-instrument)' : undefined,
      }}
    >
      <header
        style={{
          display: 'flex',
          'align-items': 'center',
          'justify-content': 'space-between',
          gap: 'var(--space-sm)',
          'min-height': '20px',
        }}
      >
        <SectionTitle>{props.title}</SectionTitle>
        <Show when={props.trailing}>
          <Secondary color="tertiary" style={{ 'margin-left': 'auto' }}>
            {props.trailing}
          </Secondary>
        </Show>
        <Show when={props.action}>
          {(action) => (
            <button
              onClick={action().onClick}
              style={{
                display: 'flex',
                'align-items': 'center',
                'min-height': 'var(--touch-target)',
                // Negative margin so the 44pt target doesn't inflate the header.
                margin: 'calc((var(--touch-target) - 20px) / -2) 0',
              }}
            >
              <Label color="accent" tracking={1}>
                [{action().label}]
              </Label>
            </button>
          )}
        </Show>
      </header>

      <div data-slot="primary">{props.primary}</div>

      <Show when={props.supporting}>
        <div data-slot="supporting">{props.supporting}</div>
      </Show>
    </section>
  )
}

/*
 * OptionList — the dropdown panel shared by FilterControl and InlinePicker.
 *
 * Extracted on the second use rather than the third. The two triggers differ
 * (a filter names its dimension, a form field shows its value) but the list they
 * open is the same object, and two copies would drift.
 */
import { For, Show } from 'solid-js'
import { Body, Secondary } from './Text'

export interface Option<T extends string> {
  value: T
  label: string
  count?: number
}

export function OptionList<T extends string>(props: {
  options: Option<T>[]
  value: T
  onChange: (value: T) => void
  /** Which edge to anchor to, so the panel never hangs off the screen. */
  align?: 'left' | 'right'
}) {
  return (
    <div
      role="listbox"
      style={{
        position: 'absolute',
        'z-index': '10',
        top: '100%',
        left: props.align === 'left' ? '0' : undefined,
        right: props.align === 'left' ? undefined : '0',
        'min-width': '190px',
        border: 'var(--border-width) solid var(--accent)',
        background: 'var(--background-elevated)',
        animation: 'fade-in var(--anim-fast) ease-out',
      }}
    >
      <For each={props.options}>
        {(option, i) => {
          const selected = () => option.value === props.value
          return (
            <button
              role="option"
              aria-selected={selected()}
              onClick={() => props.onChange(option.value)}
              style={{
                display: 'flex',
                'align-items': 'center',
                gap: 'var(--space-md)',
                width: '100%',
                'min-height': 'var(--touch-target)',
                padding: '0 var(--space-md)',
                'border-top': i() > 0 ? '1px solid var(--grid-line)' : undefined,
                background: selected() ? 'var(--background-subtle)' : 'transparent',
              }}
            >
              {/* Selection is a rule plus weight, not color alone. */}
              <div
                aria-hidden="true"
                style={{
                  width: '2px',
                  'align-self': 'stretch',
                  background: selected() ? 'var(--accent)' : 'transparent',
                }}
              />
              <Body
                color={selected() ? 'primary' : 'secondary'}
                style={{ flex: '1 1 auto', 'text-align': 'left' }}
              >
                {option.label}
              </Body>
              <Show when={option.count != null}>
                <Secondary color="tertiary">{option.count}</Secondary>
              </Show>
            </button>
          )
        }}
      </For>
    </div>
  )
}

/** Dismiss layer, so tapping away closes the list instead of trapping the user. */
export function Backdrop(props: { onClick: () => void }) {
  return (
    <div onClick={props.onClick} style={{ position: 'fixed', inset: '0', 'z-index': '9' }} />
  )
}

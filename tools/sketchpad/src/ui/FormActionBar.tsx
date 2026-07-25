/*
 * FormActionBar — the single save affordance for every form (invariant F1).
 *
 * Mirrors Views/Components/Inputs/FormActionBar.swift.
 *
 * NOTE ON WHAT THIS CANNOT PROVE: invariant F3 ("the bar never rides above the
 * keyboard") is untestable here. A browser has no software keyboard, so the
 * sketchpad will always show this bar behaving correctly even for a layout that
 * would break on device. Keyboard avoidance, Dynamic Type reflow past the
 * largest sizes, and VoiceOver order must be verified in the Simulator. See
 * CLAUDE.md, "What the sketchpad cannot answer".
 */
import { Show } from 'solid-js'
import { Emphasis, Secondary } from './Text'

interface FormActionBarProps {
  label: string
  enabled: boolean
  /**
   * Why save is unavailable. Required whenever `enabled` is false (invariant
   * F2): a disabled control with no stated reason is a dead end, so the
   * component makes the explanation non-optional in practice.
   */
  disabledReason?: string
  onSave?: () => void
  onCancel?: () => void
}

export function FormActionBar(props: FormActionBarProps) {
  return (
    <div
      style={{
        display: 'flex',
        'flex-direction': 'column',
        gap: 'var(--space-sm)',
        padding: 'var(--space-md) var(--space-screen-h)',
        'padding-bottom': 'var(--space-lg)',
        'border-top': 'var(--border-width) solid var(--grid-line)',
        background: 'var(--background-primary)',
      }}
    >
      <Show when={!props.enabled && props.disabledReason}>
        <Secondary color="tertiary">{props.disabledReason}</Secondary>
      </Show>

      <div style={{ display: 'flex', gap: 'var(--space-sm)' }}>
        <Show when={props.onCancel}>
          <button
            onClick={props.onCancel}
            style={{
              'min-height': 'var(--button-height)',
              padding: '0 var(--space-lg)',
              border: 'var(--border-width) solid var(--border-subtle)',
              display: 'flex',
              'align-items': 'center',
            }}
          >
            <Emphasis color="secondary">Cancel</Emphasis>
          </button>
        </Show>

        <button
          onClick={() => props.enabled && props.onSave?.()}
          aria-disabled={!props.enabled}
          style={{
            flex: '1 1 auto',
            'min-height': 'var(--button-height)',
            display: 'flex',
            'align-items': 'center',
            'justify-content': 'center',
            border: `var(--border-width) solid ${
              props.enabled ? 'var(--accent)' : 'var(--border-subtle)'
            }`,
            background: props.enabled ? 'var(--accent)' : 'transparent',
            cursor: props.enabled ? 'pointer' : 'not-allowed',
            transition: 'background var(--anim-fast) ease-out',
          }}
        >
          <Emphasis
            style={{
              color: props.enabled ? 'var(--background-primary)' : 'var(--text-tertiary)',
            }}
            uppercase
            tracking={1}
          >
            {props.label}
          </Emphasis>
        </button>
      </div>
    </div>
  )
}

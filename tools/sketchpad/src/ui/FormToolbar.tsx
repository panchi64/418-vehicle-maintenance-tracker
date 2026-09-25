/*
 * FormToolbar — where Save lives on every form (replaces FormActionBar; F1).
 *
 * Stand-in for a sheet's NavigationStack toolbar: Cancel leading
 * (`.cancellationAction`), a prominent Save trailing (`.confirmationAction`,
 * `.buttonStyle(.glassProminent)` on iOS 26), title + subtitle centred
 * (`.navigationTitle` / `.navigationSubtitle`). The sketchpad does not model
 * system chrome, so this is deliberately plain — it exists to give the form
 * its real vertical budget and to put Save where the port will put it.
 *
 * WHY THE BOTTOM BAR WENT. FormActionBar was a 48pt bar plus padding pinned
 * above the home indicator: ~96pt of every form spent on one button, and it
 * had to hide itself behind the keyboard (F3) precisely because it would
 * otherwise eat number-pad space. The toolbar costs no content height, never
 * collides with the keyboard (so F3 is satisfied by construction rather than by
 * `KeyboardVisibility`), and is where every iOS sheet puts its confirm action,
 * so it needs no learning. Save is still in the same place on every surface —
 * F1's actual promise — just a different, platform-standard place.
 *
 * F2 STILL HOLDS. A disabled Save is drawn dim but stays TAPPABLE: the tap
 * calls `onBlocked`, and the form scrolls to the field that blocks it and shows
 * the reason there. PORT NOTE: do not use `.disabled(true)` — a disabled
 * SwiftUI button swallows the tap, which is the dead end F2 exists to prevent.
 * Style it dim, keep it hit-testable, fire the error haptic + scroll in its
 * action.
 */
import { Show } from 'solid-js'
import { Body, Emphasis, Secondary } from './Text'

/**
 * F2's scroll half. Forms tag each field that can block saving with
 * `data-blocker="<key>"`; this brings the named one to the middle of the sheet.
 */
export function revealBlocker(root: HTMLElement | undefined, key: string) {
  root
    ?.querySelector(`[data-blocker="${key}"]`)
    ?.scrollIntoView({ block: 'center', behavior: 'smooth' })
}

interface FormToolbarProps {
  title: string
  /** Identity of what the form writes to — the vehicle, on service forms. */
  subtitle?: string
  saveLabel?: string
  canSave: boolean
  onSave?: () => void
  /** F2: a tap on a dim Save. The form scrolls to the blocking field. */
  onBlocked?: () => void
  onCancel?: () => void
}

export function FormToolbar(props: FormToolbarProps) {
  return (
    <div
      style={{
        display: 'grid',
        'grid-template-columns': '1fr auto 1fr',
        'align-items': 'center',
        gap: 'var(--space-sm)',
        'min-height': '56px',
        padding: 'var(--space-xs) var(--space-md)',
        'border-bottom': '1px solid var(--grid-line)',
        background: 'var(--background-elevated)',
      }}
    >
      <button
        onClick={props.onCancel}
        style={{ 'min-height': 'var(--touch-target)', 'justify-self': 'start' }}
      >
        <Body color="secondary">Cancel</Body>
      </button>

      <div
        style={{
          display: 'flex',
          'flex-direction': 'column',
          'align-items': 'center',
          'text-align': 'center',
          'min-width': '0',
        }}
      >
        <Emphasis lines={1} as="div">
          {props.title}
        </Emphasis>
        <Show when={props.subtitle}>
          <Secondary color="tertiary" lines={1} as="div">
            {props.subtitle}
          </Secondary>
        </Show>
      </div>

      <button
        onClick={() => (props.canSave ? props.onSave?.() : props.onBlocked?.())}
        aria-disabled={!props.canSave}
        data-save
        style={{
          'justify-self': 'end',
          'min-height': 'var(--touch-target)',
          'min-width': '72px',
          padding: '0 var(--space-md)',
          display: 'flex',
          'align-items': 'center',
          'justify-content': 'center',
          border: `var(--border-width) solid ${props.canSave ? 'var(--accent)' : 'var(--border-subtle)'}`,
          background: props.canSave ? 'var(--accent)' : 'transparent',
          transition: 'background var(--anim-fast) ease-out',
        }}
      >
        <Emphasis
          style={{
            color: props.canSave ? 'var(--background-primary)' : 'var(--text-tertiary)',
            'white-space': 'nowrap',
          }}
        >
          {props.saveLabel ?? 'Save'}
        </Emphasis>
      </button>
    </div>
  )
}

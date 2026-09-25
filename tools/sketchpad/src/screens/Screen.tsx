/*
 * Screen — the scroll container each tab's content sits in.
 *
 * Owns the bottom clearance. The tab bar stand-in now sits in flow below this
 * container (as the system bar's safe-area inset does), so only breathing room
 * is added here — the old floating-bar clearance double-counted it.
 */
import type { JSX } from 'solid-js'

export function Screen(props: { children: JSX.Element; center?: boolean }) {
  return (
    <div
      style={{
        flex: '1 1 auto',
        'min-height': '0',
        'overflow-y': 'auto',
        // Lets Hero shrink-to-fit against the screen width (22cqi).
        'container-type': 'inline-size',
        display: 'flex',
        'flex-direction': 'column',
        gap: 'var(--space-lg)',
        padding: 'var(--space-md) var(--space-screen-h)',
        'padding-bottom': 'var(--space-xl)',
        'justify-content': props.center ? 'center' : undefined,
        'align-items': props.center ? 'center' : undefined,
      }}
    >
      {props.children}
    </div>
  )
}

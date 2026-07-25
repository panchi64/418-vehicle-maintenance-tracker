/*
 * Screen — the scroll container each tab's content sits in.
 *
 * Owns the bottom clearance for the floating tab bar. That clearance is a real
 * bug source: content and empty states have both clipped behind the bar, so it
 * belongs in one place rather than being re-added per screen.
 */
import type { JSX } from 'solid-js'

export function Screen(props: { children: JSX.Element; center?: boolean }) {
  return (
    <div
      style={{
        flex: '1 1 auto',
        'min-height': '0',
        'overflow-y': 'auto',
        display: 'flex',
        'flex-direction': 'column',
        gap: 'var(--space-lg)',
        padding: 'var(--space-md) var(--space-screen-h)',
        // Clearance for the tab bar, plus breathing room.
        'padding-bottom': 'calc(var(--tab-bar-height) + var(--space-lg))',
        'justify-content': props.center ? 'center' : undefined,
        'align-items': props.center ? 'center' : undefined,
      }}
    >
      {props.children}
    </div>
  )
}

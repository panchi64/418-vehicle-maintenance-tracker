/*
 * SiriTip — stand-in for the system's SiriTipView (App Intents), NOT a design.
 *
 * The question it answers is PLACEMENT, not look: where does the one tip a
 * screen gets go, so it never competes for the section's primary? The app
 * uses Apple's own view (rounded, system type — it is chrome, like the tab
 * bar), so this mimics it just enough to take up its real space.
 *
 * Resolved (Sep 2026): the tip is the LAST thing in the scroll, outside
 * every section. It carries no rank, so the one-primary audit ignores it;
 * above the content it would be the first thing read on every visit, and it
 * is the least important thing on the screen. It shows only once the screen
 * has something the phrase acts on, and its × dismisses it for good.
 */
import { createSignal, Show } from 'solid-js'

export function SiriTip(props: { phrase: string }) {
  const [visible, setVisible] = createSignal(true)
  return (
    <Show when={visible()}>
      <div
        aria-label="Siri tip"
        style={{
          display: 'flex',
          'align-items': 'center',
          gap: '12px',
          padding: '12px 14px',
          'border-radius': '14px',
          background: 'var(--grid-line)',
          'font-family': '-apple-system, system-ui, sans-serif',
          'font-size': '15px',
          color: 'var(--text-primary)',
        }}
      >
        <span aria-hidden="true" style={{ 'font-size': '22px' }}>◉</span>
        <span style={{ flex: '1 1 auto', 'min-width': '0' }}>
          Try saying <strong>“{props.phrase}”</strong>
        </span>
        <button
          aria-label="Dismiss tip"
          onClick={() => setVisible(false)}
          style={{ 'min-width': '44px', 'min-height': '44px', color: 'var(--text-tertiary)' }}
        >
          ×
        </button>
      </div>
    </Show>
  )
}

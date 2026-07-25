/*
 * BrutalistTabBar.
 *
 * Note the [+] is a SINGLE action here, not the two-way LOG / SCHEDULE expansion
 * that ships today. Phase 4 deletes that fork: the timing the user picks derives
 * the intent, so the tab bar no longer has to ask which kind of thing they are
 * adding. The sketchpad shows the target, not the current state — that is what
 * it is for.
 */
import { For } from 'solid-js'
import { Label } from '../ui/Text'

export type TabId = 'home' | 'services' | 'costs'

const TABS: { id: TabId; label: string }[] = [
  { id: 'home', label: 'Home' },
  { id: 'services', label: 'Services' },
  { id: 'costs', label: 'Costs' },
]

export function TabBar(props: {
  selected: TabId
  onSelect: (id: TabId) => void
  onAdd?: () => void
}) {
  return (
    <nav
      style={{
        display: 'flex',
        'align-items': 'center',
        gap: 'var(--space-sm)',
        height: 'var(--tab-bar-height)',
        padding: '0 var(--space-screen-h)',
        'border-top': 'var(--border-width) solid var(--grid-line)',
        background: `color-mix(in srgb, var(--background-elevated) 88%, transparent)`,
        'backdrop-filter': 'blur(12px)',
      }}
    >
      <For each={TABS}>
        {(tab) => {
          const selected = () => props.selected === tab.id
          return (
            <button
              onClick={() => props.onSelect(tab.id)}
              aria-current={selected() ? 'page' : undefined}
              style={{
                flex: '1 1 0',
                display: 'flex',
                'flex-direction': 'column',
                'align-items': 'center',
                'justify-content': 'center',
                gap: 'var(--space-xs)',
                'min-height': 'var(--touch-target)',
              }}
            >
              <Label color={selected() ? 'accent' : 'tertiary'} tracking={1}>
                {tab.label}
              </Label>
              {/* Selection is marked by a rule as well as by color. */}
              <div
                aria-hidden="true"
                style={{
                  width: '16px',
                  height: '2px',
                  background: selected() ? 'var(--accent)' : 'transparent',
                }}
              />
            </button>
          )
        }}
      </For>

      <button
        onClick={props.onAdd}
        aria-label="Add a service"
        style={{
          flex: '0 0 auto',
          width: 'var(--touch-target)',
          height: 'var(--touch-target)',
          display: 'flex',
          'align-items': 'center',
          'justify-content': 'center',
          border: 'var(--border-width) solid var(--accent)',
          background: 'var(--accent)',
        }}
      >
        <span
          style={{
            font: 'var(--font-heading)',
            color: 'var(--background-primary)',
            'line-height': '1',
          }}
        >
          +
        </span>
      </button>
    </nav>
  )
}

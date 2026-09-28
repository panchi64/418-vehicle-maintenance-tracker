/*
 * Regular-width shell — stand-in for `TabView { … }.tabViewStyle(.sidebarAdaptable)`.
 *
 * Like TabBar.tsx this is NOT a design: the system draws the sidebar. It
 * exists so regular-width screens are laid out inside their real horizontal
 * budget.
 *
 * DOCKED ONLY WHERE IT LEAVES ROOM FOR LIST | DETAIL. An always-docked 260pt
 * sidebar left the Duo's inner display (669pt) 409pt of content — a list
 * column plus a 75pt detail — and put the fold through the middle of the list.
 * iPad 11" portrait (834) fared little better. So the sidebar docks at
 * ≥ SIDEBAR_DOCK_MIN_WIDTH (iPad 13" landscape) and is otherwise collapsed
 * behind a leading toolbar button, opening as an overlay — what
 * NavigationSplitView's automatic column visibility does in iPad portrait.
 *
 * When docked, the sidebar header carries the vehicle name and switcher, so
 * the content columns' large titles fall back to the tab name.
 */
import { createContext, For, Show, useContext, type JSX } from 'solid-js'
import { Body, Heading, Label } from '../ui/Text'
import { SIDEBAR_WIDTH } from '../layout/sizeClass'
import { TABS, type TabId } from '../layout/tabs'

export interface SidebarState {
  /** Beside the content, always visible. */
  docked: boolean
  /** Collapsed: the toolbar toggle opens it as an overlay. */
  onToggle?: () => void
}

const SidebarContext = createContext<() => SidebarState | undefined>(() => undefined)
export const useSidebar = () => useContext(SidebarContext)

function SidebarList(props: { vehicleTitle: string; selected: TabId; onSelect: (tab: TabId) => void }) {
  return (
    <nav
      aria-label="Sidebar"
      style={{
        display: 'flex',
        'flex-direction': 'column',
        gap: 'var(--space-xs)',
        width: `${SIDEBAR_WIDTH}px`,
        height: '100%',
        padding: 'var(--space-md) var(--space-sm)',
        background: 'var(--background-elevated)',
        'border-right': '1px solid var(--grid-line)',
      }}
    >
      <button
        aria-label="Switch vehicle"
        style={{
          display: 'flex',
          'align-items': 'baseline',
          gap: 'var(--space-sm)',
          'min-height': 'var(--touch-target)',
          padding: '0 var(--space-sm)',
          'margin-bottom': 'var(--space-sm)',
          'text-align': 'left',
        }}
      >
        <Heading lines={2} as="div" style={{ 'min-width': '0' }}>
          {props.vehicleTitle}
        </Heading>
        <span aria-hidden="true" style={{ font: 'var(--font-heading)', color: 'var(--accent)' }}>
          ⌄
        </span>
      </button>
      <For each={TABS}>
        {(tab) => {
          const selected = () => props.selected === tab.id
          return (
            <button
              onClick={() => props.onSelect(tab.id)}
              aria-current={selected() ? 'page' : undefined}
              style={{
                display: 'flex',
                'align-items': 'center',
                'min-height': 'var(--touch-target)',
                padding: '0 var(--space-sm)',
                background: selected() ? 'var(--background-subtle)' : 'transparent',
              }}
            >
              <Body color={selected() ? 'accent' : 'secondary'}>{tab.label}</Body>
            </button>
          )
        }}
      </For>
    </nav>
  )
}

export function RegularShell(props: {
  vehicleTitle: string
  selected: TabId
  onSelect: (tab: TabId) => void
  docked: boolean
  open: boolean
  onOpenChange: (open: boolean) => void
  children: JSX.Element
}) {
  const state = (): SidebarState => ({
    docked: props.docked,
    onToggle: props.docked ? undefined : () => props.onOpenChange(!props.open),
  })

  return (
    <SidebarContext.Provider value={state}>
      <div style={{ position: 'relative', display: 'flex', flex: '1 1 auto', 'min-height': '0' }}>
        <Show when={props.docked}>
          <SidebarList vehicleTitle={props.vehicleTitle} selected={props.selected} onSelect={props.onSelect} />
        </Show>
        <div style={{ display: 'flex', 'flex-direction': 'column', flex: '1 1 auto', 'min-width': '0' }}>
          {props.children}
        </div>
        <Show when={!props.docked && props.open}>
          <div
            aria-hidden="true"
            onClick={() => props.onOpenChange(false)}
            style={{ position: 'absolute', inset: '0', background: 'rgb(0 0 0 / 0.35)', 'z-index': '5' }}
          />
          <div style={{ position: 'absolute', top: '0', bottom: '0', left: '0', 'z-index': '6' }}>
            <SidebarList
              vehicleTitle={props.vehicleTitle}
              selected={props.selected}
              onSelect={(tab) => {
                props.onSelect(tab)
                props.onOpenChange(false)
              }}
            />
          </div>
        </Show>
      </div>
    </SidebarContext.Provider>
  )
}

/** The leading toolbar button that opens a collapsed sidebar. */
export function SidebarToggle() {
  const sidebar = useSidebar()
  return (
    <Show when={sidebar()?.onToggle}>
      {(toggle) => (
        <button
          onClick={toggle()}
          aria-label="Show sidebar"
          style={{
            'min-width': 'var(--touch-target)',
            height: 'var(--touch-target)',
            display: 'flex',
            'align-items': 'center',
            'justify-content': 'center',
          }}
        >
          <Label color="accent" tracking={0} style={{ font: 'var(--font-heading)' }}>
            ◧
          </Label>
        </button>
      )}
    </Show>
  )
}

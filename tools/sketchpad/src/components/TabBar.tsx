/*
 * System chrome stand-ins: status bar, a tab's navigation bar, and the tab bar.
 *
 * These are NOT designs. The iOS 26 shell is native — a system TabView (Home,
 * Services, Costs), a NavigationStack per tab with a LARGE TITLE that is the
 * vehicle's name and a title menu to switch vehicles, Settings as a leading
 * toolbar item, and one prominent [+] trailing. The sketchpad cannot render
 * Liquid Glass and should not try; these blocks exist so every screen is laid
 * out inside its real vertical budget:
 *
 *   status bar     54   (Dynamic Island devices)
 *   nav bar        44   leading ⚙, trailing [+]
 *   large title    52   vehicle name ⌄   (collapses on scroll — not modelled)
 *   ...content...
 *   tab bar        83   floating bar + home-indicator inset
 *
 * The [+] moved here from the old custom tab bar. On iOS 26 the tab bar is a
 * system control that should hold tabs only; an add action is a toolbar item,
 * and there is exactly one of it (Phase 4: no LOG / SCHEDULE fork).
 *
 * At regular width the tab bar is replaced by the sidebar (Sidebar.tsx);
 * NavBar then gains the leading sidebar toggle and, while the sidebar is
 * docked, drops its vehicle menu to it.
 */
import { createSignal, For, Show } from 'solid-js'
import { Body, Label, Title } from '../ui/Text'
import { Backdrop, OptionList } from '../ui/OptionList'
import { vehicles } from '../data/fixtures'
import { TABS, type TabId } from '../layout/tabs'
import { SidebarToggle, useSidebar } from './Sidebar'

export type { TabId }

export function StatusBar() {
  return <div aria-hidden="true" style={{ height: '54px', flex: '0 0 auto' }} />
}

/** A plain bar button: 44pt target, text or glyph. */
function BarButton(props: { label: string; glyph?: string; prominent?: boolean; onClick?: () => void }) {
  return (
    <button
      onClick={props.onClick}
      aria-label={props.label}
      style={{
        'min-width': 'var(--touch-target)',
        height: 'var(--touch-target)',
        display: 'flex',
        'align-items': 'center',
        'justify-content': 'center',
        padding: props.glyph ? '0' : '0 var(--space-sm)',
        background: props.prominent ? 'var(--accent)' : 'transparent',
      }}
    >
      <Show when={props.glyph} fallback={<Body color="accent">{props.label}</Body>}>
        <span
          style={{
            font: 'var(--font-heading)',
            'line-height': '1',
            color: props.prominent ? 'var(--background-primary)' : 'var(--text-secondary)',
          }}
        >
          {props.glyph}
        </span>
      </Show>
    </button>
  )
}

export function NavBar(props: {
  title: string
  onAdd?: () => void
  onSettings?: () => void
  /** Extra trailing text item before [+], e.g. `Select` on Services. */
  extra?: { label: string; onClick: () => void }
  /** Stand-in for `.searchable` — rendered under the large title. */
  search?: string
}) {
  const [menuOpen, setMenuOpen] = createSignal(false)
  // Docked sidebar owns the vehicle switcher; the title is then the tab name.
  const sidebar = useSidebar()
  const hasMenu = () => !sidebar()?.docked

  return (
    <div style={{ flex: '0 0 auto', background: 'var(--background-primary)' }}>
      <div
        style={{
          display: 'flex',
          'align-items': 'center',
          gap: 'var(--space-xs)',
          height: '44px',
          padding: '0 var(--space-sm)',
        }}
      >
        <SidebarToggle />
        <BarButton label="Settings" glyph="⚙" onClick={props.onSettings} />
        <div style={{ flex: '1 1 auto' }} />
        <Show when={props.extra}>
          {(x) => <BarButton label={x().label} onClick={x().onClick} />}
        </Show>
        <BarButton label="Add" glyph="+" prominent onClick={props.onAdd} />
      </div>

      {/* Large title + title menu (`.toolbarTitleMenu`). */}
      <div class="vh-identity" style={{ position: 'relative', padding: '0 var(--space-screen-h)' }}>
        <button
          onClick={() => hasMenu() && setMenuOpen(!menuOpen())}
          aria-label={hasMenu() ? 'Switch vehicle' : undefined}
          style={{
            display: 'flex',
            'align-items': 'baseline',
            gap: 'var(--space-sm)',
            'min-height': '52px',
            'max-width': '100%',
          }}
        >
          <Title class="vh-name" lines={1} as="div" style={{ 'min-width': '0' }}>
            {props.title}
          </Title>
          <Show when={hasMenu()}>
            <span aria-hidden="true" style={{ font: 'var(--font-heading)', color: 'var(--accent)' }}>
              ⌄
            </span>
          </Show>
        </button>
        <Show when={menuOpen()}>
          <Backdrop onClick={() => setMenuOpen(false)} />
          <OptionList
            align="left"
            options={vehicles.map((v) => ({
              value: v.id,
              label: v.name || `${v.year} ${v.make} ${v.model}`,
            }))}
            value="v1"
            onChange={() => setMenuOpen(false)}
          />
        </Show>
      </div>

      <Show when={props.search}>
        <div style={{ padding: '0 var(--space-screen-h) var(--space-sm)' }}>
          <div
            style={{
              display: 'flex',
              'align-items': 'center',
              gap: 'var(--space-sm)',
              height: '36px',
              padding: '0 var(--space-sm)',
              background: 'var(--background-subtle)',
            }}
          >
            <Label tracking={0}>⌕</Label>
            <Body color="tertiary">{props.search}</Body>
          </div>
        </div>
      </Show>
    </div>
  )
}

/**
 * A pushed screen's bar (F13: details push): back leading, [+] trailing, a
 * large title that is the screen's name, and an optional `.searchable` field
 * whose input is live so a list can be filtered in the sketch.
 */
export function PushedNavBar(props: {
  title: string
  back: string
  onBack?: () => void
  onAdd?: () => void
  search?: { placeholder: string; value: string; onInput: (v: string) => void }
}) {
  return (
    <div style={{ flex: '0 0 auto', background: 'var(--background-primary)' }}>
      <div style={{ display: 'flex', 'align-items': 'center', height: '44px', padding: '0 var(--space-sm)' }}>
        <button
          onClick={props.onBack}
          style={{ 'min-height': 'var(--touch-target)', display: 'flex', 'align-items': 'center', gap: '2px' }}
        >
          <Body color="accent">‹ {props.back}</Body>
        </button>
        <div style={{ flex: '1 1 auto' }} />
        <Show when={props.onAdd}>
          <BarButton label="Add" glyph="+" prominent onClick={props.onAdd} />
        </Show>
      </div>
      <div style={{ padding: '0 var(--space-screen-h)', 'min-height': '52px', display: 'flex', 'align-items': 'center' }}>
        <Title lines={1} as="div">
          {props.title}
        </Title>
      </div>
      <Show when={props.search}>
        {(s) => (
          <div style={{ padding: '0 var(--space-screen-h) var(--space-sm)' }}>
            <div
              style={{
                display: 'flex',
                'align-items': 'center',
                gap: 'var(--space-sm)',
                height: '36px',
                padding: '0 var(--space-sm)',
                background: 'var(--background-subtle)',
              }}
            >
              <Label tracking={0}>⌕</Label>
              <input
                value={s().value}
                placeholder={s().placeholder}
                onInput={(e) => s().onInput(e.currentTarget.value)}
                style={{ flex: '1 1 auto', 'min-width': '0', font: 'var(--font-body)', color: 'var(--text-primary)' }}
              />
            </div>
          </div>
        )}
      </Show>
    </div>
  )
}

export function TabBar(props: { selected: TabId; onSelect: (id: TabId) => void }) {
  return (
    <nav
      style={{
        display: 'flex',
        'align-items': 'flex-start',
        height: '83px',
        'padding-top': 'var(--space-sm)',
        flex: '0 0 auto',
        'border-top': '1px solid var(--grid-line)',
        background: 'color-mix(in srgb, var(--background-elevated) 92%, transparent)',
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
                gap: 'var(--space-xs)',
                'min-height': 'var(--touch-target)',
                'justify-content': 'center',
              }}
            >
              <Label color={selected() ? 'accent' : 'tertiary'} tracking={1}>
                {tab.label}
              </Label>
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
    </nav>
  )
}

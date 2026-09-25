import { createEffect, createSignal, For, Match, onCleanup, Show, Switch } from 'solid-js'
import './styles/base.css'
import './harness/harness.css'

import { applyTheme, defaultTheme, systemAppearance, themes, type ColorScheme } from './theme/themes'
import { AuditPanel, useAudit } from './harness/Inspector'
import { VehicleHeader } from './components/VehicleHeader'
import { QuickSpecsPanel } from './components/Cards'
import { TabBar, type TabId } from './components/TabBar'
import { HomeEmpty, HomeTab } from './screens/HomeTab'
import { ServicesTab } from './screens/ServicesTab'
import { CostsTab } from './screens/CostsTab'
import { ServiceForm } from './screens/ServiceForm'
import { AddVehicle } from './screens/AddVehicle'
import { vehicle } from './data/fixtures'

type ScreenId = 'home' | 'home-empty' | 'services' | 'costs' | 'form' | 'vehicle'

interface ScreenDef {
  id: ScreenId
  label: string
  /** Sheets fill the frame; tabs sit inside the persistent shell. */
  sheet?: boolean
  /** Tap budget from the doctrine's acceptance tests, where one applies. */
  budget?: number
}

const SCREENS: ScreenDef[] = [
  { id: 'home', label: 'Home' },
  { id: 'home-empty', label: 'Home — empty state' },
  { id: 'services', label: 'Services' },
  { id: 'costs', label: 'Costs' },
  { id: 'form', label: 'Add service — unified form', sheet: true, budget: 6 },
  { id: 'vehicle', label: 'Add vehicle', sheet: true, budget: 8 },
]

const DEVICES = [
  { id: 'se', label: 'iPhone SE — 375×667', w: 375, h: 667 },
  { id: '17', label: 'iPhone 17 — 393×852', w: 393, h: 852 },
  { id: '17pm', label: 'iPhone 17 Pro Max — 440×956', w: 440, h: 956 },
] as const

export function App() {
  const [themeId, setThemeId] = createSignal(defaultTheme.id)
  // Starts from the browser's own setting, as the app starts from the system's.
  const initialAppearance = systemAppearance()
  const [scheme, setScheme] = createSignal<ColorScheme>(initialAppearance.scheme)
  const [highContrast, setHighContrast] = createSignal(initialAppearance.highContrast)
  const [deviceId, setDeviceId] = createSignal<(typeof DEVICES)[number]['id']>('17')
  const [screen, setScreen] = createSignal<ScreenId>('home')
  const [tab, setTab] = createSignal<TabId>('home')
  const [typeScale, setTypeScale] = createSignal(1)
  const [squint, setSquint] = createSignal(false)
  const [showRanks, setShowRanks] = createSignal(false)
  const [showSections, setShowSections] = createSignal(false)
  const [specsExpanded, setSpecsExpanded] = createSignal(false)
  const [taps, setTaps] = createSignal(0)

  let frameRef: HTMLDivElement | undefined

  const theme = () => themes.find((t) => t.id === themeId()) ?? defaultTheme
  const device = () => DEVICES.find((d) => d.id === deviceId()) ?? DEVICES[1]
  const current = () => SCREENS.find((s) => s.id === screen()) ?? SCREENS[0]

  // Theme and type scale live on :root, matching how Swift resolves colors
  // through ThemeManager at render time rather than baking them into views.
  createEffect(() => {
    applyTheme(theme(), { scheme: scheme(), highContrast: highContrast() })
    document.documentElement.style.setProperty('--type-scale', String(typeScale()))
  })

  const auditRows = useAudit(
    () => frameRef,
    () => showRanks() || showSections(),
  )

  // Scale the frame down when the window is shorter than the device, so the
  // whole screen stays visible. Judging a layout while its top and bottom are
  // scrolled out of view is how you miss that something clips behind the tab bar.
  const [viewportH, setViewportH] = createSignal(window.innerHeight)
  const onResize = () => setViewportH(window.innerHeight)
  window.addEventListener('resize', onResize)
  onCleanup(() => window.removeEventListener('resize', onResize))

  const fit = () => Math.min(1, (viewportH() - 56) / device().h)

  const goToScreen = (id: ScreenId) => {
    setScreen(id)
    setTaps(0)
    if (id === 'home' || id === 'home-empty') setTab('home')
    if (id === 'services') setTab('services')
    if (id === 'costs') setTab('costs')
  }

  const selectTab = (id: TabId) => {
    setTab(id)
    setScreen(id === 'home' ? 'home' : id === 'services' ? 'services' : 'costs')
  }

  return (
    <div class="hz">
      <aside class="hz-panel">
        <div class="hz-brand">Checkpoint Sketchpad</div>

        <div class="hz-group">
          <label for="hz-screen">Screen</label>
          <div class="hz-screens" id="hz-screen">
            <For each={SCREENS}>
              {(s) => (
                <button aria-current={screen() === s.id} onClick={() => goToScreen(s.id)}>
                  {s.label}
                </button>
              )}
            </For>
          </div>
        </div>

        <div class="hz-group">
          <label for="hz-theme">Theme</label>
          <select
            id="hz-theme"
            value={themeId()}
            onChange={(e) => setThemeId(e.currentTarget.value)}
          >
            <For each={themes}>
              {(t) => (
                <option value={t.id}>
                  {t.displayName} — {t.fontDesign}
                </option>
              )}
            </For>
          </select>
          <p class="hz-hint">
            Eight ship. A layout is not verified until it holds in a non-monospaced theme.
          </p>
        </div>

        <div class="hz-group">
          <span class="hz-legend">Appearance</span>
          <div class="hz-segmented" role="radiogroup" aria-label="Appearance">
            <For each={['light', 'dark'] as const}>
              {(s) => (
                <button role="radio" aria-checked={scheme() === s} onClick={() => setScheme(s)}>
                  {s}
                </button>
              )}
            </For>
          </div>
          <label class="hz-check">
            <input
              type="checkbox"
              checked={highContrast()}
              onChange={(e) => setHighContrast(e.currentTarget.checked)}
            />
            Increase Contrast
          </label>
          <p class="hz-hint">
            The app follows the system appearance, and every theme ships all four. Check
            light and dark before calling a layout resolved.
          </p>
        </div>

        <div class="hz-group">
          <label for="hz-device">Device</label>
          <select
            id="hz-device"
            value={deviceId()}
            onChange={(e) => setDeviceId(e.currentTarget.value as (typeof DEVICES)[number]['id'])}
          >
            <For each={DEVICES}>{(d) => <option value={d.id}>{d.label}</option>}</For>
          </select>
        </div>

        <div class="hz-group">
          <label for="hz-scale">Dynamic Type — {typeScale().toFixed(2)}×</label>
          <input
            id="hz-scale"
            type="range"
            min="0.85"
            max="2"
            step="0.05"
            value={typeScale()}
            onInput={(e) => setTypeScale(parseFloat(e.currentTarget.value))}
          />
          <p class="hz-hint">
            Dynamic Type is a requirement, not a nicety. A layout that only survives at
            1.00× is not finished.
          </p>
        </div>

        <div class="hz-group">
          <span class="hz-legend">Inspect</span>
          <label class="hz-check">
            <input type="checkbox" checked={squint()} onChange={(e) => setSquint(e.currentTarget.checked)} />
            Squint test (blur)
          </label>
          <label class="hz-check">
            <input
              type="checkbox"
              checked={showRanks()}
              onChange={(e) => setShowRanks(e.currentTarget.checked)}
            />
            Outline declared ranks
          </label>
          <label class="hz-check">
            <input
              type="checkbox"
              checked={showSections()}
              onChange={(e) => setShowSections(e.currentTarget.checked)}
            />
            Outline sections
          </label>
          <p class="hz-hint">
            Blur it. If you cannot tell what the screen is for, the hierarchy is carried by
            the words rather than by the layout.
          </p>
        </div>

        <div class="hz-group">
          <span class="hz-legend">One primary per section</span>
          <Show
            when={showRanks() || showSections()}
            fallback={<p class="hz-hint">Enable an outline toggle above to run the audit.</p>}
          >
            <AuditPanel rows={auditRows()} />
          </Show>
        </div>

        <div class="hz-group">
          <span class="hz-legend">Tap budget</span>
          <div class="hz-taps">
            <output>{taps()}</output>
            <button onClick={() => setTaps(0)}>reset</button>
          </div>
          <Show
            when={current().budget}
            fallback={<p class="hz-hint">No budget defined for this screen.</p>}
          >
            <p class={`hz-budget ${taps() > current().budget! ? 'over' : ''}`}>
              Budget {current().budget} taps
              {taps() > current().budget! ? ` — over by ${taps() - current().budget!}` : ''}
            </p>
          </Show>
        </div>
      </aside>

      <main class="hz-stage">
        <div
          ref={frameRef}
          class="hz-device"
          data-squint={squint()}
          data-ranks={showRanks()}
          data-sections={showSections()}
          style={{
            width: `${device().w}px`,
            height: `${device().h}px`,
            transform: `scale(${fit()})`,
          }}
          onClick={() => setTaps((n) => n + 1)}
        >
          <div class="hz-app">
            <Switch>
              <Match when={current().sheet}>
                <Switch>
                  <Match when={screen() === 'form'}>
                    <ServiceForm onClose={() => goToScreen('home')} />
                  </Match>
                  <Match when={screen() === 'vehicle'}>
                    <AddVehicle onClose={() => goToScreen('home')} />
                  </Match>
                </Switch>
              </Match>

              <Match when={!current().sheet}>
                <VehicleHeader
                  vehicle={screen() === 'home-empty' ? undefined : vehicle}
                  specsExpanded={specsExpanded()}
                  onToggleSpecs={() => setSpecsExpanded(!specsExpanded())}
                  mileageStale
                />

                {/* Vehicle reference data hangs off the header rather than living
                    in Home's scroll flow: it is identity, not maintenance state,
                    and sitting in the shell makes it reachable from every tab. */}
                <Show when={specsExpanded() && screen() !== 'home-empty'}>
                  <QuickSpecsPanel vehicle={vehicle} />
                </Show>

                <Switch>
                  <Match when={screen() === 'home'}>
                    <HomeTab onNavigate={selectTab} />
                  </Match>
                  <Match when={screen() === 'home-empty'}>
                    <HomeEmpty onAdd={() => goToScreen('vehicle')} />
                  </Match>
                  <Match when={screen() === 'services'}>
                    <ServicesTab />
                  </Match>
                  <Match when={screen() === 'costs'}>
                    <CostsTab />
                  </Match>
                </Switch>

                <TabBar selected={tab()} onSelect={selectTab} onAdd={() => goToScreen('form')} />
              </Match>
            </Switch>
          </div>
        </div>
      </main>
    </div>
  )
}

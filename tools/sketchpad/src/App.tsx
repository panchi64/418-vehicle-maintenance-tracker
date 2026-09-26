import { createEffect, createSignal, For, Match, onCleanup, Show, Switch } from 'solid-js'
import './styles/base.css'
import './harness/harness.css'

import { applyTheme, defaultTheme, systemAppearance, themes, type ColorScheme } from './theme/themes'
import { AuditPanel, HistogramPanel, useAudit, useTypeHistogram } from './harness/Inspector'
import { StatusBar, TabBar, type TabId } from './components/TabBar'
import { HomeEmpty, HomeTab } from './screens/HomeTab'
import { ServicesTab } from './screens/ServicesTab'
import { CostsTab } from './screens/CostsTab'
import { ServiceForm, type FormMode } from './screens/ServiceForm'
import { AddVehicle } from './screens/AddVehicle'
import { ScenarioProvider, scenarios, type Scenario } from './data/scenario'
import type { Service, ServiceLog } from './data/fixtures'
import { sampleReceipt, type ReceiptDraft } from './data/receipt'
import { AppointmentForm } from './screens/AppointmentForm'
import { NotesList } from './screens/NotesList'
import { NoteSheet } from './screens/NoteSheet'
import { appointmentsFull, notesFull, type Appointment, type VehicleNote } from './data/visits'

/**
 * Where the frame is. Tabs sit inside the shell; forms and Add Vehicle are
 * sheets that fill it. Navigating INSIDE the frame (Mark Done, [+]) changes
 * the route without resetting the tap counter, so a flow's budget is counted
 * end to end from the screen it starts on.
 */
type Route =
  | { kind: 'tab'; tab: TabId }
  | { kind: 'form'; mode: FormMode; service?: Service; log?: ServiceLog; receipt?: ReceiptDraft }
  | { kind: 'vehicle' }
  | { kind: 'appointment'; appointment?: Appointment; preselect?: string; start?: Date }
  | { kind: 'notes' }
  | { kind: 'note'; note?: VehicleNote }

interface ScreenDef {
  id: string
  label: string
  scenario: Scenario['id']
  start: Route
  /** Tap budget from the doctrine's acceptance tests, where one applies. */
  budget?: number
  /** The default path the budget is measured along. */
  path?: string
  /** Open Home's specs panel on entry. */
  specs?: boolean
}

const SCREENS: ScreenDef[] = [
  { id: 'home', label: 'Home', scenario: 'full', start: { kind: 'tab', tab: 'home' } },
  { id: 'home-marbete', label: 'Home — marbete most urgent', scenario: 'marbete', start: { kind: 'tab', tab: 'home' } },
  { id: 'home-sparse', label: 'Home — sparse data', scenario: 'sparse', start: { kind: 'tab', tab: 'home' } },
  { id: 'home-fresh', label: 'Home — vehicle, no services', scenario: 'fresh', start: { kind: 'tab', tab: 'home' } },
  { id: 'home-empty', label: 'Home — no vehicle', scenario: 'empty', start: { kind: 'tab', tab: 'home' } },
  { id: 'services', label: 'Services', scenario: 'full', start: { kind: 'tab', tab: 'services' } },
  { id: 'services-empty', label: 'Services — empty', scenario: 'fresh', start: { kind: 'tab', tab: 'services' } },
  { id: 'costs', label: 'Costs', scenario: 'full', start: { kind: 'tab', tab: 'costs' } },
  { id: 'costs-sparse', label: 'Costs — sparse data', scenario: 'sparse', start: { kind: 'tab', tab: 'costs' } },
  {
    id: 'flow-done',
    label: 'Flow: mark Next Up done',
    scenario: 'full',
    start: { kind: 'tab', tab: 'home' },
    budget: 2,
    path: 'Mark Done → Save',
  },
  {
    id: 'flow-log',
    label: 'Flow: log oil change today + cost',
    scenario: 'full',
    start: { kind: 'tab', tab: 'home' },
    budget: 4,
    path: '[+] → Oil & Filter Change → Cost field (type) → Save',
  },
  {
    id: 'flow-schedule',
    label: 'Flow: schedule a future service',
    scenario: 'full',
    start: { kind: 'tab', tab: 'home' },
    budget: 4,
    path: '[+] → a service → Not done yet → Save',
  },
  {
    id: 'flow-receipt',
    label: 'Flow: log a service from a receipt',
    scenario: 'full',
    start: { kind: 'tab', tab: 'home' },
    budget: 3,
    path: '[+] → Scan a receipt → Save (+2 taps in the system camera: shutter, Save)',
  },
  {
    id: 'form-receipt',
    label: 'Form: opened from a receipt (Share / Visual Intelligence)',
    scenario: 'full',
    start: { kind: 'form', mode: 'log', receipt: sampleReceipt },
    budget: 1,
    path: 'Save — every value is already in its field, marked From receipt',
  },
  {
    id: 'form-edit',
    label: 'Form: edit a log',
    scenario: 'full',
    start: { kind: 'form', mode: 'edit', log: scenarios.full.logs[0] },
    budget: 3,
    path: 'Cost field (type) → Save; Save stays dim until something changes',
  },
  { id: 'vehicle', label: 'Add vehicle', scenario: 'full', start: { kind: 'vehicle' }, budget: 8 },
  // --- Shop visits -------------------------------------------------------
  {
    id: 'home-visit-today',
    label: 'Home — shop visit started 1 h ago, 4 services, +2',
    scenario: 'visitToday',
    start: { kind: 'tab', tab: 'home' },
  },
  {
    id: 'flow-book',
    label: 'Flow: book a shop visit from Home',
    scenario: 'full',
    start: { kind: 'tab', tab: 'home' },
    budget: 6,
    path: '[Book] → (Shop autofocused: type “toy”) → Toyota de Puerto Rico → Date field (type) → Save = 4; 3 if tomorrow 9:00 is right; 6 on device with a compact DatePicker (date, day, tap away).',
  },
  {
    id: 'form-appointment-edit',
    label: 'Form: edit a shop visit',
    scenario: 'full',
    start: { kind: 'appointment', appointment: appointmentsFull[0] },
  },
  {
    id: 'form-appointment-clash',
    label: 'Form: book on a day that already has a visit',
    scenario: 'full',
    start: { kind: 'appointment', start: new Date('2026-07-27T14:00:00') },
  },
  // --- Notes ---------------------------------------------------------------
  { id: 'home-specs', label: 'Home — specs open (Documents, Notes)', scenario: 'full', start: { kind: 'tab', tab: 'home' }, specs: true },
  { id: 'notes', label: 'Notes', scenario: 'full', start: { kind: 'notes' } },
  { id: 'notes-empty', label: 'Notes — none', scenario: 'visitToday', start: { kind: 'notes' } },
  {
    id: 'flow-note',
    label: 'Flow: add a pinned note with a photo',
    scenario: 'full',
    start: { kind: 'tab', tab: 'home' },
    budget: 6,
    path: 'Specs strip → Notes › → [+] → (title autofocused: type) → Pin → Add Photo or File → Save (+ system picker: source, shutter, Use Photo)',
  },
  { id: 'form-note-edit', label: 'Form: edit a note', scenario: 'full', start: { kind: 'note', note: notesFull[0] } },
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
  const [headers, setHeaders] = createSignal<'caps' | 'title'>('title')
  const [deviceId, setDeviceId] = createSignal<(typeof DEVICES)[number]['id']>('17')
  const [screenId, setScreenId] = createSignal('home')
  const [route, setRoute] = createSignal<Route>(SCREENS[0].start)
  const [typeScale, setTypeScale] = createSignal(1)
  const [squint, setSquint] = createSignal(false)
  const [showRanks, setShowRanks] = createSignal(false)
  const [showSections, setShowSections] = createSignal(false)
  const [revealActions, setRevealActions] = createSignal(false)
  const [specsExpanded, setSpecsExpanded] = createSignal(false)
  const [taps, setTaps] = createSignal(0)

  let frameRef: HTMLDivElement | undefined

  const theme = () => themes.find((t) => t.id === themeId()) ?? defaultTheme
  const device = () => DEVICES.find((d) => d.id === deviceId()) ?? DEVICES[1]
  const current = () => SCREENS.find((s) => s.id === screenId()) ?? SCREENS[0]
  const scenario = () => scenarios[current().scenario]

  // Theme, type scale, and the section-header style live on :root, matching how
  // Swift resolves them through ThemeManager at render time.
  createEffect(() => {
    applyTheme(theme(), { scheme: scheme(), highContrast: highContrast() })
    document.documentElement.style.setProperty('--type-scale', String(typeScale()))
    document.documentElement.dataset.largeType = String(typeScale() >= 1.5)
    document.documentElement.dataset.headers = headers()
  })

  const auditRows = useAudit(
    () => frameRef,
    () => showRanks() || showSections(),
  )
  const hist = useTypeHistogram(() => frameRef)

  const [viewportH, setViewportH] = createSignal(window.innerHeight)
  const onResize = () => setViewportH(window.innerHeight)
  window.addEventListener('resize', onResize)
  onCleanup(() => window.removeEventListener('resize', onResize))
  const fit = () => Math.min(1, (viewportH() - 56) / device().h)

  const goToScreen = (id: string) => {
    const def = SCREENS.find((s) => s.id === id) ?? SCREENS[0]
    setScreenId(def.id)
    setRoute({ ...def.start }) // a fresh object, so a keyed form remounts
    setSpecsExpanded(!!def.specs)
    setTaps(0)
  }

  // In-frame navigation: no tap reset.
  const home = () => setRoute({ kind: 'tab', tab: 'home' })
  const openAdd = () => setRoute({ kind: 'form', mode: 'log' })
  const vehicleTitle = () => {
    const v = scenario().vehicle
    return v ? v.name || `${v.year} ${v.make} ${v.model}` : 'Checkpoint'
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
                <button aria-current={screenId() === s.id} onClick={() => goToScreen(s.id)}>
                  {s.label}
                </button>
              )}
            </For>
          </div>
        </div>

        <div class="hz-group">
          <span class="hz-legend">Tap budget</span>
          <div class="hz-taps">
            <output>{taps()}</output>
            <button onClick={() => goToScreen(screenId())}>reset</button>
          </div>
          <Show
            when={current().budget}
            fallback={<p class="hz-hint">No budget defined for this screen.</p>}
          >
            <p class={`hz-budget ${taps() > current().budget! ? 'over' : ''}`}>
              Budget {current().budget} taps
              {taps() > current().budget! ? ` — over by ${taps() - current().budget!}` : ''}
            </p>
            <Show when={current().path}>
              <p class="hz-hint">{current().path}</p>
            </Show>
          </Show>
        </div>

        <div class="hz-group">
          <label for="hz-theme">Theme</label>
          <select id="hz-theme" value={themeId()} onChange={(e) => setThemeId(e.currentTarget.value)}>
            <For each={themes}>
              {(t) => (
                <option value={t.id}>
                  {t.displayName} — {t.fontDesign}
                </option>
              )}
            </For>
          </select>
          <p class="hz-hint">Eight ship. A layout is not verified until it holds in a non-monospaced theme.</p>
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
        </div>

        <div class="hz-group">
          <span class="hz-legend">Section headers</span>
          <div class="hz-segmented" role="radiogroup" aria-label="Section headers">
            <button role="radio" aria-checked={headers() === 'title'} onClick={() => setHeaders('title')}>
              Title Case
            </button>
            <button role="radio" aria-checked={headers() === 'caps'} onClick={() => setHeaders('caps')}>
              UPPERCASE
            </button>
          </div>
          <p class="hz-hint">
            Switches only the section tier. Status tags and metadata labels stay uppercase either way.
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
        </div>

        <div class="hz-group">
          <span class="hz-legend">Inspect</span>
          <label class="hz-check">
            <input type="checkbox" checked={squint()} onChange={(e) => setSquint(e.currentTarget.checked)} />
            Squint test (blur)
          </label>
          <label class="hz-check">
            <input type="checkbox" checked={showRanks()} onChange={(e) => setShowRanks(e.currentTarget.checked)} />
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
          <label class="hz-check">
            <input
              type="checkbox"
              checked={revealActions()}
              onChange={(e) => setRevealActions(e.currentTarget.checked)}
            />
            Reveal row actions (swipe stand-in)
          </label>
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
          <span class="hz-legend">Type distribution — {hist().total} text runs</span>
          <HistogramPanel hist={hist()} />
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
            <ScenarioProvider value={scenario}>
              <StatusBar />
              <Switch>
                {/* Keyed: each form route is a fresh form. Unkeyed, going from one
                    form route to another kept the first form's state. */}
                <Match when={route().kind === 'form' && (route() as Extract<Route, { kind: 'form' }>)} keyed>
                  {(r) => <ServiceForm mode={r.mode} service={r.service} log={r.log} receipt={r.receipt} onClose={home} />}
                </Match>

                <Match when={route().kind === 'vehicle'}>
                  <AddVehicle onClose={home} />
                </Match>

                <Match when={route().kind === 'appointment' && (route() as Extract<Route, { kind: 'appointment' }>)} keyed>
                  {(r) => (
                    <AppointmentForm
                      appointment={r.appointment}
                      preselectServiceId={r.preselect}
                      initialStart={r.start}
                      onClose={home}
                    />
                  )}
                </Match>

                <Match when={route().kind === 'note' && (route() as Extract<Route, { kind: 'note' }>)} keyed>
                  {(r) => <NoteSheet note={r.note} onClose={() => setRoute({ kind: 'notes' })} />}
                </Match>

                <Match when={route().kind === 'notes'}>
                  <NotesList
                    onBack={home}
                    onAdd={() => setRoute({ kind: 'note' })}
                    onOpen={(note) => setRoute({ kind: 'note', note })}
                    revealActions={revealActions()}
                  />
                  <TabBar selected="home" onSelect={(tab) => setRoute({ kind: 'tab', tab })} />
                </Match>

                <Match when={route().kind === 'tab' && (route() as Extract<Route, { kind: 'tab' }>)}>
                  {(r) => (
                    <>
                      <Switch>
                        <Match when={r().tab === 'home' && !scenario().vehicle}>
                          <HomeEmpty onAdd={() => setRoute({ kind: 'vehicle' })} />
                        </Match>
                        <Match when={r().tab === 'home'}>
                          <HomeTab
                            title={vehicleTitle()}
                            onAdd={openAdd}
                            onNavigate={(tab) => setRoute({ kind: 'tab', tab })}
                            onMarkDone={(service) => setRoute({ kind: 'form', mode: 'complete', service })}
                            onBook={(preselect) => setRoute({ kind: 'appointment', preselect })}
                            onEditAppointment={(appointment) => setRoute({ kind: 'appointment', appointment })}
                            onLogVisit={(a) => {
                              // Stand-in: the port's log form takes the whole visit
                              // (shop + every linked service); here, its first service.
                              const service = scenario().services.find((s) => s.id === a.serviceIds[0])
                              setRoute({ kind: 'form', mode: service ? 'complete' : 'log', service })
                            }}
                            onOpenNotes={() => setRoute({ kind: 'notes' })}
                            specsExpanded={specsExpanded()}
                            onToggleSpecs={() => setSpecsExpanded(!specsExpanded())}
                          />
                        </Match>
                        <Match when={r().tab === 'services'}>
                          <ServicesTab title={vehicleTitle()} onAdd={openAdd} revealActions={revealActions()} />
                        </Match>
                        <Match when={r().tab === 'costs'}>
                          <CostsTab title={vehicleTitle()} onAdd={openAdd} />
                        </Match>
                      </Switch>
                      <TabBar selected={r().tab} onSelect={(tab) => setRoute({ kind: 'tab', tab })} />
                    </>
                  )}
                </Match>
              </Switch>
            </ScenarioProvider>
          </div>
        </div>
      </main>
    </div>
  )
}

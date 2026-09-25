/*
 * Home — Readout. "What does this car need from me, and can I do it now?"
 *
 * FIXED ORDER, ALWAYS THE SAME FIVE BLOCKS (Readout rule 2):
 *
 *   0. Vehicle band      odometer (tap → update; stale tag) | specs ⌄
 *   1. Next up           THE hero: status word, remaining figure, due line,
 *                        and a primary MARK DONE. The marbete takes this slot
 *                        when it is the most urgent item.
 *   2. Suggestions       at most ONE item — the cluster ("do X on the same
 *                        visit") and seasonal suggestions used to be separate
 *                        sections that could both show; they share one slot,
 *                        and the more actionable wins it.
 *   3. Upcoming          the next 3 after Next Up, dense two-line rows
 *   4. Recent            the last 3 logs
 *
 * What was removed, and why:
 *   - The odometer caution ADVISORY above the hero. It pushed the hero down
 *     on exactly the days a stale reading made the hero least trustworthy,
 *     and it was a warning rendered away from the control that resolves it.
 *     The stale tag now sits ON the odometer cell, which is that control.
 *   - "Miles this year". A genuinely interesting stat that answered no
 *     question Home is for; it belongs with Costs or vehicle detail.
 *
 * SPARSE DATA never removes a section and never renders an apology card: an
 * empty section is its header plus ONE quiet line (InsufficientDataNote).
 * Five headers and three quiet lines on a new user's Home is a screen whose
 * shape they will recognise later, instead of one that grows new sections
 * under them.
 */
import { Show } from 'solid-js'
import { NextUpCard, QuickSpecsPanel } from '../components/Cards'
import { VehicleBand } from '../components/VehicleBand'
import { ExpenseRow, RowList, ServiceRow } from '../components/Rows'
import { ReadoutSection } from '../ui/ReadoutSection'
import { InsufficientDataNote } from '../ui/FormAdvisory'
import { Emphasis, Label, Secondary } from '../ui/Text'
import { Screen } from './Screen'
import { sortedByUrgency, useScenario } from '../data/scenario'
import { NavBar, type TabId } from '../components/TabBar'
import type { Service } from '../data/fixtures'

export function HomeTab(props: {
  title: string
  onAdd: () => void
  onNavigate: (tab: TabId) => void
  onMarkDone: (service: Service) => void
  specsExpanded: boolean
  onToggleSpecs: () => void
}) {
  const data = useScenario()
  // Derived once and passed down (Views/CLAUDE.md: one derivation per body).
  const sorted = () => sortedByUrgency(data().services, data().vehicle!)
  const nextUp = () => sorted()[0] as Service | undefined
  const upcoming = () => sorted().slice(1, 4)
  const recent = () => data().logs.slice(0, 3)

  return (
    <>
    <NavBar title={props.title} onAdd={props.onAdd} />
    <Screen>
      {/* Full-bleed, and inside the scroll: it scrolls away with the content
          as the large title collapses, rather than pinning ~55pt of chrome. */}
      <div style={{ margin: 'calc(var(--space-md) * -1) calc(var(--space-screen-h) * -1) 0' }}>
        <VehicleBand
          vehicle={data().vehicle!}
          specsExpanded={props.specsExpanded}
          onToggleSpecs={props.onToggleSpecs}
        />
        <Show when={props.specsExpanded}>
          <QuickSpecsPanel vehicle={data().vehicle!} />
        </Show>
      </div>

      {/* 1. The hero. One per screen. */}
      <Show
        when={nextUp()}
        fallback={<InsufficientDataNote message="Nothing scheduled. Add a service with [+]." />}
      >
        {(s) => (
          <NextUpCard
            service={s()}
            vehicle={data().vehicle!}
            onMarkDone={() => props.onMarkDone(s())}
          />
        )}
      </Show>

      {/* 2. Suggestions — one slot. */}
      <ReadoutSection
        title="Suggestions"
        primary={
          <Show
            when={data().suggestion}
            fallback={<InsufficientDataNote message="Nothing to suggest right now." />}
          >
            {(sg) => (
              <div style={{ display: 'flex', 'flex-direction': 'column', 'align-items': 'flex-start', gap: '2px' }}>
                <Emphasis as="div">{sg().title}</Emphasis>
                <Secondary color="tertiary" as="div">
                  {sg().detail}
                </Secondary>
                {/* A bracket link, not an outlined button: the hero's Mark Done
                    is the screen's one filled action, and a boxed button here
                    competed with it in the squint test. */}
                <button style={{ 'min-height': 'var(--touch-target)', display: 'flex', 'align-items': 'center' }}>
                  <Label color="accent" tracking={1}>
                    [{sg().action}]
                  </Label>
                </button>
              </div>
            )}
          </Show>
        }
      />

      {/* 3. Upcoming — the three after Next Up. "View all" lands on Services'
             Due/Upcoming list, which contains every row shown here. */}
      <ReadoutSection
        title="Upcoming"
        action={{ label: 'View all', onClick: () => props.onNavigate('services') }}
        primary={
          <Show
            when={upcoming().length}
            fallback={<InsufficientDataNote message="Nothing else scheduled." />}
          >
            <RowList each={upcoming()}>
              {(s) => (
                <ServiceRow
                  service={s}
                  vehicle={data().vehicle!}
                  actions={['Edit', 'Mark Done']}
                />
              )}
            </RowList>
          </Show>
        }
      />

      {/* 4. Recent — "View all" lands on Services' History, never on Costs:
             a maintenance-history list must not point at a financial view. */}
      <ReadoutSection
        title="Recent"
        action={{ label: 'View all', onClick: () => props.onNavigate('services') }}
        primary={
          <Show
            when={recent().length}
            fallback={<InsufficientDataNote message="Completed services appear here." />}
          >
            <RowList each={recent()}>{(log) => <ExpenseRow log={log} />}</RowList>
          </Show>
        }
      />
    </Screen>
    </>
  )
}

/** No vehicle at all. One primary: the action that fixes it. */
export function HomeEmpty(props: { onAdd?: () => void }) {
  return (
    <Screen center>
      <div
        style={{
          display: 'flex',
          'flex-direction': 'column',
          gap: 'var(--space-sm)',
          'align-items': 'center',
          'text-align': 'center',
        }}
      >
        <Emphasis>No vehicle yet</Emphasis>
        <Secondary color="tertiary">
          Add one with its VIN and odometer. Reminders start from there.
        </Secondary>
        <button
          onClick={props.onAdd}
          data-rank="primary"
          style={{
            'margin-top': 'var(--space-sm)',
            'min-height': 'var(--button-height)',
            padding: '0 var(--space-lg)',
            background: 'var(--accent)',
          }}
        >
          <Emphasis style={{ color: 'var(--background-primary)' }}>Add a Vehicle</Emphasis>
        </button>
      </div>
    </Screen>
  )
}

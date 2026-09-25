/*
 * Services — Readout. "What's due, and what have I done?"
 *
 * ONE SCROLL, NO MODE SWITCH. The previous version kept a Scheduled/History
 * segmented control plus a status FilterControl — one row of chrome, but it
 * still hid half the tab behind a mode, and the status filter re-derived what
 * grouping by status gives for free. Now the tab opens on what matters first
 * and continues into history:
 *
 *   [search]                  system `.searchable` (stand-in)
 *   Overdue            1      status groups, most urgent first — each a
 *   Due Soon           2      ReadoutSection whose header IS the status word
 *   On Track           2
 *   July 2026                 History, by month (no month totals — money
 *   June 2026                 is Costs' question; rows keep their amounts)
 *   …
 *   Reference                 Document library › (a destination, not a mode)
 *
 * A status group with no items is omitted — it is a GROUP, not a section of
 * fixed position, and "Overdue: nothing" would be an apology line on the
 * happiest possible screen. The order of the groups that remain never changes.
 *
 * ROW ACTIONS (swipe + context menu; the "Reveal row actions" harness switch
 * draws them):
 *   service:  Edit · Mark Done      (full swipe = Mark Done; Delete in the
 *                                    context menu only — deleting a schedule
 *                                    is rarer and heavier than editing one)
 *   log:      Duplicate · Edit · Delete   (full swipe = Delete, with undo)
 *
 * EDIT MODE. `Select` in the toolbar; rows grow a leading square; a bottom
 * toolbar replaces the tab bar with the bulk actions and their counts.
 */
import { createSignal, For, Show } from 'solid-js'
import { ExpenseRow, RowList, ServiceRow } from '../components/Rows'
import { NavBar } from '../components/TabBar'
import { ReadoutSection } from '../ui/ReadoutSection'
import { Body, Emphasis, Label, Secondary } from '../ui/Text'
import { Screen } from './Screen'
import { groupByMonth, sortedByUrgency, useScenario } from '../data/scenario'
import type { ServiceStatus } from '../data/fixtures'

const GROUPS: ServiceStatus[] = ['overdue', 'dueSoon', 'good', 'neutral']

/** Group headers are headers, so they take title case; the words match STATUS_LABEL. */
const GROUP_TITLE: Record<ServiceStatus, string> = {
  overdue: 'Overdue',
  dueSoon: 'Due Soon',
  good: 'On Track',
  neutral: 'No Schedule',
}

export function ServicesTab(props: {
  title: string
  onAdd: () => void
  revealActions: boolean
}) {
  const data = useScenario()
  const [selecting, setSelecting] = createSignal(false)
  const [selected, setSelected] = createSignal<Set<string>>(new Set())

  const toggle = (id: string) => {
    const next = new Set(selected())
    next.has(id) ? next.delete(id) : next.add(id)
    setSelected(next)
  }

  const sorted = () => sortedByUrgency(data().services, data().vehicle!)
  const groups = () =>
    GROUPS.map((status) => ({ status, items: sorted().filter((s) => s.status === status) })).filter(
      (g) => g.items.length,
    )
  const months = () => groupByMonth(data().logs)
  const isEmpty = () => !data().services.length && !data().logs.length

  const chrome = (id: string) => ({
    selecting: selecting(),
    selected: selected().has(id),
    onToggleSelect: () => toggle(id),
    revealActions: props.revealActions,
  })

  return (
    <>
      <NavBar
        title={props.title}
        onAdd={props.onAdd}
        search="Search services"
        extra={
          isEmpty()
            ? undefined
            : {
                label: selecting() ? 'Done' : 'Select',
                onClick: () => {
                  setSelecting(!selecting())
                  setSelected(new Set<string>())
                },
              }
        }
      />

      <Show when={!isEmpty()} fallback={<ServicesEmpty onAdd={props.onAdd} />}>
        <Screen>
          <For each={groups()}>
            {(g) => (
              <ReadoutSection
                title={GROUP_TITLE[g.status]}
                trailing={String(g.items.length)}
                primary={
                  <RowList each={g.items}>
                    {(s) => (
                      <ServiceRow
                        service={s}
                        vehicle={data().vehicle!}
                        actions={['Edit', 'Mark Done']}
                        groupedByStatus
                        {...chrome(s.id)}
                      />
                    )}
                  </RowList>
                }
              />
            )}
          </For>

          <For each={months()}>
            {(m) => (
              <ReadoutSection
                title={m.label}
                primary={
                  <RowList each={m.logs}>
                    {(log) => (
                      <ExpenseRow
                        log={log}
                        dateStyle="day"
                        actions={['Duplicate', 'Edit', 'Delete']}
                        {...chrome(log.id)}
                      />
                    )}
                  </RowList>
                }
              />
            )}
          </For>

          <div>
            <Label>Reference</Label>
            <button style={{ 'min-height': 'var(--touch-target)', display: 'flex', 'align-items': 'center' }}>
              <Label color="accent" tracking={1}>
                [Document library]
              </Label>
            </button>
          </div>
        </Screen>
      </Show>

      {/* Edit-mode bottom toolbar — replaces the tab bar while selecting. */}
      <Show when={selecting()}>
        <div
          style={{
            display: 'flex',
            'justify-content': 'space-between',
            'align-items': 'center',
            height: '83px',
            'padding-bottom': '34px',
            'padding-left': 'var(--space-screen-h)',
            'padding-right': 'var(--space-screen-h)',
            'border-top': '1px solid var(--grid-line)',
            background: 'var(--background-elevated)',
            position: 'relative',
            'z-index': '1',
            'margin-bottom': '-83px',
          }}
        >
          <button style={{ 'min-height': 'var(--touch-target)' }} aria-disabled={!selected().size}>
            <Body color={selected().size ? 'accent' : 'tertiary'}>Mark Done ({selected().size})</Body>
          </button>
          <button style={{ 'min-height': 'var(--touch-target)' }} aria-disabled={!selected().size}>
            <Body color={selected().size ? 'overdue' : 'tertiary'}>Delete ({selected().size})</Body>
          </button>
        </div>
      </Show>
    </>
  )
}

/** First run: one message, one action. */
function ServicesEmpty(props: { onAdd: () => void }) {
  return (
    <Screen center>
      <div
        style={{
          display: 'flex',
          'flex-direction': 'column',
          'align-items': 'center',
          gap: 'var(--space-sm)',
          'text-align': 'center',
        }}
      >
        <Emphasis>No services yet</Emphasis>
        <Secondary color="tertiary">
          Log one you've already done, or schedule the next one. Either starts your reminders.
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
          <Emphasis style={{ color: 'var(--background-primary)' }}>Add a Service</Emphasis>
        </button>
      </div>
    </Screen>
  )
}

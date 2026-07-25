/*
 * Services.
 *
 * The problem being solved: up to four rows of chrome before any content —
 * search, view-mode segmented, status-filter segmented, and a filter indicator.
 * Plus "Documents" was a third view mode that then offered "OPEN LIBRARY" to
 * leave for the real documents screen: a content type masquerading as a view.
 *
 * The fix modelled here: exactly ONE control row. Mode is the segmented control
 * because it changes what the screen *is*; status is a FilterControl because
 * filtering is refinement. The status filter only exists in Scheduled mode —
 * history entries have no status, and a control that does nothing is worse than
 * an absent one. Documents is a destination, not a mode.
 */
import { createSignal, For, Show } from 'solid-js'
import { SegmentedControl } from '../ui/Controls'
import { ActiveFilterBar, ControlRow, FilterControl } from '../ui/FilterControl'
import { ExpenseRow, ListDivider, ServiceRow } from '../components/Rows'
import { ReadoutSection } from '../ui/ReadoutSection'
import { Label, Secondary } from '../ui/Text'
import { Screen } from './Screen'
import { serviceLogs, services, type ServiceStatus } from '../data/fixtures'

type Mode = 'scheduled' | 'history'
type StatusFilter = 'all' | ServiceStatus

export function ServicesTab() {
  const [mode, setMode] = createSignal<Mode>('scheduled')
  const [status, setStatus] = createSignal<StatusFilter>('all')

  const filtered = () =>
    status() === 'all' ? services : services.filter((s) => s.status === status())

  const countOf = (s: ServiceStatus) => services.filter((x) => x.status === s).length

  const statusFilters = () => [
    { value: 'all' as StatusFilter, label: 'All', count: services.length },
    { value: 'overdue' as StatusFilter, label: 'Overdue', count: countOf('overdue') },
    { value: 'dueSoon' as StatusFilter, label: 'Due soon', count: countOf('dueSoon') },
    { value: 'good' as StatusFilter, label: 'On track', count: countOf('good') },
  ]

  return (
    <div style={{ display: 'flex', 'flex-direction': 'column', flex: '1 1 auto', 'min-height': '0' }}>
      {/* One control row, pinned above the scroll area so the list scrolls
          under it rather than pushing it away. */}
      <ControlRow>
        <div style={{ flex: '1 1 auto', 'min-width': '0' }}>
          <SegmentedControl
            options={[
              { value: 'scheduled', label: 'Scheduled' },
              { value: 'history', label: 'History' },
            ]}
            value={mode()}
            onChange={setMode}
          />
        </div>

        {/* Status only exists for scheduled items, so the filter only exists
            there too. A no-op control in History mode costs a target and
            answers nothing. */}
        <Show when={mode() === 'scheduled'}>
          <FilterControl
            name="Status"
            options={statusFilters()}
            value={status()}
            onChange={setStatus}
            defaultValue="all"
          />
        </Show>
      </ControlRow>

      <Show when={mode() === 'scheduled'}>
        <ActiveFilterBar
          name="Status"
          options={statusFilters()}
          value={status()}
          defaultValue="all"
          onClear={() => setStatus('all')}
        />
      </Show>

      <Screen>
        <Show
          when={mode() === 'scheduled'}
          fallback={
            <ReadoutSection
              title={`${serviceLogs.length} entries`}
              action={{ label: 'Documents' }}
              primary={
                <div style={{ display: 'flex', 'flex-direction': 'column' }}>
                  <For each={serviceLogs}>
                    {(log, i) => (
                      <>
                        <Show when={i() > 0}>
                          <ListDivider />
                        </Show>
                        <ExpenseRow log={log} />
                      </>
                    )}
                  </For>
                </div>
              }
            />
          }
        >
          <Show
            when={filtered().length}
            fallback={<Secondary color="tertiary">Nothing matches this filter.</Secondary>}
          >
            <ReadoutSection
              title={`${filtered().length} scheduled`}
              primary={
                <div style={{ display: 'flex', 'flex-direction': 'column' }}>
                  <For each={filtered()}>
                    {(service, i) => (
                      <>
                        <Show when={i() > 0}>
                          <ListDivider />
                        </Show>
                        <ServiceRow service={service} />
                      </>
                    )}
                  </For>
                </div>
              }
            />
          </Show>
        </Show>

        <div style={{ 'padding-top': 'var(--space-sm)' }}>
          <Label>Reference</Label>
          <div style={{ display: 'flex', 'flex-direction': 'column', 'padding-top': 'var(--space-xs)' }}>
            <button style={{ 'min-height': 'var(--touch-target)', display: 'flex', 'align-items': 'center' }}>
              <Label color="accent" tracking={1}>
                [Document library]
              </Label>
            </button>
          </div>
        </div>
      </Screen>
    </div>
  )
}

/*
 * Services.
 *
 * The problem being solved: up to four rows of chrome before any content —
 * search, view-mode segmented, status-filter segmented, and a filter indicator.
 * Plus "Documents" was a third view mode that then offered "OPEN LIBRARY" to
 * leave for the real documents screen: a content type masquerading as a view.
 *
 * The fix modelled here: ONE control row. Mode is the segmented control; the
 * status filter collapses into chips that only appear in Scheduled mode, where
 * status exists. Documents is a destination, not a mode.
 */
import { createSignal, For, Show } from 'solid-js'
import { Chip, ChipRow, SegmentedControl } from '../ui/Controls'
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

  const statusFilters: { value: StatusFilter; label: string }[] = [
    { value: 'all', label: 'All' },
    { value: 'overdue', label: 'Overdue' },
    { value: 'dueSoon', label: 'Due soon' },
    { value: 'good', label: 'On track' },
  ]

  return (
    <div style={{ display: 'flex', 'flex-direction': 'column', flex: '1 1 auto', 'min-height': '0' }}>
      {/* One control row, pinned above the scroll area so the list scrolls
          under it rather than pushing it away. */}
      <div
        style={{
          display: 'flex',
          'flex-direction': 'column',
          gap: 'var(--space-sm)',
          padding: 'var(--space-md) var(--space-screen-h)',
          'border-bottom': 'var(--border-width) solid var(--grid-line)',
        }}
      >
        <SegmentedControl
          options={[
            { value: 'scheduled', label: 'Scheduled' },
            { value: 'history', label: 'History' },
          ]}
          value={mode()}
          onChange={setMode}
        />

        {/* Status only exists for scheduled items, so the filter only exists
            there too. Showing a disabled or no-op control in History mode is
            chrome that costs a row and answers nothing. */}
        <Show when={mode() === 'scheduled'}>
          <ChipRow wrap={false}>
            <For each={statusFilters}>
              {(f) => (
                <Chip
                  label={f.label}
                  selected={status() === f.value}
                  onClick={() => setStatus(f.value)}
                />
              )}
            </For>
          </ChipRow>
        </Show>
      </div>

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

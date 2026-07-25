/*
 * Costs.
 *
 * The problem being solved: two stacked segmented controls (4 periods × 4
 * categories = 16 states) above nine independently-gated cards.
 *
 * The fix modelled here: period is the segmented control, category is a chip row
 * (chips scale to six categories where a segmented control does not), then a
 * FIXED card order. "Not enough data yet" is one quiet line, never a full card
 * whose only content is absence.
 */
import { createSignal, For, Show } from 'solid-js'
import { Chip, ChipRow, SegmentedControl } from '../ui/Controls'
import { CostHeadlineCard, StatsGrid } from '../components/Cards'
import { ExpenseRow, ListDivider } from '../components/Rows'
import { ReadoutSection } from '../ui/ReadoutSection'
import { InsufficientDataNote } from '../ui/FormAdvisory'
import { Body } from '../ui/Text'
import { Screen } from './Screen'
import {
  categoryLabels,
  fmtCurrencyWhole,
  serviceLogs,
  type CostCategory,
} from '../data/fixtures'

type Period = '30d' | '90d' | 'ytd' | 'all'
type CategoryFilter = 'all' | CostCategory

const PERIOD_LABEL: Record<Period, string> = {
  '30d': 'Last 30 days',
  '90d': 'Last 90 days',
  ytd: 'Year to date',
  all: 'All time',
}

export function CostsTab() {
  const [period, setPeriod] = createSignal<Period>('ytd')
  const [category, setCategory] = createSignal<CategoryFilter>('all')

  const filtered = () =>
    category() === 'all' ? serviceLogs : serviceLogs.filter((l) => l.category === category())

  const total = () => filtered().reduce((sum, l) => sum + (l.cost ?? 0), 0)

  const byCategory = () => {
    const map = new Map<CostCategory, number>()
    for (const log of filtered()) {
      map.set(log.category, (map.get(log.category) ?? 0) + (log.cost ?? 0))
    }
    return [...map.entries()].sort((a, b) => b[1] - a[1])
  }

  const categories: CategoryFilter[] = [
    'all',
    'maintenance',
    'repair',
    'registration',
    'insurance',
    'fuel',
  ]

  return (
    <div style={{ display: 'flex', 'flex-direction': 'column', flex: '1 1 auto', 'min-height': '0' }}>
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
            { value: '30d', label: '30D' },
            { value: '90d', label: '90D' },
            { value: 'ytd', label: 'YTD' },
            { value: 'all', label: 'All' },
          ]}
          value={period()}
          onChange={setPeriod}
        />
        <ChipRow wrap={false}>
          <For each={categories}>
            {(c) => (
              <Chip
                label={c === 'all' ? 'All' : categoryLabels[c]}
                selected={category() === c}
                onClick={() => setCategory(c)}
              />
            )}
          </For>
        </ChipRow>
      </div>

      <Screen>
        {/* 1. The hero. */}
        <CostHeadlineCard total={total()} periodLabel={PERIOD_LABEL[period()]} delta={12} />

        {/* 2. Stats, fixed position. */}
        <StatsGrid
          stats={[
            { label: 'Entries', value: String(filtered().length) },
            {
              label: 'Average',
              value: fmtCurrencyWhole(filtered().length ? total() / filtered().length : 0),
            },
            { label: 'Cost / mile', value: '$0.16' },
            { label: 'Monthly pace', value: fmtCurrencyWhole(total() / 7) },
          ]}
        />

        {/* 3. Spending pace. When there isn't enough data this is ONE LINE, not
               a full-size card whose only content is "3+ expenses to show
               spending pace". */}
        <ReadoutSection
          title="Spending pace"
          primary={
            <Show
              when={filtered().length >= 3}
              fallback={
                <InsufficientDataNote message="Two more entries and a spending pace appears here." />
              }
            >
              <PaceBars logs={filtered()} />
            </Show>
          }
        />

        {/* 4. Breakdown, fixed position. */}
        <ReadoutSection
          title="By category"
          primary={
            <div style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-sm)' }}>
              <For each={byCategory()}>
                {([cat, amount]) => (
                  <div style={{ display: 'flex', 'flex-direction': 'column', gap: '2px' }}>
                    <div
                      style={{
                        display: 'flex',
                        'justify-content': 'space-between',
                        'align-items': 'baseline',
                      }}
                    >
                      <Body>{categoryLabels[cat]}</Body>
                      <Body>{fmtCurrencyWhole(amount)}</Body>
                    </div>
                    <div style={{ height: '2px', background: 'var(--grid-line)' }}>
                      <div
                        style={{
                          height: '100%',
                          width: `${total() ? (amount / total()) * 100 : 0}%`,
                          background: 'var(--accent)',
                        }}
                      />
                    </div>
                  </div>
                )}
              </For>
            </div>
          }
        />

        {/* 5. Top expenses, fixed position. */}
        <ReadoutSection
          title="Largest expenses"
          primary={
            <div style={{ display: 'flex', 'flex-direction': 'column' }}>
              <For each={[...filtered()].sort((a, b) => (b.cost ?? 0) - (a.cost ?? 0)).slice(0, 3)}>
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
      </Screen>
    </div>
  )
}

/** A minimal bar chart, enough to judge how the section reads at this size. */
function PaceBars(props: { logs: { cost?: number; name: string }[] }) {
  const max = () => Math.max(...props.logs.map((l) => l.cost ?? 0), 1)
  return (
    <div style={{ display: 'flex', 'align-items': 'flex-end', gap: 'var(--space-xs)', height: '72px' }}>
      <For each={props.logs.slice(0, 8)}>
        {(log) => (
          <div
            title={log.name}
            style={{
              flex: '1 1 0',
              height: `${((log.cost ?? 0) / max()) * 100}%`,
              'min-height': '2px',
              background: 'var(--accent-muted)',
            }}
          />
        )}
      </For>
    </div>
  )
}

/*
 * Costs — Readout. "How much is this car costing me, and is that changing?"
 *
 * FIXED ORDER:
 *
 *   [ 30D | YTD | 12M | All ]     the one control; scopes every number below
 *   Year to Date                  hero: the period total (56 Light)
 *     $330 per month on average   the secondary figure (20, secondary)
 *   Per Month, USD  Trend·Category ONE chart section — Trend ↔ Category —
 *     [chart]                     always with a written summary line, so the
 *     Highest: March — $1,317…    chart is never the only carrier of its point
 *   2026 vs 2025                  one comparison row, same calendar span
 *   July 2026         $730.40     expenses, by month; rows drill in
 *   …
 *
 * What was removed, and why:
 *   - The Category FilterControl. The Category chart answers "where does it
 *     go" at a glance; filtering a list by category was the slow way to ask.
 *   - The four-cell StatsGrid (entries, average, cost/mile, pace). Four equal
 *     numbers in equal boxes is the wall this doctrine exists to prevent —
 *     each was a primary, so none was. The one that mattered (monthly
 *     average) is now the hero's secondary.
 *   - Top Expenses, and the separate Yearly roundup hero. Top Expenses
 *     re-listed rows already in the month groups; the roundup was a second
 *     hero. "2026 vs 2025" is what the roundup was for, as one row.
 *   - 90D. Replaced by 12M, which is the period that actually smooths the
 *     annual insurance and marbete spikes out of the average.
 *
 * SPARSE DATA: the hero always renders (a total of one expense is still a
 * total). The chart and the comparison each collapse to ONE quiet line saying
 * what will make them appear — never a card whose only content is absence.
 */
import { createMemo, createSignal, For, Show } from 'solid-js'
import { Chip, ChipRow, SegmentedControl } from '../ui/Controls'
import { ExpenseRow, RowList } from '../components/Rows'
import { NavBar } from '../components/TabBar'
import { ReadoutSection } from '../ui/ReadoutSection'
import { InsufficientDataNote } from '../ui/FormAdvisory'
import { Body, Emphasis, Heading, Hero, Label, SectionTitle, Secondary } from '../ui/Text'
import { Screen } from './Screen'
import { groupByMonth, useScenario } from '../data/scenario'
import {
  categoryLabels,
  fmtCurrency,
  fmtCurrencyWhole,
  today,
  type CostCategory,
  type ServiceLog,
} from '../data/fixtures'

type Period = '30d' | 'ytd' | '12m' | 'all'
type ChartMode = 'trend' | 'category'

const PERIOD_LABEL: Record<Period, string> = {
  '30d': 'Last 30 Days',
  ytd: 'Year to Date',
  '12m': 'Last 12 Months',
  all: 'All Time',
}

const DAY = 24 * 60 * 60 * 1000

function periodStart(p: Period): Date {
  if (p === '30d') return new Date(today.getTime() - 30 * DAY)
  if (p === 'ytd') return new Date(today.getFullYear(), 0, 1)
  if (p === '12m') return new Date(today.getFullYear() - 1, today.getMonth(), today.getDate())
  return new Date(0)
}

const sum = (logs: ServiceLog[]) => logs.reduce((t, l) => t + (l.cost ?? 0), 0)
const monthShort = (d: Date) => d.toLocaleDateString('en-US', { month: 'short' })

export function CostsTab(props: { title: string; onAdd: () => void }) {
  const data = useScenario()
  const [period, setPeriod] = createSignal<Period>('ytd')
  const [chart, setChart] = createSignal<ChartMode>('trend')

  // Derived once per render pass and passed down.
  const inPeriod = createMemo(() =>
    data().logs.filter((l) => l.performedAt >= periodStart(period()) && l.performedAt <= today),
  )
  const total = () => sum(inPeriod())

  /** Months from the later of the period start and the first expense — a
      July-only history averaged over seven YTD months read "$10 a month". */
  const monthsSpanned = () => {
    const logs = inPeriod()
    if (!logs.length) return 1
    const first = logs.reduce((m, l) => (l.performedAt < m ? l.performedAt : m), today)
    const start = first > periodStart(period()) ? first : periodStart(period())
    return Math.max(1, (today.getFullYear() - start.getFullYear()) * 12 + today.getMonth() - start.getMonth() + 1)
  }

  /** Last 12 months' average, the yardstick for the 30-day view. */
  const twelveMonthAvg = () =>
    sum(data().logs.filter((l) => l.performedAt >= periodStart('12m'))) / 12

  const months = createMemo(() => groupByMonth(inPeriod()))

  // Trend: one bar per calendar month in the period, oldest first, zeros kept.
  const trend = createMemo(() => {
    const n = period() === '30d' ? 2 : Math.min(monthsSpanned(), 24)
    return Array.from({ length: n }, (_, i) => {
      const d = new Date(today.getFullYear(), today.getMonth() - (n - 1 - i), 1)
      const logs = inPeriod().filter(
        (l) => l.performedAt.getFullYear() === d.getFullYear() && l.performedAt.getMonth() === d.getMonth(),
      )
      const top = [...logs].sort((a, b) => (b.cost ?? 0) - (a.cost ?? 0))[0]
      return { date: d, total: sum(logs), top }
    })
  })

  const byCategory = createMemo(() => {
    const map = new Map<CostCategory, number>()
    for (const l of inPeriod()) map.set(l.category, (map.get(l.category) ?? 0) + (l.cost ?? 0))
    return [...map.entries()].sort((a, b) => b[1] - a[1])
  })

  const monthsWithSpend = () => trend().filter((m) => m.total > 0).length
  const trendReady = () => period() === '30d' ? inPeriod().length >= 2 : monthsWithSpend() >= 3
  const categoryReady = () => byCategory().length >= 2

  const summary = () => {
    if (chart() === 'trend') {
      const peak = [...trend()].sort((a, b) => b.total - a.total)[0]
      if (!peak) return ''
      const quiet = trend().filter((m) => m.total < 100).length
      return `Highest: ${peak.date.toLocaleDateString('en-US', { month: 'long' })} — ${fmtCurrencyWhole(peak.total)}${
        peak.top ? ` (${peak.top.name})` : ''
      }. ${quiet} of ${trend().length} months under $100.`
    }
    const [cat, amt] = byCategory()[0] ?? []
    return cat ? `${categoryLabels[cat]} is ${Math.round((amt! / total()) * 100)}% of spending.` : ''
  }

  // Comparison: this year so far vs the same calendar span last year.
  const comparison = () => {
    const y = today.getFullYear()
    const cut = (yr: number) => new Date(yr, today.getMonth(), today.getDate())
    const thisYear = sum(data().logs.filter((l) => l.performedAt >= new Date(y, 0, 1) && l.performedAt <= today))
    const lastLogs = data().logs.filter((l) => l.performedAt >= new Date(y - 1, 0, 1) && l.performedAt <= cut(y - 1))
    if (!lastLogs.length) return undefined
    const last = sum(lastLogs)
    return { y, thisYear, last, pct: Math.round(((thisYear - last) / last) * 100) }
  }

  return (
    <>
      <NavBar title={props.title} onAdd={props.onAdd} />
      <Screen>
        <SegmentedControl
          options={[
            { value: '30d', label: '30D' },
            { value: 'ytd', label: 'YTD' },
            { value: '12m', label: '12M' },
            { value: 'all', label: 'All' },
          ]}
          value={period()}
          onChange={setPeriod}
        />

        {/* 1. Hero: the period total. */}
        <ReadoutSection
          title={PERIOD_LABEL[period()]}
          primary={<Hero>{fmtCurrencyWhole(total())}</Hero>}
          supporting={
            <div style={{ display: 'flex', 'align-items': 'baseline', gap: 'var(--space-sm)', 'flex-wrap': 'wrap' }}>
              <Show
                when={period() !== '30d'}
                fallback={
                  <>
                    <Heading color="secondary">{fmtCurrencyWhole(twelveMonthAvg())}</Heading>
                    <Secondary color="tertiary">a month, on average, over 12 months</Secondary>
                  </>
                }
              >
                <Heading color="secondary">{fmtCurrencyWhole(total() / monthsSpanned())}</Heading>
                <Secondary color="tertiary">a month, on average</Secondary>
              </Show>
            </div>
          }
        />

        {/* 2. ONE chart section. Units in the title; a written summary always. */}
        <section
          data-section="Chart"
          style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-sm)' }}
        >
          <div style={{ display: 'flex', 'align-items': 'center', gap: 'var(--space-sm)' }}>
            <span style={{ flex: '1 1 auto', 'min-width': '0' }}>
              <SectionTitle>
                {chart() === 'trend' ? 'Per Month, USD' : 'By Category, USD'}
              </SectionTitle>
            </span>
            {/* Plain chips, not a second segmented control. Two filled accent
                slabs (period + chart) competed at the top of the screen — the
                same fault the old FilterControl row had. The period changes
                every number; this only changes one picture, so it is quieter. */}
            <ChipRow wrap={false}>
              <Chip variant="plain" label="Trend" selected={chart() === 'trend'} onClick={() => setChart('trend')} />
              <Chip variant="plain" label="Category" selected={chart() === 'category'} onClick={() => setChart('category')} />
            </ChipRow>
          </div>

          <div data-slot="primary">
            <Show
              when={chart() === 'trend' ? trendReady() : categoryReady()}
              fallback={
                <InsufficientDataNote
                  message={
                    chart() === 'trend'
                      ? 'A trend appears once three months have expenses.'
                      : 'A breakdown appears once expenses span two categories.'
                  }
                />
              }
            >
              <Show when={chart() === 'trend'} fallback={<CategoryBars rows={byCategory()} total={total()} />}>
                <TrendBars months={trend()} />
              </Show>
              <Secondary color="secondary" as="div" style={{ 'padding-top': 'var(--space-sm)' }}>
                {summary()}
              </Secondary>
            </Show>
          </div>
        </section>

        {/* 3. Comparison row. */}
        <ReadoutSection
          title={`${today.getFullYear()} vs ${today.getFullYear() - 1}`}
          primary={
            <Show
              when={comparison()}
              fallback={<InsufficientDataNote message="Appears once there's a year of history to compare." />}
            >
              {(c) => (
                <div style={{ display: 'flex', 'flex-direction': 'column', gap: '2px' }}>
                  <div style={{ display: 'flex', 'align-items': 'baseline', gap: 'var(--space-sm)', 'flex-wrap': 'wrap' }}>
                    <Emphasis>
                      {c().pct >= 0 ? '▲' : '▼'} {Math.abs(c().pct)}% {c().pct >= 0 ? 'more' : 'less'}
                    </Emphasis>
                    <Secondary color="tertiary">than the same stretch last year</Secondary>
                  </div>
                  <Secondary color="tertiary" as="div">
                    {fmtCurrencyWhole(c().thisYear)} Jan–{monthShort(today)} {c().y} // {fmtCurrencyWhole(c().last)} in {c().y - 1}
                  </Secondary>
                </div>
              )}
            </Show>
          }
        />

        {/* 4. Expenses by month. */}
        <Show
          when={months().length}
          fallback={
            <ReadoutSection
              title="Expenses"
              primary={<InsufficientDataNote message="Nothing spent in this period." />}
            />
          }
        >
          <For each={months()}>
            {(m) => (
              <ReadoutSection
                title={m.label}
                trailing={fmtCurrency(m.total)}
                primary={
                  <RowList each={m.logs}>
                    {(log) => <ExpenseRow log={log} dateStyle="day" />}
                  </RowList>
                }
              />
            )}
          </For>
        </Show>
      </Screen>
    </>
  )
}

function TrendBars(props: { months: { date: Date; total: number }[] }) {
  const max = () => Math.max(...props.months.map((m) => m.total), 1)
  const peak = () => props.months.reduce((p, m) => (m.total > p.total ? m : p), props.months[0])
  const labelEvery = () => (props.months.length > 12 ? 3 : props.months.length > 7 ? 2 : 1)
  return (
    <div
      role="img"
      aria-label="Monthly spending bar chart"
      style={{ display: 'flex', 'align-items': 'flex-end', gap: '3px', height: '112px' }}
    >
      <For each={props.months}>
        {(m, i) => (
          <div style={{ flex: '1 1 0', display: 'flex', 'flex-direction': 'column', 'align-items': 'center', gap: '4px', height: '100%', 'justify-content': 'flex-end', 'min-width': '0' }}>
            <div
              style={{
                width: '100%',
                height: `${(m.total / max()) * 88}px`,
                'min-height': m.total > 0 ? '2px' : '1px',
                background: m === peak() ? 'var(--accent)' : 'var(--accent-muted)',
              }}
            />
            <Label tracking={0} style={{ visibility: i() % labelEvery() === (props.months.length - 1) % labelEvery() ? 'visible' : 'hidden' }}>
              {m.date.toLocaleDateString('en-US', { month: 'narrow' })}
            </Label>
          </div>
        )}
      </For>
    </div>
  )
}

function CategoryBars(props: { rows: [CostCategory, number][]; total: number }) {
  return (
    <div
      role="img"
      aria-label="Spending by category"
      style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-sm)' }}
    >
      <For each={props.rows}>
        {([cat, amount], i) => (
          <div style={{ display: 'flex', 'flex-direction': 'column', gap: '4px' }}>
            <div style={{ display: 'flex', 'justify-content': 'space-between', 'align-items': 'baseline', gap: 'var(--space-sm)' }}>
              <Body>{categoryLabels[cat]}</Body>
              <Secondary color="secondary">
                {fmtCurrencyWhole(amount)}  ·  {Math.round((amount / props.total) * 100)}%
              </Secondary>
            </div>
            <div style={{ height: '6px', background: 'var(--grid-line)' }}>
              <div
                style={{
                  height: '100%',
                  width: `${(amount / props.total) * 100}%`,
                  background: i() === 0 ? 'var(--accent)' : 'var(--accent-muted)',
                }}
              />
            </div>
          </div>
        )}
      </For>
    </div>
  )
}

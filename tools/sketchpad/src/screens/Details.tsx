/*
 * Detail columns — what a Services or Costs row shows beside the list at
 * regular width. "What is this one thing, and what do I do about it?"
 *
 * Minimal on purpose: they model the regular-width FOOTPRINT of
 * ServiceDetailView and ServiceLogDetailView (a readable-width column, one
 * hero, sections beneath), not their full content. The ordering follows the
 * app: status → the one action → schedule → history.
 *
 * The detail column has its own inline bar (trailing Edit). Its large title is
 * the item's name; the list column keeps the tab's title, so the two columns
 * never repeat each other.
 */
import { Show } from 'solid-js'
import { ExpenseRow, RowList } from '../components/Rows'
import { ReadableColumn } from '../components/SplitView'
import { dueLine, remainingText, STATUS_COLOR, StatusTag } from '../components/status'
import { ReadoutSection } from '../ui/ReadoutSection'
import { InsufficientDataNote } from '../ui/FormAdvisory'
import { Body, Emphasis, Heading, Secondary, Title } from '../ui/Text'
import { useScenario } from '../data/scenario'
import { READABLE_WIDTH } from '../layout/sizeClass'
import {
  categoryLabels,
  fmtCurrency,
  fmtDate,
  fmtMileage,
  type Service,
  type ServiceLog,
} from '../data/fixtures'

function DetailBar(props: { title: string }) {
  return (
    <div style={{ flex: '0 0 auto', background: 'var(--background-primary)' }}>
      <div
        style={{
          display: 'flex',
          'justify-content': 'flex-end',
          'align-items': 'center',
          height: '44px',
          padding: '0 var(--space-sm)',
        }}
      >
        <button style={{ 'min-height': 'var(--touch-target)', padding: '0 var(--space-sm)' }}>
          <Body color="accent">Edit</Body>
        </button>
      </div>
      {/* Same readable width as the content, so the title aligns with it. */}
      <div style={{ 'max-width': `${READABLE_WIDTH}px`, margin: '0 auto', padding: '0 var(--space-screen-h)' }}>
        <Title lines={2} as="div">
          {props.title}
        </Title>
      </div>
    </div>
  )
}

export function ServiceDetail(props: { service: Service; onMarkDone?: () => void }) {
  const data = useScenario()
  const s = () => props.service
  const history = () => data().logs.filter((l) => l.name === s().name)
  const interval = () => {
    const parts: string[] = []
    if (s().intervalMiles) parts.push(fmtMileage(s().intervalMiles!))
    if (s().intervalMonths) parts.push(`${s().intervalMonths} months`)
    return parts.length ? `Every ${parts.join(' or ')}` : 'Once'
  }

  return (
    <>
      <DetailBar title={s().name} />
      <ReadableColumn>
        <Show when={s().status !== 'neutral'}>
          <ReadoutSection
            title="Status"
            primary={
              <Heading style={{ color: STATUS_COLOR[s().status] }}>{remainingText(s(), data().vehicle!)}</Heading>
            }
            supporting={
              <div style={{ display: 'flex', 'align-items': 'center', gap: 'var(--space-sm)' }}>
                <StatusTag status={s().status} />
                <Secondary color="tertiary">{dueLine(s())}</Secondary>
              </div>
            }
          />
        </Show>

        {/* The screen's one filled action — outside every section, as in the app. */}
        <button
          onClick={props.onMarkDone}
          style={{
            display: 'flex',
            'align-items': 'center',
            'justify-content': 'center',
            'min-height': 'var(--button-height)',
            background: 'var(--accent)',
            width: '100%',
          }}
        >
          <Emphasis style={{ color: 'var(--background-primary)' }}>Mark Done</Emphasis>
        </button>

        <ReadoutSection
          title="Schedule"
          primary={<Emphasis>{interval()}</Emphasis>}
          supporting={
            <Show when={s().lastPerformedAt}>
              <Secondary color="tertiary">
                Last done {fmtDate(s().lastPerformedAt!)}
                {s().lastPerformedMileage ? ` at ${fmtMileage(s().lastPerformedMileage!)}` : ''}
              </Secondary>
            </Show>
          }
        />

        <ReadoutSection
          title="History"
          primary={
            <Show when={history().length} fallback={<InsufficientDataNote message="Not logged yet." />}>
              <RowList each={history()}>{(log) => <ExpenseRow log={log} dateStyle="day" />}</RowList>
            </Show>
          }
        />
      </ReadableColumn>
    </>
  )
}

export function ExpenseDetail(props: { log: ServiceLog }) {
  const l = () => props.log
  const facts = () =>
    [l().mileage ? fmtMileage(l().mileage!) : undefined, l().vendor].filter(Boolean).join('  //  ')

  return (
    <>
      <DetailBar title={l().name} />
      <ReadableColumn>
        <ReadoutSection
          title="Cost"
          primary={
            <Show when={l().cost != null} fallback={<InsufficientDataNote message="No cost recorded." />}>
              {/* 32, not Hero: beside Costs the period total is the screen's
                  one 56pt number, and two of them split the squint test. */}
              <Title uppercase={false}>{fmtCurrency(l().cost!)}</Title>
            </Show>
          }
          supporting={<Secondary color="tertiary">{categoryLabels[l().category]}</Secondary>}
        />
        <ReadoutSection
          title="Done"
          primary={<Emphasis>{fmtDate(l().performedAt)}</Emphasis>}
          supporting={
            <Show when={facts()}>
              <Secondary color="tertiary">{facts()}</Secondary>
            </Show>
          }
        />
      </ReadableColumn>
    </>
  )
}

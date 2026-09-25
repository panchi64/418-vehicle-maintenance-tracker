/*
 * ServiceRow and ServiceEventRow — the two list shells that repeat everywhere.
 *
 * Mirrors Views/Components/Lists/ServiceRow.swift and ServiceEventRow.swift.
 * Between them they replaced six drifted implementations, so a change here is
 * the highest-leverage change available to a readout screen.
 *
 * DENSITY. ServiceRow was three lines — an 11pt urgency eyebrow, a 20pt name,
 * a support line — about 84pt a row, so Services showed four items above the
 * fold and Home's Upcoming alone ate a third of the screen. It is two lines
 * now (~62pt):
 *
 *   Oil & Filter Change                     917 mi over
 *   ■ OVERDUE  Due 32,500 mi or Jul 4
 *
 * The name is the row's primary (15 Medium, primary color); the status tag is
 * word + shape + color on the second line; the remaining figure trails the
 * name, where a scanning eye lands after reading it. The 20pt name is gone
 * because a list of 20pt names is a list of headings — nothing in it is
 * subordinate to anything.
 *
 * ROW ACTIONS. Rows take `actions` (the swipe / context-menu set) and render
 * them as a trailing strip when `revealActions` is on — a stand-in for the
 * swipe, so the port knows which actions each row carries and in what order.
 * Leading-to-trailing order = trailing swipe order; the LAST one is the full
 * swipe. Destructive last.
 */
import type { JSX } from 'solid-js'
import { For, Show } from 'solid-js'
import { Body, Emphasis, Label, Secondary } from '../ui/Text'
import { dueLine, remainingText, StatusMark, StatusTag, STATUS_COLOR } from './status'
import {
  fmtCurrency,
  fmtMileageBare,
  timeSince,
  type Service,
  type ServiceLog,
  type Vehicle,
} from '../data/fixtures'

// --- Shared shell: selection + revealed actions ---------------------------

export interface RowChrome {
  /** Swipe / context-menu actions, in trailing-swipe order. */
  actions?: string[]
  revealActions?: boolean
  /** Edit mode: a leading selection square replaces the chevron. */
  selecting?: boolean
  selected?: boolean
  onToggleSelect?: () => void
  onClick?: () => void
}

function RowShell(props: RowChrome & { section: string; children: JSX.Element }) {
  return (
    <div style={{ display: 'flex', 'align-items': 'stretch', width: '100%', overflow: 'hidden' }}>
      <button
        data-section={props.section}
        onClick={() => (props.selecting ? props.onToggleSelect?.() : props.onClick?.())}
        aria-pressed={props.selecting ? !!props.selected : undefined}
        style={{
          display: 'flex',
          'align-items': 'center',
          gap: 'var(--space-md)',
          flex: '1 1 auto',
          'min-width': '0',
          padding: 'var(--space-list-item) 0',
        }}
      >
        <Show when={props.selecting}>
          <div
            aria-hidden="true"
            style={{
              flex: '0 0 auto',
              width: '22px',
              height: '22px',
              border: `var(--border-width) solid ${props.selected ? 'var(--accent)' : 'var(--border-subtle)'}`,
              background: props.selected ? 'var(--accent)' : 'transparent',
              display: 'flex',
              'align-items': 'center',
              'justify-content': 'center',
              color: 'var(--background-primary)',
              font: 'var(--font-label-bold)',
            }}
          >
            {props.selected ? '✓' : ''}
          </div>
        </Show>
        {props.children}
      </button>

      <Show when={props.revealActions && props.actions?.length && !props.selecting}>
        <div style={{ display: 'flex', flex: '0 0 auto' }}>
          <For each={props.actions}>
            {(a) => (
              <div
                style={{
                  display: 'flex',
                  'align-items': 'center',
                  'justify-content': 'center',
                  padding: '0 var(--space-sm)',
                  'min-width': '64px',
                  background:
                    a === 'Delete'
                      ? 'var(--status-overdue)'
                      : a === 'Mark Done'
                        ? 'var(--status-good)'
                        : 'var(--background-subtle)',
                }}
              >
                <Label
                  tracking={0.5}
                  style={{
                    color:
                      a === 'Delete' || a === 'Mark Done'
                        ? 'var(--background-primary)'
                        : 'var(--text-primary)',
                  }}
                >
                  {a}
                </Label>
              </div>
            )}
          </For>
        </div>
      </Show>
    </div>
  )
}

// --- ServiceRow -----------------------------------------------------------

export function ServiceRow(
  props: RowChrome & {
    service: Service
    vehicle: Vehicle
    /** Inside a status-grouped list the group header carries the WORD, so the
        row keeps only the shape — "Overdue" above "■ OVERDUE" was a stutter. */
    groupedByStatus?: boolean
  },
) {
  const s = () => props.service
  const urgent = () => s().status === 'overdue' || s().status === 'dueSoon'
  const showStatus = () => urgent() && !props.groupedByStatus

  return (
    <RowShell {...props} section={`Service: ${s().name}`}>
      {/* A thin full-height rule carries the status color as a THIRD channel;
          the tag on line two carries the word and the shape. */}
      <div
        aria-hidden="true"
        style={{
          'align-self': 'stretch',
          flex: '0 0 auto',
          width: s().status === 'overdue' ? '4px' : '2px',
          background: STATUS_COLOR[s().status],
        }}
      />

      <div style={{ flex: '1 1 auto', 'min-width': '0', display: 'flex', 'flex-direction': 'column', gap: '2px' }}>
        <div style={{ display: 'flex', 'align-items': 'baseline', gap: 'var(--space-sm)' }}>
          <Emphasis rank="primary" lines={2} as="div" style={{ flex: '1 1 auto', 'min-width': '0', 'text-align': 'left' }}>
            {s().name}
          </Emphasis>
          <Secondary
            style={{
              flex: '0 0 auto',
              color: urgent() ? STATUS_COLOR[s().status] : 'var(--text-tertiary)',
            }}
          >
            {remainingText(s(), props.vehicle)}
          </Secondary>
        </div>

        <div
          style={{
            display: 'flex',
            'align-items': 'center',
            gap: 'var(--space-sm)',
            'white-space': 'nowrap',
            overflow: 'hidden',
          }}
        >
          <Show
            when={showStatus()}
            fallback={<StatusMark status={s().status} />}
          >
            <StatusTag status={s().status} />
          </Show>
          <Secondary color="tertiary" style={{ overflow: 'hidden', 'text-overflow': 'ellipsis' }}>
            {dueLine(s())}
          </Secondary>
        </div>
      </div>

      <Show when={!props.selecting}>
        <Body color="tertiary" style={{ flex: '0 0 auto' }}>
          ›
        </Body>
      </Show>
    </RowShell>
  )
}

// --- ServiceEventRow ------------------------------------------------------

export type Indicator =
  | { kind: 'completed' }
  | { kind: 'bundledVisit'; count: number }

interface ServiceEventRowProps extends RowChrome {
  title: string
  indicator?: Indicator
  /**
   * Support facts, joined with `//` on ONE line that truncates.
   *
   * Was a wrapping flex row of separate items, which on a 375pt screen shattered
   * into "3 / days / ago" and "Toyota / de / Puerto / Rico". A support line must
   * degrade by truncating, never by breaking phrases apart.
   */
  metadata?: string[]
  amount?: number
}

/**
 * One row for every "this happened" list: service history, recent activity,
 * expenses. The amount is primary when present, otherwise the title.
 */
export function ServiceEventRow(props: ServiceEventRowProps) {
  const hasAmount = () => props.amount != null

  return (
    <RowShell {...props} section={`Event: ${props.title}`}>
      <Show when={props.indicator && !props.selecting}>
        <div
          aria-hidden="true"
          style={{
            flex: '0 0 auto',
            'min-width': '20px',
            display: 'flex',
            'align-items': 'center',
            'justify-content': 'center',
          }}
        >
          <Show
            when={props.indicator!.kind === 'bundledVisit'}
            fallback={<Body color="good">✓</Body>}
          >
            <Label color="accent" tracking={0}>
              {(props.indicator as { kind: 'bundledVisit'; count: number }).count}×
            </Label>
          </Show>
        </div>
      </Show>

      <div style={{ flex: '1 1 auto', 'min-width': '0', display: 'flex', 'flex-direction': 'column' }}>
        {/* Title and amount share a line, baseline-aligned, so the amount does
            not steal width from the metadata line below. */}
        <div style={{ display: 'flex', 'align-items': 'baseline', gap: 'var(--space-sm)', width: '100%' }}>
          <Show
            when={hasAmount()}
            fallback={
              <Emphasis rank="primary" lines={2} as="div" style={{ flex: '1 1 auto', 'min-width': '0', 'text-align': 'left' }}>
                {props.title}
              </Emphasis>
            }
          >
            <Body lines={2} as="div" style={{ flex: '1 1 auto', 'min-width': '0', 'text-align': 'left' }}>
              {props.title}
            </Body>
            {/* 15 Medium, not 20. The amount leads the row by weight and
                position; at heading size a list of amounts was a list of
                headings. */}
            <Emphasis rank="primary" style={{ flex: '0 0 auto' }}>
              {fmtCurrency(props.amount!)}
            </Emphasis>
          </Show>
        </div>

        <Show when={props.metadata?.length}>
          <Secondary
            color="tertiary"
            as="div"
            style={{
              width: '100%',
              'padding-top': '2px',
              'white-space': 'nowrap',
              overflow: 'hidden',
              'text-overflow': 'ellipsis',
              'text-align': 'left',
            }}
          >
            {props.metadata!.join('  //  ')}
          </Secondary>
        </Show>
      </div>
    </RowShell>
  )
}

/** Thin model-to-row adapter, mirroring ExpenseRow.swift. */
export function ExpenseRow(props: RowChrome & { log: ServiceLog; dateStyle?: 'relative' | 'day' }) {
  /* Ordered by how reliably it is wanted, because this line truncates: when
     it does, the vendor is what should fall off the end, not the date. */
  const metadata = (): string[] => {
    const d = props.log.performedAt
    const out = [
      props.dateStyle === 'day'
        ? d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
        : timeSince(d),
    ]
    if (props.log.mileage) out.push(`${fmtMileageBare(props.log.mileage)} mi`)
    if (props.log.vendor) out.push(props.log.vendor)
    return out
  }

  return (
    <ServiceEventRow
      {...props}
      title={props.log.name}
      indicator={
        props.log.bundledCount
          ? { kind: 'bundledVisit', count: props.log.bundledCount }
          : { kind: 'completed' }
      }
      metadata={metadata()}
      amount={props.log.cost}
    />
  )
}

export function ListDivider() {
  return <div style={{ height: '1px', background: 'var(--grid-line)' }} />
}

/** Rows separated by hairlines — the list body every section repeats. */
export function RowList<T>(props: { each: T[]; children: (item: T) => JSX.Element }) {
  return (
    <div style={{ display: 'flex', 'flex-direction': 'column' }}>
      <For each={props.each}>
        {(item, i) => (
          <>
            <Show when={i() > 0}>
              <ListDivider />
            </Show>
            {props.children(item)}
          </>
        )}
      </For>
    </div>
  )
}

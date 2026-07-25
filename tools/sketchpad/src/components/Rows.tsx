/*
 * ServiceRow and ServiceEventRow — the two list shells that repeat everywhere.
 *
 * Mirrors Views/Components/Lists/ServiceRow.swift and ServiceEventRow.swift
 * after Phase 2. Between them they replaced six drifted implementations, so a
 * change here is the highest-leverage change available to a readout screen.
 */
import { For, Show } from 'solid-js'
import { Body, Emphasis, Heading, Label, Secondary } from '../ui/Text'
import {
  daysUntil,
  fmtCurrency,
  fmtMileageBare,
  timeSince,
  type Service,
  type ServiceLog,
  type ServiceStatus,
} from '../data/fixtures'

const STATUS_COLOR: Record<ServiceStatus, string> = {
  overdue: 'var(--status-overdue)',
  dueSoon: 'var(--status-due-soon)',
  good: 'var(--status-good)',
  neutral: 'var(--status-neutral)',
}

// --- ServiceRow -----------------------------------------------------------

/**
 * The urgency eyebrow. This is the row's primary element: urgency is why the row
 * exists, so it leads.
 *
 * It differs from the service name on four channels — size (11 vs 20), weight
 * (Medium vs Medium at larger size), case (caps vs sentence), and color (status
 * vs textPrimary). An earlier attempt used 15 Medium against 15 Regular, which
 * is nearly invisible in JetBrains Mono and violated the two-channel rule.
 */
function urgencyText(service: Service): string | undefined {
  if (service.status === 'overdue') {
    const days = Math.abs(daysUntil(service.dueDate ?? new Date()))
    return `Overdue by ${days} days`
  }
  if (service.status === 'dueSoon') {
    const days = daysUntil(service.dueDate ?? new Date())
    return `Due in ${days} days`
  }
  return undefined
}

export function ServiceRow(props: { service: Service; onClick?: () => void }) {
  const s = () => props.service
  const urgency = () => urgencyText(s())
  const color = () => STATUS_COLOR[s().status]

  const supportLine = () => {
    const parts: string[] = []
    if (s().dueMileage) parts.push(`At ${fmtMileageBare(s().dueMileage!)} mi`)
    if (s().lastPerformedAt) parts.push(`Last done ${timeSince(s().lastPerformedAt!).toLowerCase()}`)
    return parts.join('  //  ')
  }

  return (
    <button
      data-section={`Service: ${s().name}`}
      onClick={props.onClick}
      style={{
        display: 'flex',
        'align-items': 'stretch',
        gap: 'var(--space-md)',
        width: '100%',
        padding: 'var(--space-list-item) 0',
      }}
    >
      {/* Full-height rule, not an 8×8 dot in a 32×32 tint. Width encodes urgency
          as a second channel alongside color. */}
      <div
        aria-hidden="true"
        style={{
          flex: '0 0 auto',
          width: s().status === 'overdue' ? '4px' : '2px',
          background: color(),
        }}
      />

      <div style={{ flex: '1 1 auto', 'min-width': '0', display: 'flex', 'flex-direction': 'column' }}>
        <Show when={urgency()}>
          <Label
            rank="primary"
            style={{ color: color() }}
            uppercase
            tracking={1.5}
            as="div"
          >
            {urgency()}
          </Label>
        </Show>

        {/* When there is no urgency to lead with — a healthy item — the name is
            the primary. Without this a on-track row had NO primary at all, so
            the list lost its reading order exactly where nothing was wrong. */}
        <Heading lines={2} as="div" rank={urgency() ? undefined : 'primary'}>
          {s().name}
        </Heading>

        <Secondary color="tertiary" as="div" style={{ 'padding-top': 'var(--space-xs)' }}>
          {supportLine()}
        </Secondary>
      </div>

      <div style={{ flex: '0 0 auto', display: 'flex', 'align-items': 'center' }}>
        <Body color="tertiary">›</Body>
      </div>
    </button>
  )
}

// --- ServiceEventRow ------------------------------------------------------

export type Indicator =
  | { kind: 'completed' }
  | { kind: 'bundledVisit'; count: number }
  | { kind: 'category'; symbol: string }

export interface Metadatum {
  text: string
  /** A tag renders tinted; a detail renders as ordinary support text. */
  tag?: boolean
  color?: string
}

interface ServiceEventRowProps {
  title: string
  indicator?: Indicator
  metadata?: Metadatum[]
  amount?: number
  onClick?: () => void
}

/**
 * One row for every "this happened" list: service history, recent activity,
 * expenses, visit expenses.
 *
 * Hierarchy: the amount is primary when present, otherwise the title. That
 * settles a prior inconsistency where cost rendered at body weight in two
 * places and heading weight in a third.
 */
export function ServiceEventRow(props: ServiceEventRowProps) {
  const hasAmount = () => props.amount != null

  return (
    <button
      data-section={`Event: ${props.title}`}
      onClick={props.onClick}
      style={{
        display: 'flex',
        'align-items': 'center',
        gap: 'var(--space-md)',
        width: '100%',
        padding: 'var(--space-list-item) 0',
      }}
    >
      <Show when={props.indicator}>
        {(ind) => (
          <div
            aria-hidden="true"
            style={{
              flex: '0 0 auto',
              width: '20px',
              display: 'flex',
              'align-items': 'center',
              'justify-content': 'center',
            }}
          >
            <Show when={ind().kind === 'completed'}>
              <Body color="good">✓</Body>
            </Show>
            <Show when={ind().kind === 'bundledVisit'}>
              <Label color="accent" tracking={0}>
                {(ind() as { kind: 'bundledVisit'; count: number }).count}×
              </Label>
            </Show>
            <Show when={ind().kind === 'category'}>
              <Body color="tertiary">
                {(ind() as { kind: 'category'; symbol: string }).symbol}
              </Body>
            </Show>
          </div>
        )}
      </Show>

      <div style={{ flex: '1 1 auto', 'min-width': '0', display: 'flex', 'flex-direction': 'column' }}>
        <Show
          when={hasAmount()}
          fallback={
            <Emphasis rank="primary" lines={2} as="div">
              {props.title}
            </Emphasis>
          }
        >
          <Body lines={2} as="div">
            {props.title}
          </Body>
        </Show>

        <Show when={props.metadata?.length}>
          <div
            style={{
              display: 'flex',
              'align-items': 'center',
              gap: 'var(--space-xs)',
              'padding-top': '2px',
            }}
          >
            <For each={props.metadata}>
              {(m, i) => (
                <>
                  <Show when={i() > 0}>
                    <Secondary color="tertiary">//</Secondary>
                  </Show>
                  <Secondary
                    color="tertiary"
                    style={m.color ? { color: m.color } : undefined}
                    uppercase={m.tag}
                    tracking={m.tag ? 1 : undefined}
                  >
                    {m.text}
                  </Secondary>
                </>
              )}
            </For>
          </div>
        </Show>
      </div>

      <Show when={hasAmount()}>
        <Heading rank="primary" style={{ flex: '0 0 auto' }}>
          {fmtCurrency(props.amount!)}
        </Heading>
      </Show>
    </button>
  )
}

/** Thin model-to-row adapter, mirroring ExpenseRow.swift. */
export function ExpenseRow(props: { log: ServiceLog; onClick?: () => void }) {
  const metadata = (): Metadatum[] => {
    const out: Metadatum[] = [{ text: timeSince(props.log.performedAt) }]
    if (props.log.mileage) out.push({ text: `${fmtMileageBare(props.log.mileage)} mi` })
    if (props.log.vendor) out.push({ text: props.log.vendor })
    return out
  }

  return (
    <ServiceEventRow
      title={props.log.name}
      indicator={
        props.log.bundledCount
          ? { kind: 'bundledVisit', count: props.log.bundledCount }
          : { kind: 'completed' }
      }
      metadata={metadata()}
      amount={props.log.cost}
      onClick={props.onClick}
    />
  )
}

export function ListDivider() {
  return <div style={{ height: '1px', background: 'var(--grid-line)' }} />
}

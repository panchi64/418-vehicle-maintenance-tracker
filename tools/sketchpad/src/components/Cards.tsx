/*
 * The hero cards. These are the parts of Checkpoint that already work — they
 * commit to a single dominant datum — so the sketchpad reproduces them faithfully
 * rather than reinterpreting them. They are the reference for what "one primary"
 * looks like when done right; the rest of the app is being brought up to them.
 */
import { For, Show } from 'solid-js'
import { Body, Emphasis, Heading, Hero, Label, Secondary, Title } from '../ui/Text'
import { ReadoutSection } from '../ui/ReadoutSection'
import {
  daysUntil,
  fmtCurrencyWhole,
  fmtMileage,
  fmtMileageBare,
  type Service,
  type ServiceStatus,
  type Vehicle,
} from '../data/fixtures'

const STATUS_COLOR: Record<ServiceStatus, string> = {
  overdue: 'var(--status-overdue)',
  dueSoon: 'var(--status-due-soon)',
  good: 'var(--status-good)',
  neutral: 'var(--status-neutral)',
}

const STATUS_LABEL: Record<ServiceStatus, string> = {
  overdue: 'Overdue',
  dueSoon: 'Due soon',
  good: 'On track',
  neutral: 'No schedule',
}

/**
 * Extracted from two byte-identical blocks in NextUpCard.swift.
 *
 * The status square is baseline-aligned to the label rather than centered — as
 * centered geometry it read as misaligned against the text beside it.
 */
export function UpcomingItemHeader(props: { status: ServiceStatus; pulse?: boolean }) {
  return (
    <div style={{ display: 'flex', 'align-items': 'baseline', gap: 'var(--space-sm)' }}>
      <div
        aria-hidden="true"
        class={props.pulse ? 'pulse' : undefined}
        style={{
          width: '8px',
          height: '8px',
          flex: '0 0 auto',
          background: STATUS_COLOR[props.status],
          'box-shadow': `0 0 12px ${STATUS_COLOR[props.status]}`,
          // Sits on the text baseline instead of the line box's centre.
          transform: 'translateY(-1px)',
        }}
      />
      <Label style={{ color: STATUS_COLOR[props.status] }} tracking={1.5}>
        {STATUS_LABEL[props.status]}
      </Label>
    </div>
  )
}

/** The 56pt number that makes this card work. */
function DuePeriodHero(props: { value: string; unit: string; label?: string }) {
  return (
    <div style={{ display: 'flex', 'flex-direction': 'column' }}>
      <div style={{ display: 'flex', 'align-items': 'baseline', gap: 'var(--space-sm)' }}>
        <Hero rank="primary">{props.value}</Hero>
        <Title color="secondary" style={{ font: 'var(--font-heading)' }}>
          {props.unit}
        </Title>
      </div>
      {/* Optional: the marbete card omits it because its footer already says
          EXPIRES, and printing it twice was the bug. */}
      <Show when={props.label}>
        <Label>{props.label}</Label>
      </Show>
    </div>
  )
}

export function NextUpCard(props: { service: Service; vehicle: Vehicle; onClick?: () => void }) {
  const s = () => props.service
  const days = () => daysUntil(s().dueDate ?? new Date())

  const heroValue = () => String(Math.abs(days()))
  const heroUnit = () => (Math.abs(days()) === 1 ? 'day' : 'days')
  const heroLabel = () => (days() < 0 ? 'Overdue' : 'Until due')

  const milesRemaining = () =>
    s().dueMileage != null ? s().dueMileage! - props.vehicle.currentMileage : undefined

  return (
    <button
      data-section="Next up"
      onClick={props.onClick}
      style={{
        display: 'flex',
        'flex-direction': 'column',
        gap: 'var(--space-md)',
        width: '100%',
        padding: 'var(--card-padding)',
        border: `var(--border-width) solid ${STATUS_COLOR[s().status]}`,
        background: `color-mix(in srgb, ${STATUS_COLOR[s().status]} 10%, var(--surface-instrument))`,
      }}
    >
      <div
        style={{
          display: 'flex',
          'align-items': 'baseline',
          'justify-content': 'space-between',
          width: '100%',
        }}
      >
        <UpcomingItemHeader status={s().status} pulse={s().status !== 'good'} />
        <Label>Next up</Label>
      </div>

      <Heading as="div" lines={2} style={{ 'text-align': 'left', width: '100%' }}>
        {s().name}
      </Heading>

      <DuePeriodHero value={heroValue()} unit={heroUnit()} label={heroLabel()} />

      <div
        style={{
          display: 'flex',
          gap: 'var(--space-md)',
          width: '100%',
          'padding-top': 'var(--space-sm)',
          'border-top': '1px solid var(--grid-line)',
        }}
      >
        <Show when={milesRemaining() != null}>
          <Secondary color="tertiary">
            {milesRemaining()! < 0
              ? `${fmtMileageBare(Math.abs(milesRemaining()!))} mi past`
              : `${fmtMileageBare(milesRemaining()!)} mi to go`}
          </Secondary>
        </Show>
        <Show when={s().intervalMonths || s().intervalMiles}>
          <Secondary color="tertiary" style={{ 'margin-left': 'auto' }}>
            Every{' '}
            {[
              s().intervalMonths ? `${s().intervalMonths} mo` : null,
              s().intervalMiles ? `${fmtMileageBare(s().intervalMiles!)} mi` : null,
            ]
              .filter(Boolean)
              .join(' / ')}
          </Secondary>
        </Show>
      </div>
    </button>
  )
}

// --- Cost hero ------------------------------------------------------------

export function CostHeadlineCard(props: { total: number; periodLabel: string; delta?: number }) {
  return (
    <div
      data-section="Cost headline"
      style={{
        display: 'flex',
        'flex-direction': 'column',
        padding: 'var(--card-padding)',
        border: 'var(--border-width) solid var(--border-subtle)',
        background: 'var(--surface-instrument)',
      }}
    >
      <Label>{props.periodLabel}</Label>
      <Hero rank="primary">{fmtCurrencyWhole(props.total)}</Hero>
      <Show when={props.delta != null}>
        <Secondary style={{ color: props.delta! > 0 ? 'var(--status-overdue)' : 'var(--status-good)' }}>
          {props.delta! > 0 ? '▲' : '▼'} {Math.abs(props.delta!)}% vs prior period
        </Secondary>
      </Show>
    </div>
  )
}

/** StatsCard — a grid of small readouts, each with its own single value. */
export function StatsGrid(props: { stats: { label: string; value: string }[] }) {
  return (
    <div
      style={{
        display: 'grid',
        'grid-template-columns': 'repeat(2, 1fr)',
        gap: '1px',
        background: 'var(--grid-line)',
        border: 'var(--border-width) solid var(--border-subtle)',
      }}
    >
      <For each={props.stats}>
        {(stat) => (
          <div
            data-section={`Stat: ${stat.label}`}
            style={{
              display: 'flex',
              'flex-direction': 'column',
              gap: '2px',
              padding: 'var(--space-md)',
              background: 'var(--surface-instrument)',
            }}
          >
            <Label>{stat.label}</Label>
            <Heading rank="primary">{stat.value}</Heading>
          </div>
        )}
      </For>
    </div>
  )
}

// --- Specs panel ----------------------------------------------------------

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
]

/**
 * QuickSpecsCard, as a panel rather than a card. It lost its own header and
 * border when the trigger moved into VehicleHeader: it now hangs off the header
 * and the header owns the disclosure, so a second frame around it was one
 * enclosure too many.
 *
 * Ordered by why you opened it. VIN leads because it is the reason this panel
 * gets tapped — it is needed rarely but needed *exactly*, and it is the one spec
 * too long to sit in the collapsed strip. Plate, trim, and engine come last
 * because the strip already showed them; they are here for completeness and for
 * the narrow screens where the strip truncates.
 */
export function QuickSpecsPanel(props: { vehicle: Vehicle; onEdit?: () => void }) {
  const rows = () => {
    const v = props.vehicle
    return [
      ['VIN', v.vin],
      ['Transmission', v.transmission ?? '—'],
      ['Drivetrain', v.drivetrain ?? '—'],
      ['Fuel', v.fuelType ?? '—'],
      ['Marbete', v.marbeteMonth ? MONTHS[v.marbeteMonth - 1] : '—'],
      ['Plate', v.licensePlate ?? '—'],
      ['Trim', v.trim ?? '—'],
      ['Engine', v.engine ?? '—'],
    ] as const
  }

  return (
    <div
      data-section="Specs"
      style={{
        display: 'flex',
        'flex-direction': 'column',
        gap: 'var(--space-sm)',
        padding: 'var(--space-md) var(--space-screen-h)',
        background: 'var(--background-subtle)',
        'border-bottom': 'var(--border-width) solid var(--grid-line)',
      }}
    >
      <For each={rows()}>
        {([label, value]) => (
          <div
            style={{
              display: 'flex',
              'align-items': 'baseline',
              'justify-content': 'space-between',
              gap: 'var(--space-md)',
            }}
          >
            <Label>{label}</Label>
            <Body style={{ 'text-align': 'right', 'word-break': 'break-all' }}>{value}</Body>
          </div>
        )}
      </For>

      <button
        onClick={props.onEdit}
        style={{ 'min-height': 'var(--touch-target)', display: 'flex', 'align-items': 'center' }}
      >
        <Label color="accent" tracking={1}>
          [Edit vehicle]
        </Label>
      </button>
    </div>
  )
}

// --- Mileage-driven readout (Phase 3 target for the removed YTD subline) ---

export function MileageReadout(props: { vehicle: Vehicle }) {
  const v = () => props.vehicle
  const delta = () => {
    const prior = v().milesDrivenSamePeriodLastYear
    if (!prior) return undefined
    return Math.round(((v().milesDrivenYearToDate - prior) / prior) * 100)
  }

  return (
    <ReadoutSection
      title="Miles this year"
      // No `rank` prop on the Title below: ReadoutSection's primary slot already
      // declares the primary, and declaring it twice is how a section ends up
      // claiming two.
      primary={
        <div style={{ display: 'flex', 'align-items': 'baseline', gap: 'var(--space-sm)' }}>
          <Title>{fmtMileageBare(v().milesDrivenYearToDate)}</Title>
          <Body color="tertiary">mi</Body>
        </div>
      }
      supporting={
        <Show when={delta() != null}>
          <Secondary color="tertiary">
            {delta()! > 0 ? '▲' : '▼'} {Math.abs(delta()!)}% vs the same period last year (
            {fmtMileageBare(v().milesDrivenSamePeriodLastYear)} mi)
          </Secondary>
        </Show>
      }
    />
  )
}

export function OdometerReadout(props: { vehicle: Vehicle; onUpdate?: () => void }) {
  return (
    <ReadoutSection
      title="Odometer"
      action={{ label: 'Update', onClick: props.onUpdate }}
      primary={<Emphasis>{fmtMileage(props.vehicle.currentMileage)}</Emphasis>}
    />
  )
}

/*
 * The hero card and the specs panel.
 *
 * NEXT UP NOW ENDS IN AN ACTION. The card used to be a readout you tapped
 * through to a detail screen, then found Mark Done on, then confirmed in a
 * sheet — four taps to close the loop on the one thing the whole Home tab
 * exists to surface. It now carries a primary MARK DONE button, which opens
 * the unified service form pre-filled for completion, so the loop is two taps
 * (Mark Done → Save).
 *
 *   ┌───────────────────────────────────────────┐
 *   │ ■ OVERDUE                        NEXT UP  │  status: word + shape
 *   │ Oil & Filter Change                       │  20 Medium
 *   │ 917 mi  over                              │  56 Light hero (the primary)
 *   │ Due 32,500 mi or Jul 4                    │  13 support — ONE line;
 *   │                                           │  the interval is detail
 *   │ [ Mark Done ]                             │  48pt, filled accent
 *   └───────────────────────────────────────────┘
 *
 * THE HERO SHOWS WHICHEVER TRIGGER IS CLOSER. Oil is due by miles OR by date,
 * whichever first; the card used to always print days, so an oil change 917 mi
 * past due read "21 days" — true, and the less urgent of the two facts. Miles
 * are converted to days at the vehicle's pace to decide which leads
 * (`remaining()` in data/scenario.ts), and that figure becomes the hero.
 *
 * THE MARBETE TAKES THE HERO WHEN IT IS THE MOST URGENT ITEM. It has no
 * odometer relationship, so its hero is always days, and the unit is days
 * even at 1 ("1 day") — the number is the thing to be unmissable. Its action
 * reads "Mark Renewed": the sticker is renewed, not serviced. Same component;
 * the differences are props, not a fork.
 *
 * The card is no longer itself a <button>. A button inside a button is
 * invalid and, on device, makes the inner target ambiguous. The card body
 * still pushes the detail view; Mark Done is a separate target.
 */
import { For } from 'solid-js'
import { Body, Emphasis, Heading, Hero, Label, Secondary } from '../ui/Text'
import { dueLine, STATUS_COLOR, StatusTag } from './status'
import { fmtMileageBare, type Service, type Vehicle } from '../data/fixtures'
import { isMarbete, remaining } from '../data/scenario'

export function NextUpCard(props: {
  service: Service
  vehicle: Vehicle
  onOpen?: () => void
  onMarkDone?: () => void
}) {
  const s = () => props.service
  const marbete = () => isMarbete(s())
  const r = () => remaining(s(), props.vehicle)
  const leadMiles = () => !marbete() && r().lead === 'miles' && r().miles != null

  const heroValue = () =>
    leadMiles() ? fmtMileageBare(Math.abs(r().miles!)) : String(Math.abs(r().days ?? 0))
  const heroUnit = () =>
    leadMiles() ? 'mi' : Math.abs(r().days ?? 0) === 1 ? 'day' : 'days'
  const past = () => (leadMiles() ? r().miles! < 0 : (r().days ?? 0) < 0)
  const heroQualifier = () => (past() ? 'over' : marbete() ? 'to expiry' : 'left')

  const color = () => STATUS_COLOR[s().status]

  return (
    <div
      data-section="Next up"
      style={{
        display: 'flex',
        'flex-direction': 'column',
        gap: 'var(--space-sm)',
        width: '100%',
        padding: 'var(--card-padding)',
        border: `var(--border-width) solid ${color()}`,
        background: `color-mix(in srgb, ${color()} 8%, var(--surface-instrument))`,
      }}
    >
      <button
        onClick={props.onOpen}
        style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-sm)', width: '100%' }}
      >
        <div style={{ display: 'flex', 'align-items': 'center', 'justify-content': 'space-between', width: '100%' }}>
          <StatusTag status={s().status} />
          <Label>Next up</Label>
        </div>

        <Heading as="div" lines={2} style={{ 'text-align': 'left', width: '100%' }}>
          {s().name}
        </Heading>

        <div style={{ display: 'flex', 'align-items': 'baseline', gap: 'var(--space-sm)', 'flex-wrap': 'wrap' }}>
          <Hero rank="primary">{heroValue()}</Hero>
          <Heading color="secondary">{heroUnit()}</Heading>
          <Body color="secondary">{heroQualifier()}</Body>
        </div>

        <Secondary color="tertiary" as="div" style={{ 'text-align': 'left', width: '100%' }}>
          {marbete() ? dueLine(s()).replace('Due', 'Expires') : dueLine(s())}
        </Secondary>
      </button>

      <button
        onClick={props.onMarkDone}
        data-action="mark-done"
        style={{
          'margin-top': 'var(--space-xs)',
          'min-height': 'var(--button-height)',
          display: 'flex',
          'align-items': 'center',
          'justify-content': 'center',
          background: 'var(--accent)',
          border: 'var(--border-width) solid var(--accent)',
        }}
      >
        <Emphasis style={{ color: 'var(--background-primary)' }}>
          {marbete() ? 'Mark Renewed' : 'Mark Done'}
        </Emphasis>
      </button>
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
 * border when the trigger moved into the header band: it now hangs off the band
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


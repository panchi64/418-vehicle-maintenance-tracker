/*
 * VehicleBand — the odometer + specs strip at the top of Home.
 *
 * WHAT CHANGED. This was VehicleHeader: persistent chrome on every tab, with a
 * [SELECT] link, the vehicle name as a 32pt title, a gear, and this two-cell
 * band. The iOS 26 shell took over the first three — the NavigationStack's
 * large title IS the vehicle name, its title menu switches vehicles, and
 * Settings is a toolbar item — so the only part left with a job is the band.
 *
 * It lives on Home only. Services and Costs never needed the odometer at the
 * top of the screen, and repeating it cost them ~55pt of list.
 *
 *   ──────────────────────┬──────────────────────
 *   ODOMETER   □ 9 D OLD › │ SPECS             ⌄
 *   33,417 mi             │ IWK-482 · XLE Premium
 *
 * STALE FLAG. Word + shape, never a lone dot: an outlined square (the due-soon
 * mark) and "9 d old". The bare 6pt square it replaces carried the whole
 * meaning in color.
 *
 * PORT NOTE: tap on the odometer cell opens the mileage update sheet; tap on
 * specs expands QuickSpecsPanel in place (fade only).
 *
 * SPECS STRIP, iteration history (it took five tries; read before revisiting):
 *   v1  A full bordered QuickSpecsCard below the header.   Too heavy.
 *   v2  A bare `SPECS ⌄` label inside the header.          Read as a caption.
 *   v3  A bordered chip.                                   Foreign to the header.
 *   v4  Bracket notation `[SPECS] ⌄`.                      Right vocabulary, but
 *       the target was only as wide as the word (~70×44), and collapsing the
 *       panel meant NOTHING was visible by default — the trim and plate that used
 *       to be glanceable on Home became two taps away.
 *   v5  (this) The collapsed row IS the summary. Full-width target, and its
 *       label is real data, so the at-a-glance reference survives while the long
 *       tail (VIN, engine, transmission, drivetrain, marbete) stays one tap away.
 */
import { Show } from 'solid-js'
import { Label, Secondary } from '../ui/Text'
import { StatusMark } from './status'
import { daysUntil, fmtMileage, type Vehicle } from '../data/fixtures'

interface VehicleBandProps {
  vehicle: Vehicle
  specsExpanded: boolean
  onToggleSpecs: () => void
  onUpdateMileage?: () => void
}

/** A reading older than this is flagged. Matches the app's stale threshold. */
const STALE_DAYS = 7

export function VehicleBand(props: VehicleBandProps) {
  /* Plate and trim only. Adding the engine truncated mid-word at 393pt, and a
     line ending in "2.5L I4…" is not glanceable. VIN is in the panel. */
  const summary = () =>
    [props.vehicle.licensePlate, props.vehicle.trim].filter(Boolean).join('  ·  ')

  const age = () => -daysUntil(props.vehicle.mileageUpdatedAt)

  return (
    <div
      /* Wraps to two full-width rows at large type (AdaptiveStack in the
         port): at 2x on a 375pt screen the specs cell was crushed to 56pt. */
      style={{
        display: 'flex',
        'flex-wrap': 'wrap',
        'align-items': 'stretch',
        flex: '0 0 auto',
        'border-top': '1px solid var(--grid-line)',
        'border-bottom': 'var(--border-width) solid var(--grid-line)',
      }}
    >
      <HeaderCell
        label="Odometer"
        value={fmtMileage(props.vehicle.currentMileage)}
        valueColor="accent"
        glyph="›"
        flag={age() >= STALE_DAYS ? `${age()} d old` : undefined}
        onClick={props.onUpdateMileage}
      />

      <div aria-hidden="true" style={{ width: '1px', background: 'var(--grid-line)' }} />

      <HeaderCell
        label="Specs"
        value={summary() || '—'}
        glyph="⌄"
        glyphRotated={props.specsExpanded}
        active={props.specsExpanded}
        grow
        onClick={props.onToggleSpecs}
        expanded={props.specsExpanded}
      />
    </div>
  )
}

/**
 * One cell of the header's data band. Both cells share this so they cannot drift
 * apart — the odometer and the specs strip are the same kind of thing and should
 * stay the same shape.
 */
function HeaderCell(props: {
  label: string
  value: string
  valueColor?: 'primary' | 'accent'
  glyph: string
  glyphRotated?: boolean
  /** Stale-reading tag: word + shape, e.g. "9 d old". */
  flag?: string
  active?: boolean
  /** Set on the cell that should absorb the leftover width. */
  grow?: boolean
  expanded?: boolean
  onClick?: () => void
}) {
  return (
    <button
      onClick={props.onClick}
      aria-expanded={props.expanded}
      aria-label={props.label}
      style={{
        display: 'flex',
        'flex-direction': 'column',
        'justify-content': 'center',
        gap: '2px',
        flex: props.grow ? '1 1 calc(150px * var(--type-scale))' : '0 1 auto',
        'min-width': '0',
        'min-height': '54px',
        padding: `var(--space-sm) var(--space-screen-h)`,
        background: props.active ? 'var(--background-subtle)' : 'transparent',
        transition: 'background var(--anim-fast) ease-out',
      }}
    >
      <div
        style={{
          display: 'flex',
          'flex-wrap': 'wrap',
          'align-items': 'center',
          gap: 'var(--space-xs)',
          width: '100%',
        }}
      >
        <Label style={{ 'text-align': 'left' }}>{props.label}</Label>
        <Show when={props.flag}>
          <span
            style={{
              display: 'inline-flex',
              'align-items': 'center',
              gap: '3px',
              color: 'var(--status-due-soon)',
              font: 'var(--font-label-bold)',
            }}
          >
            <StatusMark status="dueSoon" />
            <Label style={{ color: 'inherit', font: 'inherit' }} tracking={1}>
              {props.flag}
            </Label>
          </span>
        </Show>
        <div style={{ flex: '1 1 auto' }} />

        <span
          aria-hidden="true"
          style={{
            flex: '0 0 auto',
            font: 'var(--font-label)',
            color: 'var(--accent)',
            display: 'inline-block',
            transform: props.glyphRotated ? 'rotate(180deg)' : 'rotate(0deg)',
            transition: 'transform var(--anim-medium) ease-out',
          }}
        >
          {props.glyph}
        </span>
      </div>

      <Secondary
        color={props.valueColor === 'accent' ? 'accent' : 'secondary'}
        lines={1}
        style={{ width: '100%', 'text-align': 'left', font: 'var(--font-body)' }}
      >
        {props.value}
      </Secondary>
    </button>
  )
}

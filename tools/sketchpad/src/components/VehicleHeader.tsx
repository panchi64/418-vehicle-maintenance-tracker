/*
 * VehicleHeader — persistent chrome, present on every tab.
 *
 * Mirrors Views/Components/Navigation/VehicleHeader.swift.
 *
 * STRUCTURE: full-width bands, ending in a two-cell data band.
 *
 *   [SELECT]                                    ⚙     chrome
 *   DAILY DRIVER                                      identity (the one primary)
 *   Toyota RAV4 · 2026                                identity support
 *   ──────────────────────┬──────────────────────
 *   ODOMETER            › │ SPECS             ⌄      data cells, side by side
 *   33,417 mi             │ IWK-482 · XLE Premium
 *
 * The version before this was two independent vertical stacks placed beside each
 * other — [SELECT]/name/spec-line on the left, gear/[UPDATE]/mileage on the
 * right — with no shared baseline or grid between them. Nothing lined up with
 * anything, so the name read as dropped into the corner of a header rather than
 * belonging to it. Two stacks is not a layout; it is two layouts.
 *
 * Bands fix three things:
 *
 *   1. Every element sits on one vertical rhythm and one left edge, so alignment
 *      is structural rather than coincidental.
 *   2. The name gets the FULL width. It previously competed with the odometer for
 *      horizontal space, which is why it clipped to "DAILY…" at 375pt.
 *   3. The odometer gains a label, so its meaning is stated rather than inferred
 *      from a bare number under a gear icon.
 *
 * The odometer and specs sit SIDE BY SIDE rather than as two stacked bands. As
 * separate full-width strips they read as two unrelated rules across the screen
 * and cost ~38pt more height; they are both "reference data about this vehicle,
 * tap for more", so one line is honest and cheaper. Net height is close to the
 * original two-column header despite the added structure.
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
import { Label, Secondary, Title } from '../ui/Text'
import { fmtMileage, type Vehicle } from '../data/fixtures'

interface VehicleHeaderProps {
  vehicle?: Vehicle
  specsExpanded: boolean
  onToggleSpecs: () => void
  onSelectVehicle?: () => void
  onUpdateMileage?: () => void
  onSettings?: () => void
  /** Set when the odometer reading is old enough to prompt for a refresh. */
  mileageStale?: boolean
}

/** Shared inset, so every band lines up on the same left and right edge. */
const INSET = '0 var(--space-screen-h)'

export function VehicleHeader(props: VehicleHeaderProps) {
  const displayName = () => {
    const v = props.vehicle
    if (!v) return 'Select vehicle'
    return v.name || `${v.year} ${v.make} ${v.model}`
  }

  /* The make/model/year line only earns its place when the user gave the vehicle
     a nickname. Without one, displayName is already "2026 Toyota RAV4", so this
     line repeated every word above it. */
  const specLine = () => {
    const v = props.vehicle
    if (!v || !v.name) return undefined
    return `${v.make} ${v.model} · ${v.year}`
  }

  /* What the collapsed strip shows: the plate, needed constantly (parking,
     forms, the marbete line), and the trim, which identifies the car when
     ordering parts.

     Held to two values on purpose. Adding the engine truncated mid-word at
     393pt, and a line ending in "2.5L I4…" is not glanceable — it only signals
     that something was cut. VIN is deliberately absent: 17 characters would
     consume the row, and it is needed rarely but *exactly*, which is what the
     expanded panel is for. */
  const summary = () => {
    const v = props.vehicle
    if (!v) return undefined
    return [v.licensePlate, v.trim].filter(Boolean).join('  ·  ')
  }

  return (
    <header
      data-section="Vehicle header"
      style={{
        display: 'flex',
        'flex-direction': 'column',
        'border-bottom': 'var(--border-width) solid var(--grid-line)',
      }}
    >
      {/* --- Band 1: chrome. Two small elements, one baseline. --------------
          The 44pt targets overflow this 28pt band via negative margin, so the
          band's height is set by what you can see rather than by the hit area. */}
      <div
        style={{
          display: 'flex',
          'align-items': 'center',
          'justify-content': 'space-between',
          height: '28px',
          padding: INSET,
        }}
      >
        <button
          onClick={props.onSelectVehicle}
          aria-label="Select vehicle"
          style={{
            display: 'flex',
            'align-items': 'center',
            height: 'var(--touch-target)',
            margin: 'calc((var(--touch-target) - 28px) / -2) 0',
          }}
        >
          <Label color="accent" tracking={1}>
            [Select]
          </Label>
        </button>

        <button
          onClick={props.onSettings}
          aria-label="Settings"
          style={{
            display: 'flex',
            'align-items': 'center',
            'justify-content': 'flex-end',
            width: 'var(--touch-target)',
            height: 'var(--touch-target)',
            margin: 'calc((var(--touch-target) - 28px) / -2) calc(var(--space-screen-h) * -1) calc((var(--touch-target) - 28px) / -2) 0',
            'padding-right': 'var(--space-screen-h)',
          }}
        >
          <span style={{ font: 'var(--font-heading)', color: 'var(--text-tertiary)' }}>⚙</span>
        </button>
      </div>

      {/* --- Band 2: identity. Full width, so it never competes for space. --- */}
      <button
        onClick={props.onSelectVehicle}
        style={{
          display: 'flex',
          'flex-direction': 'column',
          'align-items': 'flex-start',
          padding: INSET,
          'padding-bottom': 'var(--space-sm)',
        }}
      >
        <Title class="vh-name" rank="primary" lines={1} as="div">
          {displayName()}
        </Title>
        <Show when={specLine()}>
          <Secondary color="tertiary" lines={1} as="div">
            {specLine()}
          </Secondary>
        </Show>
      </button>

      {/* --- Band 3: odometer and specs, side by side. ---------------------
          Two cells of the same shape — label row, then value row — split by a
          rule. Stacking them as two separate full-width bands read as two
          unrelated strips and cost ~38pt more height; they are both "reference
          data about this vehicle, tap for more", so they belong on one line.

          The trailing glyphs differ on purpose: `›` opens a sheet, `⌄` expands
          in place. Using the same glyph for both would promise the same
          behaviour from two controls that behave differently. */}
      <Show when={props.vehicle}>
        {(v) => (
          <div
            style={{
              display: 'flex',
              'align-items': 'stretch',
              'border-top': '1px solid var(--grid-line)',
            }}
          >
            <HeaderCell
              label="Odometer"
              value={fmtMileage(v().currentMileage)}
              valueColor="accent"
              glyph="›"
              flag={props.mileageStale}
              onClick={props.onUpdateMileage}
            />

            <div aria-hidden="true" style={{ width: '1px', background: 'var(--grid-line)' }} />

            <HeaderCell
              label="Specs"
              /* Not uppercased. These are values, not labels — and the panel
                 below renders the same trim in sentence case, so uppercasing
                 here would show one datum two different ways. */
              value={summary() ?? '—'}
              glyph="⌄"
              glyphRotated={props.specsExpanded}
              active={props.specsExpanded}
              grow
              onClick={props.onToggleSpecs}
              expanded={props.specsExpanded}
            />
          </div>
        )}
      </Show>
    </header>
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
  /** Small status square beside the label, e.g. a stale odometer reading. */
  flag?: boolean
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
        flex: props.grow ? '1 1 auto' : '0 0 auto',
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
          'align-items': 'center',
          gap: 'var(--space-xs)',
          width: '100%',
        }}
      >
        <Show when={props.flag}>
          <div
            aria-hidden="true"
            style={{
              width: '6px',
              height: '6px',
              flex: '0 0 auto',
              background: 'var(--status-due-soon)',
            }}
          />
        </Show>

        <Label style={{ flex: '1 1 auto', 'text-align': 'left' }}>{props.label}</Label>

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

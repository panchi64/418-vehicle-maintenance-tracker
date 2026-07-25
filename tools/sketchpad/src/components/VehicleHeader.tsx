/*
 * VehicleHeader — persistent chrome, present on every tab.
 *
 * Mirrors Views/Components/Navigation/VehicleHeader.swift.
 *
 * The specs strip is the part that took the most iteration, so the reasoning is
 * worth recording:
 *
 *   v1  A full bordered QuickSpecsCard below the header.   Too heavy.
 *   v2  A bare `SPECS ⌄` label inside the header.          Read as a caption.
 *   v3  A bordered chip.                                   Foreign to the header.
 *   v4  Bracket notation `[SPECS] ⌄`.                      Right vocabulary, but
 *       the target was only as wide as the word (~70×44), and collapsing the
 *       panel meant NOTHING was visible by default — the trim, engine, and plate
 *       that used to be glanceable on Home were now two taps away.
 *   v5  (this) The collapsed row IS the summary.
 *
 * v5 resolves both faults at once. The strip spans the full width, so the target
 * is the whole row rather than a word. And its collapsed label is real data —
 * the plate and trim — so the at-a-glance reference survives, while the long
 * tail (VIN, engine, transmission, drivetrain, marbete) stays one tap away.
 *
 * The affordance is carried by the chevron, the full-bleed rule above, and the
 * row's own hit area, so it does not need brackets to read as a control. Bracket
 * notation stays on `[SELECT]` and `[UPDATE]`, where the control IS the text.
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

     Held to two values on purpose. Adding the engine truncated mid-word on a
     393pt screen, and a line that ends in "2.5L I4…" is not glanceable — it just
     signals that something was cut. VIN is deliberately absent: 17 characters
     would consume the row, and it is needed rarely but *exactly*, which is what
     the expanded panel is for. */
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
      <div
        style={{
          display: 'flex',
          'align-items': 'flex-start',
          gap: 'var(--space-md)',
          padding: 'var(--space-xs) var(--space-screen-h) var(--space-sm)',
        }}
      >
        <div
          class="vh-identity"
          style={{ display: 'flex', 'flex-direction': 'column', flex: '1 1 auto' }}
        >
          {/* One button, not two. [SELECT] and the name previously were separate
              buttons firing the same action, with the first accessibilityHidden. */}
          <button
            onClick={props.onSelectVehicle}
            style={{ display: 'flex', 'flex-direction': 'column', 'min-width': '0' }}
          >
            <Label color="accent" tracking={1}>
              [Select]
            </Label>
            {/* `vh-name` lets the title shrink rather than clip — see harness.css.
                The Swift equivalent is .minimumScaleFactor(0.7). */}
            <Title class="vh-name" rank="primary" lines={1}>
              {displayName()}
            </Title>
            <Show when={specLine()}>
              <Secondary color="tertiary" lines={1}>
                {specLine()}
              </Secondary>
            </Show>
          </button>
        </div>

        <div
          style={{
            display: 'flex',
            'flex-direction': 'column',
            'align-items': 'flex-end',
            flex: '0 0 auto',
          }}
        >
          <button
            onClick={props.onSettings}
            aria-label="Settings"
            style={{
              width: 'var(--touch-target)',
              height: 'var(--touch-target)',
              display: 'flex',
              'align-items': 'center',
              'justify-content': 'flex-end',
            }}
          >
            <span style={{ font: 'var(--font-heading)', color: 'var(--text-tertiary)' }}>⚙</span>
          </button>

          <Show when={props.vehicle}>
            {(v) => (
              <button
                onClick={props.onUpdateMileage}
                style={{
                  display: 'flex',
                  'flex-direction': 'column',
                  'align-items': 'flex-end',
                  padding: 'var(--space-xs) 0',
                }}
              >
                <div style={{ display: 'flex', 'align-items': 'center', gap: 'var(--space-xs)' }}>
                  <Show when={props.mileageStale}>
                    <div
                      aria-hidden="true"
                      style={{ width: '6px', height: '6px', background: 'var(--status-due-soon)' }}
                    />
                  </Show>
                  <Label color="accent" tracking={1}>
                    [Update]
                  </Label>
                </div>
                <Secondary color="accent" style={{ font: 'var(--font-body)' }}>
                  {fmtMileage(v().currentMileage)}
                </Secondary>
              </button>
            )}
          </Show>
        </div>
      </div>

      {/* --- The specs strip: full-width target, informative when collapsed --- */}
      <Show when={props.vehicle && summary()}>
        <button
          onClick={props.onToggleSpecs}
          aria-expanded={props.specsExpanded}
          aria-label="Vehicle specifications"
          style={{
            display: 'flex',
            'align-items': 'center',
            gap: 'var(--space-sm)',
            width: '100%',
            'min-height': 'var(--touch-target)',
            padding: '0 var(--space-screen-h)',
            'border-top': `1px solid var(--grid-line)`,
            background: props.specsExpanded ? 'var(--background-subtle)' : 'transparent',
            transition: 'background var(--anim-fast) ease-out',
          }}
        >
          {/* Not uppercased. These are values, not labels — and the panel below
              renders the same trim in sentence case, so uppercasing here would
              show one datum two different ways. */}
          <Secondary
            color="tertiary"
            lines={1}
            style={{ flex: '1 1 auto', 'min-width': '0', 'text-align': 'left' }}
          >
            {summary()}
          </Secondary>

          <span
            aria-hidden="true"
            style={{
              flex: '0 0 auto',
              font: 'var(--font-label)',
              color: 'var(--accent)',
              display: 'inline-block',
              transform: props.specsExpanded ? 'rotate(180deg)' : 'rotate(0deg)',
              transition: `transform var(--anim-medium) ease-out`,
            }}
          >
            ⌄
          </span>
        </button>
      </Show>
    </header>
  )
}

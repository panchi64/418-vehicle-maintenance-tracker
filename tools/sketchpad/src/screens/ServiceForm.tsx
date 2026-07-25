/*
 * The unified service form — the Phase 4 target, and the reason this sketchpad
 * exists. This is the surface the current app gets most wrong ("a wall of data
 * when filling it out").
 *
 * Three ideas carry the design:
 *
 * 1. ONE FORM, INTENT DERIVED. There is no Record/Remind mode switch. The user
 *    answers "when", and a past answer means they are logging while a future
 *    answer means they are scheduling. They never see or name those words. The
 *    mode switch was asking the user to classify their own intent before the
 *    app would let them describe it.
 *
 * 2. DEFAULT-DISCLOSE WHAT MAKES IT WORK; HIDE WHAT MAKES IT COMPLETE. The
 *    repeat interval is what makes a reminder fire again, so it is on the
 *    default path. Notes, vendor, and receipts make an entry complete, so they
 *    live in depth. Today this is inverted.
 *
 * 3. THE TAP BUDGET IS A REAL CONSTRAINT. Log an oil change with a cost in <=6
 *    taps; schedule a reminder that provably fires in <=5. The harness counts
 *    taps so this is measured, not asserted.
 */
import { createMemo, createSignal, For, Show } from 'solid-js'
import { Chip, ChipRow, Field, InlinePicker, Toggle } from '../ui/Controls'
import { FormSection, FormSubgroup } from '../ui/FormSection'
import { FormAdvisory } from '../ui/FormAdvisory'
import { FormActionBar } from '../ui/FormActionBar'
import { Body, Emphasis, Heading, Label, Secondary } from '../ui/Text'
import {
  categoryLabels,
  fmtMileageBare,
  quickServiceTypes,
  vehicle,
  type CostCategory,
} from '../data/fixtures'

// --- Timing model ---------------------------------------------------------

type PastKind = 'today' | 'yesterday' | 'earlier'
type FutureKind = 'in3mo' | 'in6mo' | 'atMileage' | 'onDate'

type Timing =
  | { when: 'past'; kind: PastKind }
  | { when: 'future'; kind: FutureKind }

/** Intent is DERIVED. Nothing in the UI names it. */
type Intent = 'log' | 'schedule'
const intentOf = (t: Timing | undefined): Intent | undefined =>
  t == null ? undefined : t.when === 'past' ? 'log' : 'schedule'

export function ServiceForm(props: { onClose?: () => void }) {
  const [name, setName] = createSignal('')
  const [timing, setTiming] = createSignal<Timing>()
  const [customDate, setCustomDate] = createSignal('')

  // Past branch
  const [odometer, setOdometer] = createSignal('')
  const [cost, setCost] = createSignal('')
  const [category, setCategory] = createSignal<CostCategory>('maintenance')

  // Future branch
  const [remindAtMileage, setRemindAtMileage] = createSignal('')
  const [repeats, setRepeats] = createSignal(true)
  const [intervalMonths, setIntervalMonths] = createSignal('6')
  const [intervalMiles, setIntervalMiles] = createSignal('5000')

  // Depth
  const [depthOpen, setDepthOpen] = createSignal(false)
  const [vendor, setVendor] = createSignal('')
  const [notes, setNotes] = createSignal('')

  const [mileageResolution, setMileageResolution] = createSignal<'adopt' | 'keep'>()

  const intent = createMemo(() => intentOf(timing()))

  // --- Mileage-commit reasoning, mirroring Utilities/MileageCommit.swift ---
  //
  // Adoption is gated on "is this the newest reading", not on magnitude. A
  // backfilled 2023 service at 40,000 mi must never overwrite a current
  // odometer of 33,417.

  const enteredOdometer = createMemo(() => {
    const n = parseInt(odometer().replace(/\D/g, ''), 10)
    return Number.isFinite(n) ? n : undefined
  })

  const isBackfill = createMemo(() => timing()?.when === 'past' && timing()?.kind === 'earlier')

  const wouldAdopt = createMemo(() => {
    const reading = enteredOdometer()
    if (reading == null || intent() !== 'log') return false
    return reading > vehicle.currentMileage && !isBackfill()
  })

  /** The genuinely unresolvable case: an old date carrying a reading above current. */
  const contradiction = createMemo(() => {
    const reading = enteredOdometer()
    return (
      reading != null && isBackfill() && reading > vehicle.currentMileage && !mileageResolution()
    )
  })

  // --- Can this be saved, and if not, why -------------------------------

  const blockingReason = createMemo(() => {
    if (!name().trim()) return 'Name the service first.'
    if (!timing()) return 'Choose when it happened, or when it is due.'
    if (contradiction()) return 'Resolve the odometer conflict above.'
    // A future item with "at mileage" selected but no mileage typed has no
    // trigger and would never fire. This is the one case that genuinely blocks.
    if (
      timing()?.when === 'future' &&
      timing()?.kind === 'atMileage' &&
      !remindAtMileage().trim()
    ) {
      return 'Enter the mileage to be reminded at, or this reminder will not fire.'
    }
    return undefined
  })

  const canSave = () => blockingReason() == null

  /**
   * When the reminder will fire, and whether that is yet knowable.
   *
   * `known: false` means the user has chosen a trigger but not supplied its
   * value, so the readout must say what is missing rather than print a
   * confident-looking placeholder date.
   */
  const fireTime = createMemo<{ text: string; known: boolean }>(() => {
    const kind = timing()?.kind
    if (kind === 'atMileage') {
      const target = parseInt(remindAtMileage().replace(/\D/g, ''), 10)
      if (!Number.isFinite(target)) {
        return { text: 'once you enter a mileage', known: false }
      }
      // ~940 mi/month, from the fixture vehicle's recent pace.
      const months = Math.max(1, Math.round((target - vehicle.currentMileage) / 940))
      return {
        text: `at ${fmtMileageBare(target)} mi — about ${months} ${
          months === 1 ? 'month' : 'months'
        } away at your pace`,
        known: true,
      }
    }
    if (kind === 'in3mo') return { text: '25 Oct 2026', known: true }
    if (kind === 'in6mo') return { text: '25 Jan 2027', known: true }
    return { text: 'on the date you pick', known: false }
  })

  /* Neutral until a timing is picked. Saying "Log it" before the user has said
     when it happened claims an intent they have not expressed yet, and the
     button would silently change meaning under their finger. */
  const saveLabel = () =>
    intent() === 'schedule' ? 'Schedule it' : intent() === 'log' ? 'Log it' : 'Save'

  const pastChips: { kind: PastKind; label: string }[] = [
    { kind: 'today', label: 'Today' },
    { kind: 'yesterday', label: 'Yesterday' },
    { kind: 'earlier', label: 'Earlier…' },
  ]

  const futureChips: { kind: FutureKind; label: string }[] = [
    { kind: 'in3mo', label: 'In 3 months' },
    { kind: 'in6mo', label: 'In 6 months' },
    { kind: 'atMileage', label: 'At mileage…' },
    { kind: 'onDate', label: 'Pick a date…' },
  ]

  const select = (t: Timing) => {
    setTiming(t)
    setMileageResolution(undefined)
  }

  return (
    <div style={{ display: 'flex', 'flex-direction': 'column', flex: '1 1 auto', 'min-height': '0' }}>
      {/* Sheet header */}
      <div
        style={{
          display: 'flex',
          'align-items': 'center',
          'justify-content': 'space-between',
          padding: 'var(--space-md) var(--space-screen-h)',
          'border-bottom': 'var(--border-width) solid var(--grid-line)',
        }}
      >
        {/* The title states what will happen, which is how the derived intent
            becomes visible without ever asking the user to pick a mode.

            20pt, not 15. At 15 Medium it was the same size as the body text and
            the save button, so the sheet had no title tier at all. */}
        <Heading rank="primary" uppercase tracking={1}>
          {intent() === 'schedule' ? 'New reminder' : intent() === 'log' ? 'New entry' : 'Add service'}
        </Heading>
        <button onClick={props.onClose} style={{ 'min-height': 'var(--touch-target)' }}>
          <Label color="accent" tracking={1}>
            [Cancel]
          </Label>
        </button>
      </div>

      <div
        style={{
          flex: '1 1 auto',
          'min-height': '0',
          'overflow-y': 'auto',
          display: 'flex',
          'flex-direction': 'column',
          /* lg, not xl. The section header rules now carry the separation, so
             paying 32pt of gap on top of them was buying the same grouping
             twice — and it pushed the last field below the fold. */
          gap: 'var(--space-lg)',
          padding: 'var(--space-md) var(--space-screen-h) var(--space-lg)',
        }}
      >
        {/* ---------- 1. WHAT ----------
            The section header IS this field's label, so the field carries none.
            Labelling both "SERVICE" stacked two identical labels on one input. */}
        <FormSection title="Service" trailing="Required">
          <Field
            value={name()}
            onInput={setName}
            placeholder="Oil change"
            /* No autofocus. It scrolled the section label out of view on open,
               and on device it would raise the keyboard over the timing chips —
               hiding the control that derives the intent in order to save one
               tap on a field the quick chips can fill anyway. */
          />

          {/* Plain, not outlined. These are a shortcut for the field above, not
              a choice the form requires — eight outlined rectangles made them
              compete with the timing control, which IS required.

              The row carries its own label. Without one it read as a second
              input: an unlabelled strip of text sitting directly beneath a
              labelled field, in a form where every other line IS a field. */}
          <div
            style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-xs)' }}
          >
            <Label>Common</Label>
            <ChipRow wrap={false}>
              <For each={quickServiceTypes}>
                {(t) => (
                  <Chip
                    variant="plain"
                    label={t}
                    selected={name() === t}
                    onClick={() => setName(t)}
                  />
                )}
              </For>
            </ChipRow>
          </div>
        </FormSection>

        {/* ---------- 2. WHEN — the control that derives intent ---------- */}
        <FormSection title="When">
          <FormSubgroup title="Already done">
            <ChipRow>
              <For each={pastChips}>
                {(c) => (
                  <Chip
                    label={c.label}
                    selected={timing()?.when === 'past' && timing()?.kind === c.kind}
                    onClick={() => select({ when: 'past', kind: c.kind })}
                  />
                )}
              </For>
            </ChipRow>
          </FormSubgroup>

          <FormSubgroup title="Coming up">
            <ChipRow>
              <For each={futureChips}>
                {(c) => (
                  <Chip
                    label={c.label}
                    selected={timing()?.when === 'future' && timing()?.kind === c.kind}
                    onClick={() => select({ when: 'future', kind: c.kind })}
                  />
                )}
              </For>
            </ChipRow>
          </FormSubgroup>

          <Show when={timing()?.kind === 'earlier' || timing()?.kind === 'onDate'}>
            <Field
              label="Date"
              value={customDate()}
              onInput={setCustomDate}
              placeholder="2023-08-14"
              requirement={{ kind: 'required' }}
            />
          </Show>
        </FormSection>

        {/* ---------- 3. BRANCH BODY ---------- */}

        {/* Past: what it cost and what the odometer read. */}
        <Show when={intent() === 'log'}>
          <FormSection title="The visit">
            <Field
              // Distinct from "Remind me at". Identical labels across the two
              // branches are what made "should this update current mileage?"
              // ambiguous in the first place.
              label="Odometer at service"
              value={odometer()}
              onInput={(v) => {
                setOdometer(v)
                setMileageResolution(undefined)
              }}
              placeholder={fmtMileageBare(vehicle.currentMileage)}
              suffix="mi"
              numeric
              requirement={{ kind: 'optional' }}
              below={
                <>
                  {/* Adoption is STATED, never prompted. The app knows what it
                      will do; a modal question would be the app asking the user
                      to make its decision for it. */}
                  <Show when={wouldAdopt()}>
                    <FormAdvisory
                      severity="info"
                      message={`Also updates your odometer — ${fmtMileageBare(
                        vehicle.currentMileage,
                      )} → ${fmtMileageBare(enteredOdometer()!)} mi.`}
                    />
                  </Show>

                  {/* Reserved for the case the app genuinely cannot resolve:
                      an old date carrying a reading above the current odometer. */}
                  <Show when={contradiction()}>
                    <FormAdvisory
                      severity="contradiction"
                      message={`This is dated earlier than your last reading but is higher than it (${fmtMileageBare(
                        vehicle.currentMileage,
                      )} mi). Which is right?`}
                      outcomes={[
                        {
                          label: 'Keep my odometer',
                          onClick: () => setMileageResolution('keep'),
                        },
                        {
                          label: 'Correct it upward',
                          onClick: () => setMileageResolution('adopt'),
                        },
                      ]}
                    />
                  </Show>

                  <Show when={mileageResolution() === 'keep'}>
                    <FormAdvisory
                      severity="info"
                      message={`Your odometer stays at ${fmtMileageBare(vehicle.currentMileage)} mi.`}
                    />
                  </Show>
                </>
              }
            />

            <Field
              label="Cost"
              value={cost()}
              onInput={setCost}
              placeholder="0.00"
              suffix="USD"
              numeric
              requirement={{ kind: 'optional' }}
            />

            {/* A picker, not six chips. Category has a working default and is
                rarely changed, so a permanent option set spent six enclosures on
                a decision most users never make. */}
            <InlinePicker
              label="Category"
              value={category()}
              onChange={setCategory}
              options={(Object.keys(categoryLabels) as CostCategory[]).map((c) => ({
                value: c,
                label: categoryLabels[c],
              }))}
            />
          </FormSection>
        </Show>

        {/* Future: what makes it fire, and whether it comes back. */}
        <Show when={intent() === 'schedule'}>
          <FormSection title="The reminder">
            <Show when={timing()?.kind === 'atMileage'}>
              <Field
                label="Remind me at"
                value={remindAtMileage()}
                onInput={setRemindAtMileage}
                placeholder={fmtMileageBare(vehicle.currentMileage + 5000)}
                suffix="mi"
                numeric
                requirement={{ kind: 'required' }}
              />
            </Show>

            {/* THE REPEAT POLICY IS ON THE DEFAULT PATH, not in a drawer. It is
                what makes the reminder come back, and hiding the thing that
                makes a feature work is the inversion this refactor exists to
                fix. */}
            <div style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-sm)' }}>
              <Toggle
                label="Repeat after each service"
                detail={repeats() ? undefined : 'This will remind you once, then stop.'}
                checked={repeats()}
                onChange={setRepeats}
              />

              <Show when={repeats()}>
                {/* Wraps to two rows at large type, same as Add Vehicle's
                    Year/Make pair — a fixed two-column split cannot survive
                    Dynamic Type on a 375pt screen. */}
                <div style={{ display: 'flex', 'flex-wrap': 'wrap', gap: 'var(--space-sm)' }}>
                  <div style={{ flex: '1 1 calc(130px * var(--type-scale))', 'min-width': '0' }}>
                    <Field
                      label="Every"
                      value={intervalMonths()}
                      onInput={setIntervalMonths}
                      suffix="mo"
                      numeric
                    />
                  </div>
                  <div style={{ flex: '1 1 calc(130px * var(--type-scale))', 'min-width': '0' }}>
                    <Field
                      label="Or every"
                      value={intervalMiles()}
                      onInput={setIntervalMiles}
                      suffix="mi"
                      numeric
                    />
                  </div>
                </div>
                <Secondary color="tertiary">
                  Whichever comes first, counted from the day you mark it done.
                </Secondary>
              </Show>
            </div>

            {/* The projection is a READOUT, not an advisory.

                It was an `.info` advisory, which made the most important line on
                the screen the quietest thing on it — this is the proof that the
                reminder will actually fire, which is the entire point of the
                surface. The severity ladder is for things needing attention or
                resolution; a projected outcome is a value, so it gets a label and
                emphasis weight instead.

                It shares the save path's calculation (F4), so the preview cannot
                promise something the save does not do. */}
            <div
              style={{
                display: 'flex',
                'align-items': 'baseline',
                gap: 'var(--space-md)',
                'padding-top': 'var(--space-xs)',
                'border-top': '1px solid var(--grid-line)',
              }}
            >
              <Label style={{ flex: '0 0 auto', 'padding-top': 'var(--space-sm)' }}>Fires</Label>
              <Emphasis
                color={fireTime().known ? 'primary' : 'tertiary'}
                style={{ flex: '1 1 auto', 'padding-top': 'var(--space-sm)' }}
              >
                {fireTime().text}
              </Emphasis>
            </div>
          </FormSection>
        </Show>

        {/* ---------- 4. DEPTH — what makes it complete ---------- */}
        <Show when={intent() != null}>
          <section data-section="Depth">
            {/* A full-width row with a rule, not a bare bracket label. As an
                11pt label at the end of a long form it was invisible — the
                cheapest control on screen guarding the only content still
                hidden. It now gets the same presence as the header's specs
                strip, and names its contents so you can tell whether to bother
                opening it. */}
            <button
              onClick={() => setDepthOpen(!depthOpen())}
              aria-expanded={depthOpen()}
              style={{
                display: 'flex',
                'align-items': 'center',
                gap: 'var(--space-sm)',
                width: '100%',
                'min-height': '54px',
                /* Bottom rule only. A top rule sat a few pixels under the
                   category field's own underline and read as a doubled line. */
                'border-bottom': 'var(--border-width) solid var(--grid-line)',
              }}
            >
              <div
                style={{
                  display: 'flex',
                  'flex-direction': 'column',
                  gap: '2px',
                  flex: '1 1 auto',
                  'min-width': '0',
                }}
              >
                <Label color="accent" tracking={1.5}>
                  {depthOpen() ? 'Fewer details' : 'More details'}
                </Label>
                <Show when={!depthOpen()}>
                  <Secondary color="tertiary" lines={1} as="div">
                    Shop, notes, receipt
                  </Secondary>
                </Show>
              </div>

              <span
                aria-hidden="true"
                style={{
                  flex: '0 0 auto',
                  font: 'var(--font-heading)',
                  color: 'var(--accent)',
                  display: 'inline-block',
                  'line-height': '1',
                  transform: depthOpen() ? 'rotate(180deg)' : 'rotate(0deg)',
                  transition: 'transform var(--anim-medium) ease-out',
                }}
              >
                ⌄
              </span>
            </button>

            {/* Fade only. AESTHETIC.md forbids slide transitions. */}
            <Show when={depthOpen()}>
              <div
                style={{
                  display: 'flex',
                  'flex-direction': 'column',
                  gap: 'var(--space-md)',
                  'padding-top': 'var(--space-sm)',
                  animation: 'fade-in var(--anim-medium) ease-out',
                }}
              >
                <Field
                  label="Shop or vendor"
                  value={vendor()}
                  onInput={setVendor}
                  placeholder="Toyota de Puerto Rico"
                  requirement={{ kind: 'optional' }}
                />
                <Field
                  label="Notes"
                  value={notes()}
                  onInput={setNotes}
                  placeholder="Used full synthetic"
                  requirement={{ kind: 'optional' }}
                />
                <button
                  style={{
                    'min-height': 'var(--button-height)',
                    border: 'var(--border-width) solid var(--border-subtle)',
                    display: 'flex',
                    'align-items': 'center',
                    'justify-content': 'center',
                  }}
                >
                  <Body color="secondary">Attach a receipt</Body>
                </button>
              </div>
            </Show>
          </section>
        </Show>
      </div>

      <FormActionBar
        label={saveLabel()}
        enabled={canSave()}
        disabledReason={blockingReason()}
        onSave={props.onClose}
      />
    </div>
  )
}

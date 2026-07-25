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
import { FormAdvisory } from '../ui/FormAdvisory'
import { FormActionBar } from '../ui/FormActionBar'
import { Body, Emphasis, Label, Secondary } from '../ui/Text'
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
            becomes visible without ever asking the user to pick a mode. */}
        <Emphasis rank="primary" uppercase tracking={1}>
          {intent() === 'schedule' ? 'New reminder' : intent() === 'log' ? 'New entry' : 'Add service'}
        </Emphasis>
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
          gap: 'var(--space-lg)',
          padding: 'var(--space-md) var(--space-screen-h) var(--space-lg)',
        }}
      >
        {/* ---------- 1. WHAT ---------- */}
        <section data-section="What">
          <Field
            label="Service"
            value={name()}
            onInput={setName}
            placeholder="Oil change"
            requirement={{ kind: 'required' }}
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
              labelled field, in a form where every other line IS a field. Naming
              the role is cheaper than trying to signal it with styling. */}
          <div
            style={{
              display: 'flex',
              'flex-direction': 'column',
              gap: 'var(--space-xs)',
              'padding-top': 'var(--space-md)',
            }}
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
        </section>

        {/* ---------- 2. WHEN — the control that derives intent ---------- */}
        <section
          data-section="When"
          style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-sm)' }}
        >
          <Label>When</Label>

          <div style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-xs)' }}>
            <Secondary color="tertiary">Already done</Secondary>
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
          </div>

          <div
            style={{
              display: 'flex',
              'flex-direction': 'column',
              gap: 'var(--space-xs)',
              'padding-top': 'var(--space-sm)',
            }}
          >
            <Secondary color="tertiary">Coming up</Secondary>
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
          </div>

          <Show when={timing()?.kind === 'earlier' || timing()?.kind === 'onDate'}>
            <div style={{ 'padding-top': 'var(--space-sm)' }}>
              <Field
                label="Date"
                value={customDate()}
                onInput={setCustomDate}
                placeholder="2023-08-14"
                requirement={{ kind: 'required' }}
              />
            </div>
          </Show>
        </section>

        {/* ---------- 3. BRANCH BODY ---------- */}

        {/* Past: what it cost and what the odometer read. */}
        <Show when={intent() === 'log'}>
          <section
            data-section="Log details"
            style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-md)' }}
          >
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
          </section>
        </Show>

        {/* Future: what makes it fire, and whether it comes back. */}
        <Show when={intent() === 'schedule'}>
          <section
            data-section="Reminder details"
            style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-md)' }}
          >
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
                <div style={{ display: 'flex', gap: 'var(--space-sm)' }}>
                  <div style={{ flex: '1 1 0' }}>
                    <Field
                      label="Every"
                      value={intervalMonths()}
                      onInput={setIntervalMonths}
                      suffix="mo"
                      numeric
                    />
                  </div>
                  <div style={{ flex: '1 1 0' }}>
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

            {/* The projection preview shares the save path's calculation (F4),
                so the preview cannot promise something the save does not do. */}
            <FormAdvisory
              severity="info"
              message={
                timing()?.kind === 'atMileage'
                  ? remindAtMileage()
                    ? `Fires at ${fmtMileageBare(
                        parseInt(remindAtMileage().replace(/\D/g, ''), 10) || 0,
                      )} mi — about ${Math.max(
                        1,
                        Math.round(
                          ((parseInt(remindAtMileage().replace(/\D/g, ''), 10) || 0) -
                            vehicle.currentMileage) /
                            940,
                        ),
                      )} months away at your current pace.`
                    : 'Enter a mileage to see when this will fire.'
                  : timing()?.kind === 'in3mo'
                    ? 'Fires 25 Oct 2026.'
                    : timing()?.kind === 'in6mo'
                      ? 'Fires 25 Jan 2027.'
                      : 'Fires on the date you pick.'
              }
            />
          </section>
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

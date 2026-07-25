/*
 * Add vehicle — single scroll, no wizard.
 *
 * What changed and why:
 *
 * - THE TWO-STEP WIZARD IS GONE. One entity should not have two disclosure
 *   models, and Edit's single scroll was already the better one.
 *
 * - VIN IS FIRST, above the fields it fills. Today it sits below them, so it
 *   only helps users who scroll past fields they were just told were required.
 *   A fast path placed after the slow path is not a fast path.
 *
 * - THE ODOMETER IS REQUIRED. The wizard made its step unconditionally valid,
 *   so `currentMileage ?? 0` shipped vehicles at zero miles and every
 *   mileage-based reminder became fiction.
 *
 * - A vehicle is creatable from VIN + odometer alone.
 *
 * - The nine-state VIN block collapses into the FormAdvisory ladder.
 */
import { createMemo, createSignal, Show } from 'solid-js'
import { Field } from '../ui/Controls'
import { FormAdvisory } from '../ui/FormAdvisory'
import { FormActionBar } from '../ui/FormActionBar'
import { Emphasis, Heading, Label, Secondary } from '../ui/Text'
import { FormSection } from '../ui/FormSection'

type VinState = 'empty' | 'tooShort' | 'invalid' | 'looking' | 'resolved'

export function AddVehicle(props: { onClose?: () => void }) {
  const [vin, setVin] = createSignal('')
  const [odometer, setOdometer] = createSignal('')
  const [year, setYear] = createSignal('')
  const [make, setMake] = createSignal('')
  const [model, setModel] = createSignal('')
  const [nickname, setNickname] = createSignal('')
  const [marbeteMonth, setMarbeteMonth] = createSignal('')

  const vinState = createMemo<VinState>(() => {
    const v = vin().trim().toUpperCase()
    if (!v) return 'empty'
    if (v.length < 17) return 'tooShort'
    if (/[IOQ]/.test(v)) return 'invalid'
    return 'resolved'
  })

  // A resolved VIN fills the fields below it, which is the whole point of
  // putting it first.
  const decoded = createMemo(() => {
    if (vinState() !== 'resolved') return undefined
    return { year: '2026', make: 'Toyota', model: 'RAV4', trim: 'XLE Premium AWD' }
  })

  const effectiveYear = () => year() || decoded()?.year || ''
  const effectiveMake = () => make() || decoded()?.make || ''
  const effectiveModel = () => model() || decoded()?.model || ''

  const blockingReason = createMemo(() => {
    if (!odometer().trim()) {
      return 'Enter the current odometer reading — mileage reminders depend on it.'
    }
    if (!effectiveMake() || !effectiveModel()) {
      return 'Scan or enter a VIN, or fill in the make and model.'
    }
    return undefined
  })

  return (
    <div style={{ display: 'flex', 'flex-direction': 'column', flex: '1 1 auto', 'min-height': '0' }}>
      <div
        style={{
          display: 'flex',
          'align-items': 'center',
          'justify-content': 'space-between',
          padding: 'var(--space-md) var(--space-screen-h)',
          'border-bottom': 'var(--border-width) solid var(--grid-line)',
        }}
      >
        {/* 20pt, matching the service form. A sheet title at body size has no
            title tier. */}
        <Heading rank="primary" uppercase tracking={1}>
          Add vehicle
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
          /* Matches ServiceForm: 32px between sections, 16px between fields,
             8px from a header to its content. */
          gap: 'var(--space-xl)',
          padding: 'var(--space-md) var(--space-screen-h) var(--space-lg)',
        }}
      >
        {/* ---------- 1. THE FAST PATH, FIRST ---------- */}
        <FormSection title="VIN" trailing="Optional">
          <Field
            value={vin()}
            onInput={setVin}
            placeholder="17 characters"
            requirement={{ kind: 'optional' }}
            below={
              <>
                <Show when={vinState() === 'tooShort'}>
                  <FormAdvisory
                    severity="caution"
                    message={`${17 - vin().trim().length} more characters to look this up.`}
                  />
                </Show>
                <Show when={vinState() === 'invalid'}>
                  <FormAdvisory
                    severity="caution"
                    message="A VIN never contains I, O, or Q. Check for a 1 or a 0."
                  />
                </Show>
                <Show when={decoded()}>
                  {(d) => (
                    <FormAdvisory
                      severity="info"
                      message={`Found a ${d().year} ${d().make} ${d().model} ${d().trim}. Filled in below.`}
                    />
                  )}
                </Show>
              </>
            }
          />

          <button
            style={{
              'min-height': 'var(--button-height)',
              border: 'var(--border-width) solid var(--border-subtle)',
              display: 'flex',
              'align-items': 'center',
              'justify-content': 'center',
              gap: 'var(--space-sm)',
            }}
          >
            <Emphasis color="secondary">Scan the VIN plate</Emphasis>
          </button>
          <Secondary color="tertiary">
            On the driver's door jamb, or the corner of the windshield.
          </Secondary>
        </FormSection>

        {/* ---------- 2. THE ONE THING THE APP CANNOT INFER ---------- */}
        <FormSection title="Current odometer" trailing="Required">
          <Field
            value={odometer()}
            onInput={setOdometer}
            placeholder="33,417"
            suffix="mi"
            numeric
            requirement={{ kind: 'required' }}
            below={
              <Secondary color="tertiary">
                No VIN lookup can supply this, and every mileage reminder is measured from it.
              </Secondary>
            }
          />
        </FormSection>

        {/* ---------- 3. WHAT THE VIN WOULD HAVE FILLED ---------- */}
        <FormSection title="Vehicle" trailing="Required">
          {/* Two columns at normal type, stacked at large type.
              The flex bases are multiplied by --type-scale so the wrap point
              tracks Dynamic Type: at 375pt and 1.5x these no longer fit side by
              side, and forcing them to crushed "MAKE" to 28px against a 46px
              word. `min-width: 0` alone cannot save a row that is genuinely too
              narrow — the row has to be allowed to become two rows. */}
          <div style={{ display: 'flex', 'flex-wrap': 'wrap', gap: 'var(--space-sm)' }}>
            {/* grow:1 so that when this wraps onto its own line it fills the
                row, rather than leaving a stub underline the width of "2026". */}
            <div style={{ flex: '1 1 calc(84px * var(--type-scale))', 'min-width': '0' }}>
              <Field
                label="Year"
                value={effectiveYear()}
                onInput={setYear}
                placeholder="2026"
                numeric
              />
            </div>
            {/* grow:2 keeps Make roughly twice Year's width while they share a
                line — a year needs four characters, a make needs a word. */}
            <div style={{ flex: '2 1 calc(150px * var(--type-scale))', 'min-width': '0' }}>
              <Field
                label="Make"
                value={effectiveMake()}
                onInput={setMake}
                placeholder="Toyota"
              />
            </div>
          </div>
          <Field label="Model" value={effectiveModel()} onInput={setModel} placeholder="RAV4" />
        </FormSection>

        {/* ---------- 4. OPTIONAL, AND HONEST ABOUT CONSEQUENCES ---------- */}
        {/* The section header carries the optionality once, rather than each of
            its fields repeating it. Three "Optional" tags in a column is noise
            that stops meaning anything. */}
        <FormSection title="Details" trailing="Optional">
          <Field
            label="Nickname"
            value={nickname()}
            onInput={setNickname}
            placeholder="Daily driver"
            requirement={{ kind: 'optional' }}
            below={
              <Secondary color="tertiary">
                Shown instead of the year, make, and model in the header.
              </Secondary>
            }
          />

          {/* Marbete explains the term, and states that filling it schedules a
              notification. An [OPTIONAL] field must not quietly create one. */}
          <Field
            label="Marbete month"
            value={marbeteMonth()}
            onInput={setMarbeteMonth}
            placeholder="November"
            requirement={{
              kind: 'optionalWithEffect',
              effect:
                'Puerto Rico inspection sticker. Set it and you will be reminded a month before it expires.',
            }}
          />
        </FormSection>
      </div>

      <FormActionBar
        label="Add vehicle"
        enabled={blockingReason() == null}
        disabledReason={blockingReason()}
        onSave={props.onClose}
      />
    </div>
  )
}

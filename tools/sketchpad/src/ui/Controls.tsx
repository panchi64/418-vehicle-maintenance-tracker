/*
 * Input primitives: segmented control, chips, text field, toggle.
 * Mirrors Views/Components/Inputs/.
 */
import type { JSX } from 'solid-js'
import { createSignal, For, Show } from 'solid-js'
import { Dynamic } from 'solid-js/web'
import { Body, Emphasis, Label, Secondary } from './Text'
import { Backdrop, OptionList, type Option } from './OptionList'

// --- Segmented control (InstrumentSegmentedControl) -----------------------

interface SegmentedProps<T extends string> {
  options: { value: T; label: string }[]
  value: T
  onChange: (value: T) => void
}

export function SegmentedControl<T extends string>(props: SegmentedProps<T>) {
  return (
    <div
      role="tablist"
      style={{
        display: 'flex',
        border: 'var(--border-width) solid var(--border-subtle)',
      }}
    >
      <For each={props.options}>
        {(option, i) => {
          const selected = () => props.value === option.value
          return (
            <button
              role="tab"
              aria-selected={selected()}
              onClick={() => props.onChange(option.value)}
              style={{
                flex: '1 1 0',
                display: 'flex',
                'align-items': 'center',
                'justify-content': 'center',
                'min-height': 'var(--touch-target)',
                padding: '0 var(--space-sm)',
                background: selected() ? 'var(--accent)' : 'transparent',
                'border-left':
                  i() > 0 ? 'var(--border-width) solid var(--border-subtle)' : undefined,
                transition: `background var(--anim-fast) ease-out`,
              }}
            >
              <Label
                color={selected() ? 'inherit' : 'tertiary'}
                style={{
                  color: selected() ? 'var(--background-primary)' : undefined,
                  'white-space': 'nowrap',
                }}
              >
                {option.label}
              </Label>
            </button>
          )
        }}
      </For>
    </div>
  )
}

// --- Chips (ChipRow / QuickServiceChipsRow) -------------------------------

interface ChipProps {
  label: string
  selected?: boolean
  onClick?: () => void
  /**
   * `decision` (default) — the choice a surface exists to capture. Outlined, and
   *   set in **15 Medium sentence case**: `brutalistBodyEmphasis`, which the type
   *   scale defines as "the one primary datum". A timing chip IS that datum.
   * `plain` — a shortcut. No enclosure, 13 sentence case, selection by weight.
   *   Was 11 Medium tracked caps; suggestions like shop names wrapped into
   *   rows of shouted metadata ("TOYOTA DE PUERTO RICO"). An offer is
   *   sentence case, for the same reason "Pick a date…" is.
   *
   * Two faults are being corrected here.
   *
   * ENCLOSURE. The form once rendered every control as an outlined rectangle —
   * eight quick-service chips, seven timing chips, six category chips, three
   * boxed fields. Twenty-four identical enclosures, so none read as the decision.
   *
   * TYPE. Every chip was then 11pt Medium caps at 1.5 tracking, which is exactly
   * the FIELD-LABEL treatment. Measured across the whole form, 25 of 36 text
   * elements were 11pt: the decision was set in the smallest, most label-like
   * type in the system, and only its border said otherwise. Caps and heavy
   * tracking also make a phrase read as metadata — "PICK A DATE…" is shouted
   * where "Pick a date…" is offered.
   */
  variant?: 'decision' | 'plain'
}

export function Chip(props: ChipProps) {
  const plain = () => props.variant === 'plain'

  /* Plain chips: selection is colour + WEIGHT, never a rule. An accent underline
     was tried first and is the same visual device as a Field's bottom rule — so
     the input and the suggestions beneath it read as the same kind of control,
     and since tapping a chip copies its text into the field, the same words
     appeared twice in the same treatment. */
  const Type = () => (plain() ? Secondary : Emphasis)

  return (
    <button
      onClick={props.onClick}
      aria-pressed={props.selected}
      style={{
        display: 'inline-flex',
        'align-items': 'center',
        gap: 'var(--space-xs)',
        'max-width': '100%',
        'min-height': 'var(--touch-target)',
        padding: plain() ? '0 var(--space-xs)' : '0 var(--space-md)',
        border: plain()
          ? 'none'
          : `var(--border-width) solid ${
              props.selected ? 'var(--accent)' : 'var(--border-subtle)'
            }`,
        background: !plain() && props.selected ? 'var(--accent)' : 'transparent',
        transition: 'background var(--anim-fast) ease-out, border-color var(--anim-fast) ease-out',
      }}
    >
      <Dynamic
        component={Type()}
        style={{
          color: plain()
            ? props.selected
              ? 'var(--accent)'
              : 'var(--text-secondary)'
            : props.selected
              ? 'var(--background-primary)'
              : 'var(--text-primary)',
          // Wraps rather than overflowing at large type ("In 6 mo / 5,000 mi" was
          // 360pt in a 315pt column at 2x).
          'white-space': 'normal',
          'text-align': 'left',
          'font-weight': plain() && props.selected ? '600' : undefined,
        }}
      >
        {props.label}
      </Dynamic>
    </button>
  )
}

export function ChipRow(props: { children: JSX.Element; wrap?: boolean }) {
  return (
    <div
      style={{
        display: 'flex',
        'flex-wrap': props.wrap === false ? 'nowrap' : 'wrap',
        gap: 'var(--space-sm)',
        'overflow-x': props.wrap === false ? 'auto' : undefined,
        'scrollbar-width': 'none',
      }}
    >
      {props.children}
    </div>
  )
}

// --- Field requirement vocabulary (FieldRequirement.swift) ----------------

export type Requirement =
  | { kind: 'required'; reason?: string }
  | { kind: 'optional' }
  /** Optional, but has a consequence the user must be told about up front. */
  | { kind: 'optionalWithEffect'; effect: string }

// --- Text field (InstrumentTextField / MileageInputField) -----------------

interface FieldProps {
  /**
   * Omit when the enclosing `FormSection` header already names this field —
   * stacking two identical labels on one input is worse than none.
   */
  label?: string
  value: string
  onInput?: (value: string) => void
  placeholder?: string
  requirement?: Requirement
  suffix?: string
  /** Leading unit, e.g. the currency symbol — "$" reads before the amount. */
  prefix?: string
  numeric?: boolean
  /** F6: the saved value, shown only while the current value differs. */
  original?: string
  onFocus?: () => void
  /** Advisory or helper content rendered adjacent to the control that resolves it. */
  below?: JSX.Element
  autofocus?: boolean
}

export function Field(props: FieldProps) {
  const req = () => props.requirement ?? { kind: 'optional' as const }

  return (
    /* `min-width: 0` is load-bearing, not defensive. A flex item defaults to
       `min-width: auto`, which resolves to its content's min-content width — and
       an <input> has a wide intrinsic minimum. Without this a Field placed in a
       flex row refuses to shrink and overflows its container: the Year/Make row
       on Add Vehicle was 381px inside 333px. */
    <div
      style={{
        display: 'flex',
        'flex-direction': 'column',
        gap: 'var(--space-xs)',
        'min-width': '0',
      }}
    >
      <Show when={props.label}>
        <div style={{ display: 'flex', 'align-items': 'baseline', gap: 'var(--space-sm)' }}>
          <Label>{props.label}</Label>
          <Show when={req().kind === 'required'}>
            {/* The word, not a bare asterisk — an asterisk requires knowing the
                convention, which is recall rather than recognition. */}
            <Label color="accent" tracking={1}>
              Required
            </Label>
          </Show>
        </div>
      </Show>

      {/* A single rule, not a four-sided box. The value sits ON the line, which
          is the same idiom the readouts use, and it removes three enclosures per
          form without costing any clarity about where to type. The rule goes
          accent on focus, so the affordance is stronger than the box ever was. */}
      <div
        class="field-line"
        style={{
          display: 'flex',
          'align-items': 'center',
          gap: 'var(--space-sm)',
          'min-height': '40px',
          'min-width': '0',
          'border-bottom': 'var(--border-width) solid var(--border-subtle)',
        }}
      >
        <Show when={props.prefix}>
          <Body color="secondary">{props.prefix}</Body>
        </Show>
        <input
          value={props.value}
          onFocus={props.onFocus}
          placeholder={props.placeholder}
          inputMode={props.numeric ? 'numeric' : undefined}
          autofocus={props.autofocus}
          onInput={(e) => props.onInput?.(e.currentTarget.value)}
          style={{
            flex: '1 1 auto',
            font: 'var(--font-body)',
            color: 'var(--text-primary)',
            'min-width': '0',
          }}
        />
        {/* 13pt, not 15. A unit annotation set at the same size as the value it
            annotates competes with it; "mi" is not as important as "33,417". */}
        <Show when={props.suffix}>
          <Secondary color="tertiary">{props.suffix}</Secondary>
        </Show>
      </div>

      <Show when={req().kind === 'optionalWithEffect'}>
        <Secondary color="tertiary">
          {(req() as { kind: 'optionalWithEffect'; effect: string }).effect}
        </Secondary>
      </Show>

      <Show when={props.original != null && props.original !== props.value}>
        <Secondary color="tertiary">Was {props.original || 'empty'}</Secondary>
      </Show>

      {props.below}
    </div>
  )
}

// --- InlinePicker ---------------------------------------------------------

/**
 * A one-of-N form value that does not deserve a visible option set.
 *
 * Replaces the six outlined category chips. Category has a sensible default and
 * is rarely changed, so six permanent enclosures were six rectangles spent on a
 * decision most users never make — while the timing chips, which every user must
 * answer, looked exactly the same. Shaped like `Field` (label, value, rule) so a
 * form reads as one column of lines rather than a mix of lines and boxes.
 *
 * The trigger shows the VALUE: this sets a value rather than narrowing a list,
 * and it does not share a row with another control, so a value-dependent width
 * is safe here.
 */
export function InlinePicker<T extends string>(props: {
  label: string
  options: Option<T>[]
  value: T
  onChange: (value: T) => void
}) {
  const [open, setOpen] = createSignal(false)
  const active = () => props.options.find((o) => o.value === props.value)

  return (
    <div style={{ position: 'relative', display: 'flex', 'flex-direction': 'column', gap: 'var(--space-xs)' }}>
      <Label>{props.label}</Label>

      <button
        onClick={() => setOpen(!open())}
        aria-expanded={open()}
        aria-label={props.label}
        style={{
          display: 'flex',
          'align-items': 'center',
          gap: 'var(--space-sm)',
          'min-height': '40px',
          'border-bottom': `var(--border-width) solid ${
            open() ? 'var(--accent)' : 'var(--border-subtle)'
          }`,
        }}
      >
        <Body style={{ flex: '1 1 auto', 'text-align': 'left' }}>{active()?.label ?? '—'}</Body>
        <span
          aria-hidden="true"
          style={{
            font: 'var(--font-label)',
            color: 'var(--accent)',
            display: 'inline-block',
            transform: open() ? 'rotate(180deg)' : 'rotate(0deg)',
            transition: 'transform var(--anim-medium) ease-out',
          }}
        >
          ⌄
        </span>
      </button>

      <Show when={open()}>
        <Backdrop onClick={() => setOpen(false)} />
        <OptionList
          options={props.options}
          value={props.value}
          align="left"
          onChange={(v) => {
            props.onChange(v)
            setOpen(false)
          }}
        />
      </Show>
    </div>
  )
}

// --- Toggle (LabeledInstrumentToggle) ------------------------------------

export function Toggle(props: {
  label: string
  detail?: string
  checked: boolean
  onChange: (v: boolean) => void
}) {
  return (
    <button
      onClick={() => props.onChange(!props.checked)}
      role="switch"
      aria-checked={props.checked}
      style={{
        display: 'flex',
        'align-items': 'center',
        gap: 'var(--space-md)',
        'min-height': 'var(--touch-target)',
        width: '100%',
      }}
    >
      <div style={{ flex: '1 1 auto', display: 'flex', 'flex-direction': 'column' }}>
        <Body as="div">{props.label}</Body>
        <Show when={props.detail}>
          <Secondary as="div" color="tertiary">
            {props.detail}
          </Secondary>
        </Show>
      </div>
      <div
        style={{
          width: '44px',
          height: '24px',
          flex: '0 0 auto',
          border: `var(--border-width) solid ${
            props.checked ? 'var(--accent)' : 'var(--border-subtle)'
          }`,
          background: props.checked ? 'var(--accent)' : 'transparent',
          display: 'flex',
          'align-items': 'center',
          'justify-content': props.checked ? 'flex-end' : 'flex-start',
          padding: '2px',
          transition: 'all var(--anim-fast) ease-out',
        }}
      >
        <div
          style={{
            width: '16px',
            height: '16px',
            background: props.checked ? 'var(--background-primary)' : 'var(--text-tertiary)',
          }}
        />
      </div>
    </button>
  )
}

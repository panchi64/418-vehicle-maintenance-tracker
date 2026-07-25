/*
 * Input primitives: segmented control, chips, text field, toggle.
 * Mirrors Views/Components/Inputs/.
 */
import type { JSX } from 'solid-js'
import { createSignal, For, Show } from 'solid-js'
import { Dynamic } from 'solid-js/web'
import { Body, Label, LabelBold, Secondary } from './Text'
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
   * `outlined` — a real choice set. Spend an enclosure here.
   * `plain` — a shortcut. No enclosure at all; selection is accent text over a rule.
   *
   * The form previously rendered every control as an outlined rectangle: eight
   * quick-service chips, seven timing chips, six category chips, three boxed
   * fields. Twenty-four identical enclosures, so none of them read as the
   * decision — which is what made the form a wall. Enclosure is now a budget
   * spent only on the choice that derives the intent.
   */
  variant?: 'outlined' | 'plain'
}

export function Chip(props: ChipProps) {
  const plain = () => props.variant === 'plain'

  /* A plain chip's selected state is colour + WEIGHT, never a rule.
     It first used an accent underline, which is the same visual device as a
     Field's bottom rule — so the input and the suggestions below it read as the
     same kind of control, and since tapping a chip copies its text into the
     field, the same words appeared twice in the same treatment. Weight keeps two
     channels without borrowing the field's. */
  const Type = () => (plain() && props.selected ? LabelBold : Label)

  return (
    <button
      onClick={props.onClick}
      aria-pressed={props.selected}
      style={{
        display: 'inline-flex',
        'align-items': 'center',
        gap: 'var(--space-xs)',
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
              : 'var(--text-secondary)',
          'white-space': 'nowrap',
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
  label: string
  value: string
  onInput?: (value: string) => void
  placeholder?: string
  requirement?: Requirement
  suffix?: string
  numeric?: boolean
  /** Advisory or helper content rendered adjacent to the control that resolves it. */
  below?: JSX.Element
  autofocus?: boolean
}

export function Field(props: FieldProps) {
  const req = () => props.requirement ?? { kind: 'optional' as const }

  return (
    <div style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-xs)' }}>
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
          'border-bottom': 'var(--border-width) solid var(--border-subtle)',
        }}
      >
        <input
          value={props.value}
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
        <Show when={props.suffix}>
          <Body color="tertiary">{props.suffix}</Body>
        </Show>
      </div>

      <Show when={req().kind === 'optionalWithEffect'}>
        <Secondary color="tertiary">
          {(req() as { kind: 'optionalWithEffect'; effect: string }).effect}
        </Secondary>
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
 * Unlike `FilterControl`, the trigger shows the VALUE: this sets a value rather
 * than narrowing a list, and it is not sharing a row with another control, so a
 * value-dependent width is safe here.
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

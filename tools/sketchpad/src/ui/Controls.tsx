/*
 * Input primitives: segmented control, chips, text field, toggle.
 * Mirrors Views/Components/Inputs/.
 */
import type { JSX } from 'solid-js'
import { For, Show } from 'solid-js'
import { Body, Label, Secondary } from './Text'

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
  /** Renders the chip as the affordance that opens further input, e.g. `EARLIER…`. */
  opensInput?: boolean
}

export function Chip(props: ChipProps) {
  return (
    <button
      onClick={props.onClick}
      aria-pressed={props.selected}
      style={{
        display: 'inline-flex',
        'align-items': 'center',
        gap: 'var(--space-xs)',
        'min-height': 'var(--touch-target)',
        padding: '0 var(--space-md)',
        border: `var(--border-width) solid ${
          props.selected ? 'var(--accent)' : 'var(--border-subtle)'
        }`,
        background: props.selected ? 'var(--accent)' : 'transparent',
        transition: 'background var(--anim-fast) ease-out, border-color var(--anim-fast) ease-out',
      }}
    >
      <Label
        style={{
          color: props.selected ? 'var(--background-primary)' : 'var(--text-secondary)',
          'white-space': 'nowrap',
        }}
      >
        {props.label}
      </Label>
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

      <div
        style={{
          display: 'flex',
          'align-items': 'center',
          gap: 'var(--space-sm)',
          'min-height': 'var(--button-height)',
          padding: '0 var(--space-md)',
          border: 'var(--border-width) solid var(--border-subtle)',
          background: 'var(--background-subtle)',
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

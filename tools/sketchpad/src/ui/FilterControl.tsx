/*
 * FilterControl — the filter half of a tab's single control row.
 *
 * WHAT WAS WRONG. Services and Costs each had TWO stacked control rows: a
 * segmented control plus a horizontally-scrolling chip row. Three faults:
 *
 *   1. The scrolling chip row HID OPTIONS off the right edge. "On track" was
 *      cut to "ON TR…" on Services and three of six categories were off-screen
 *      on Costs. A filter whose options you must scroll to discover fails
 *      recognition-over-recall — you have to already know what is there.
 *   2. Two rows of chrome before any content, on a tab whose job is showing
 *      content. Costs reached four rows counting the two segmented controls.
 *   3. Chips and a segmented control are two different visual vocabularies for
 *      the same job — pick one of N — and both rendered a filled accent block,
 *      so two cream slabs competed at the top of the screen.
 *
 * WHAT THIS DOES INSTEAD. The filter collapses to a single bracket-notation
 * trigger showing the ACTIVE value, which expands to a full list. That means:
 *
 *   - One control row per tab, not two.
 *   - Nothing is hidden off an edge. The expanded list is vertical, so it scales
 *     to six categories as easily as to four statuses.
 *   - The active filter is always legible without expanding anything, which is
 *     what the old "filter indicator" row existed to do — now it is free.
 *   - Counts sit next to each option, so choosing is informed rather than a
 *     guess followed by an empty list.
 *   - Bracket notation matches [SELECT] / [UPDATE] / the specs strip, so the
 *     app gains no third control vocabulary.
 *
 * Filtering is refinement, not the default path, so it earns a trigger rather
 * than permanent real estate. The segmented control keeps its row because a
 * view or period switch changes what the screen IS, not merely what it shows.
 *
 * THE TRIGGER SHOWS THE DIMENSION, NOT THE VALUE — `[CATEGORY ⌄]`, never
 * `[MAINTENANCE ⌄]`. A first attempt labelled it with the selected value, which
 * seemed more informative and broke the row: selecting "Maintenance" widened the
 * trigger, which crushed the segmented control beside it until `ALL` collided
 * with the trigger. Any control whose width depends on its own value cannot
 * share a fixed row with another control. Constant width is the requirement, and
 * the active value is surfaced by `ActiveFilterBar` instead, where it has a whole
 * row and cannot truncate.
 */
import { createSignal, For, Show, type JSX } from 'solid-js'
import { Body, Label, Secondary } from './Text'

export interface FilterOption<T extends string> {
  value: T
  label: string
  count?: number
}

interface FilterControlProps<T extends string> {
  /** Names the dimension, e.g. "Status". Used for the accessible label. */
  name: string
  options: FilterOption<T>[]
  value: T
  onChange: (value: T) => void
  /** The value meaning "no filter". Shown as cleared, and clearable in one tap. */
  defaultValue: T
}

export function FilterControl<T extends string>(props: FilterControlProps<T>) {
  const [open, setOpen] = createSignal(false)

  const isFiltered = () => props.value !== props.defaultValue

  const choose = (value: T) => {
    props.onChange(value)
    setOpen(false)
  }

  return (
    <div style={{ position: 'relative', flex: '0 0 auto' }}>
      <button
        onClick={() => setOpen(!open())}
        aria-expanded={open()}
        aria-label={`${props.name} filter`}
        style={{
          display: 'flex',
          'align-items': 'center',
          gap: 'var(--space-xs)',
          'min-height': 'var(--touch-target)',
          padding: '0 var(--space-sm)',
          'white-space': 'nowrap',
        }}
      >
        {/* Always the dimension name, so the width never changes with the
            selection. Accent tint is what signals a filter is active; the value
            itself lives in ActiveFilterBar. */}
        <Label color={isFiltered() ? 'accent' : 'tertiary'} tracking={1}>
          [{props.name}
        </Label>
        <span
          aria-hidden="true"
          style={{
            font: 'var(--font-label)',
            color: isFiltered() ? 'var(--accent)' : 'var(--text-tertiary)',
            display: 'inline-block',
            transform: open() ? 'rotate(180deg)' : 'rotate(0deg)',
            transition: 'transform var(--anim-medium) ease-out',
          }}
        >
          ⌄
        </span>
        <Label color={isFiltered() ? 'accent' : 'tertiary'} tracking={1}>
          ]
        </Label>
      </button>

      <Show when={open()}>
        {/* A backdrop, so tapping anywhere else dismisses the list. Without it
            the only way out is re-tapping the trigger, which is a trap on a
            touch screen. */}
        <div
          onClick={() => setOpen(false)}
          style={{
            position: 'fixed',
            inset: '0',
            'z-index': '9',
          }}
        />
        <div
          role="listbox"
          style={{
            position: 'absolute',
            'z-index': '10',
            top: '100%',
            right: '0',
            'min-width': '190px',
            border: 'var(--border-width) solid var(--accent)',
            background: 'var(--background-elevated)',
            animation: 'fade-in var(--anim-fast) ease-out',
          }}
        >
          <For each={props.options}>
            {(option, i) => {
              const selected = () => option.value === props.value
              return (
                <button
                  role="option"
                  aria-selected={selected()}
                  onClick={() => choose(option.value)}
                  style={{
                    display: 'flex',
                    'align-items': 'center',
                    gap: 'var(--space-md)',
                    width: '100%',
                    'min-height': 'var(--touch-target)',
                    padding: '0 var(--space-md)',
                    'border-top':
                      i() > 0 ? '1px solid var(--grid-line)' : undefined,
                    background: selected() ? 'var(--background-subtle)' : 'transparent',
                  }}
                >
                  {/* Selection is a rule plus weight, not color alone. */}
                  <div
                    aria-hidden="true"
                    style={{
                      width: '2px',
                      'align-self': 'stretch',
                      background: selected() ? 'var(--accent)' : 'transparent',
                    }}
                  />
                  <Body
                    color={selected() ? 'primary' : 'secondary'}
                    style={{ flex: '1 1 auto', 'text-align': 'left' }}
                  >
                    {option.label}
                  </Body>
                  <Show when={option.count != null}>
                    <Secondary color="tertiary">{option.count}</Secondary>
                  </Show>
                </button>
              )
            }}
          </For>
        </div>
      </Show>
    </div>
  )
}

/**
 * ActiveFilterBar — states the filter currently narrowing the screen, and clears it.
 *
 * Renders ONLY when a filter is active, so the default screen still has one row
 * of chrome. This row is a consequence of the user's own action rather than
 * permanent furniture, which is the difference between it and the old
 * always-present "filter indicator" row.
 *
 * It also earns its space by answering the question the old scrolling chip row
 * couldn't: *what am I currently looking at, and how do I stop?*
 */
export function ActiveFilterBar<T extends string>(props: {
  name: string
  options: FilterOption<T>[]
  value: T
  defaultValue: T
  onClear: () => void
}) {
  const active = () => props.options.find((o) => o.value === props.value)

  return (
    <Show when={props.value !== props.defaultValue && active()}>
      {(option) => (
        <div
          style={{
            display: 'flex',
            'align-items': 'center',
            gap: 'var(--space-sm)',
            'min-height': 'var(--touch-target)',
            padding: '0 var(--space-screen-h)',
            'border-bottom': 'var(--border-width) solid var(--grid-line)',
            background: 'var(--background-subtle)',
          }}
        >
          <div
            aria-hidden="true"
            style={{ width: '2px', height: '14px', background: 'var(--accent)' }}
          />
          <Label color="tertiary">{props.name}</Label>
          <Body style={{ flex: '1 1 auto', 'min-width': '0' }}>{option().label}</Body>
          <Show when={option().count != null}>
            <Secondary color="tertiary">{option().count}</Secondary>
          </Show>

          {/* Clearing is one tap, not "reopen the list and find All again". */}
          <button
            onClick={props.onClear}
            aria-label={`Clear ${props.name} filter`}
            style={{
              flex: '0 0 auto',
              width: 'var(--touch-target)',
              height: 'var(--touch-target)',
              display: 'flex',
              'align-items': 'center',
              'justify-content': 'flex-end',
            }}
          >
            <Body color="accent">×</Body>
          </button>
        </div>
      )}
    </Show>
  )
}

/**
 * ControlRow — the one row of chrome a readout tab is allowed by default.
 *
 * `position: relative` is not set here: the filter anchors its own list, so this
 * row must not become a positioning context that clips it.
 */
export function ControlRow(props: { children: JSX.Element }) {
  return (
    <div
      style={{
        display: 'flex',
        'align-items': 'center',
        gap: 'var(--space-sm)',
        padding: 'var(--space-sm) var(--space-screen-h)',
        'border-bottom': 'var(--border-width) solid var(--grid-line)',
      }}
    >
      {props.children}
    </div>
  )
}

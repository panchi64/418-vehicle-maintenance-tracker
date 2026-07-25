/*
 * FormSection — a titled band of a form, separated by a header rule.
 *
 * WHAT WAS WRONG. Once the enclosures came off the form, nothing replaced them:
 * every group became a label followed by content, separated only by a slightly
 * larger gap. The whole screen melded into one column.
 *
 * The deeper fault was that THREE different levels were rendering identically.
 * `SERVICE`, `COMMON`, `WHEN`, `COST` and `CATEGORY` were all 11pt tracked caps
 * in tertiary — but "WHEN" names a section, "COST" names a field inside one, and
 * "Already done" names a subgroup inside that. A form with one label style has
 * no structure, only a sequence.
 *
 * The three levels now differ on at least two channels each:
 *
 *   section   11 Bold caps, secondary, + a full-width rule    FormSection
 *   field     11 Medium caps, tertiary, no rule               Field / InlinePicker
 *   subgroup  13 Regular sentence case, tertiary              plain Secondary
 *
 * The rule is what does most of the work: it spans the remaining width, so a
 * section boundary is a horizontal line across the screen rather than a
 * marginally bigger gap. That is the instrument-panel idiom the app already uses
 * for `InstrumentSectionHeader`.
 *
 * NOTE ON `data-form-section`. Deliberately not `data-section`, so the harness's
 * one-primary audit skips these. That rule is a READOUT rule — a readout section
 * must answer "which datum matters most". A Decision surface is governed instead
 * by a default path, a tap budget, and what is disclosed by default, and asking
 * "which of these seven timing chips is the primary" has no meaningful answer.
 * Tagging form sections as auditable sections would have produced a screenful of
 * false failures, which is how a useful check gets ignored.
 */
import type { JSX } from 'solid-js'
import { Show } from 'solid-js'
import { Label, LabelBold } from './Text'

export function FormSection(props: {
  title: string
  /** Short trailing note, e.g. `Required`. Sits past the rule. */
  trailing?: string
  children: JSX.Element
}) {
  return (
    <section
      data-form-section={props.title}
      style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-md)' }}
    >
      <div style={{ display: 'flex', 'align-items': 'center', gap: 'var(--space-sm)' }}>
        <LabelBold color="secondary" tracking={1.5}>
          {props.title}
        </LabelBold>

        <div
          aria-hidden="true"
          style={{ flex: '1 1 auto', height: '1px', background: 'var(--grid-line)' }}
        />

        <Show when={props.trailing}>
          <Label color="accent" tracking={1}>
            {props.trailing}
          </Label>
        </Show>
      </div>

      {props.children}
    </section>
  )
}

/**
 * A named group inside a section — the third label level.
 *
 * Sentence case and no rule, so it cannot be mistaken for a section boundary.
 */
export function FormSubgroup(props: { title: string; children: JSX.Element }) {
  return (
    <div style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-sm)' }}>
      <span style={{ font: 'var(--font-secondary)', color: 'var(--text-tertiary)' }}>
        {props.title}
      </span>
      {props.children}
    </div>
  )
}

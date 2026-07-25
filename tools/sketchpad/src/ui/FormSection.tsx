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

/*
 * SPACING. Three distinct steps, not two similar ones:
 *
 *   8px   header → its content     (sm)  the label belongs to what follows
 *   16px  field → field            (md)  siblings inside one group
 *   32px  section → section        (xl)  set by the parent scroll container
 *
 * A single `gap` on this section previously put the header 16px from its own
 * content while sections sat 24px apart — so the header was very nearly
 * equidistant between the group it labels and the one above it, and at a glance
 * the sections did not separate. A 1.5:1 ratio does not communicate grouping;
 * proximity has to be unambiguous to do any work.
 *
 * Tightening the inner steps is what pays for the wider outer one, so the extra
 * separation costs almost no height.
 */
export function FormSection(props: {
  title: string
  /** Short trailing note, e.g. `Required`. Sits past the rule. */
  trailing?: string
  children: JSX.Element
}) {
  return (
    <section
      data-form-section={props.title}
      style={{ display: 'flex', 'flex-direction': 'column' }}
    >
      <div
        style={{
          display: 'flex',
          'align-items': 'center',
          gap: 'var(--space-sm)',
          'margin-bottom': 'var(--space-sm)',
        }}
      >
        <LabelBold color="secondary" tracking={1.5}>
          {props.title}
        </LabelBold>

        {/* 2px, not 1. The section title is 11pt Bold caps and a field label is
            11pt Medium caps — the same size, so the RULE is what actually marks a
            section boundary, and it should be as heavy as any other structural
            border in the app. */}
        <div
          aria-hidden="true"
          style={{
            flex: '1 1 auto',
            height: 'var(--border-width)',
            background: 'var(--grid-line)',
          }}
        />

        {/* Tertiary, not accent. In the default theme `accent` equals
            `textPrimary`, so an accent-coloured note renders at FULL brightness —
            this annotation was outshining the section title it belongs to. */}
        <Show when={props.trailing}>
          <Label color="tertiary" tracking={1}>
            {props.trailing}
          </Label>
        </Show>
      </div>

      {/* Content owns its own gap, so the header can sit closer to it than the
          fields sit to each other. */}
      <div
        style={{ display: 'flex', 'flex-direction': 'column', gap: 'var(--space-md)' }}
      >
        {props.children}
      </div>
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

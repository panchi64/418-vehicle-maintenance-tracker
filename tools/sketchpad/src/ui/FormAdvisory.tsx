/*
 * FormAdvisory — one advisory component with an explicit severity ladder.
 *
 * Mirrors Views/Components/Feedback/FormAdvisory.swift. The four rungs are
 * differentiated on three channels at once (type, enclosure, color), not on
 * color alone, because status color is already load-bearing in this app and
 * because color-only encoding fails the accessibility [REQUIREMENT].
 *
 *   severity        type              enclosure             color
 *   blocking        15 Medium         filled + full border  statusOverdue
 *   contradiction   15 Medium + btns  filled + full border  accent
 *   caution         13 Regular        tinted, leading rule  statusDueSoon
 *   info            13 Regular        none                  textTertiary
 *
 * Messages are sentence case. Uppercasing a sentence-length string costs
 * legibility and reads as shouting; caps are for labels.
 *
 * Deliberately does NOT absorb SuggestedValueRow or OriginalValueHint — those
 * are field affordances that change a value, not advisories about one.
 */
import { For, Show } from 'solid-js'
import { Body, Emphasis, Secondary } from './Text'

export type Severity = 'blocking' | 'contradiction' | 'caution' | 'info'

export interface AdvisoryOutcome {
  label: string
  onClick?: () => void
}

interface FormAdvisoryProps {
  severity: Severity
  message: string
  /** Only for `contradiction`: the labeled outcomes the user picks between. */
  outcomes?: AdvisoryOutcome[]
  onDismiss?: () => void
}

const TINT: Record<Severity, string> = {
  blocking: 'var(--status-overdue)',
  contradiction: 'var(--accent)',
  caution: 'var(--status-due-soon)',
  info: 'var(--text-tertiary)',
}

export function FormAdvisory(props: FormAdvisoryProps) {
  const tint = () => TINT[props.severity]
  const filled = () => props.severity === 'blocking' || props.severity === 'contradiction'
  const ruled = () => props.severity === 'caution'

  return (
    <div
      role={props.severity === 'blocking' ? 'alert' : 'status'}
      data-advisory={props.severity}
      style={{
        display: 'flex',
        'flex-direction': 'column',
        gap: 'var(--space-sm)',
        padding: filled()
          ? 'var(--space-sm) var(--space-md)'
          : ruled()
            ? 'var(--space-sm) var(--space-md)'
            : '0',
        border: filled() ? `var(--border-width) solid ${tint()}` : undefined,
        'border-left': ruled() ? `var(--border-width) solid ${tint()}` : undefined,
        background: filled()
          ? `color-mix(in srgb, ${tint()} 14%, transparent)`
          : ruled()
            ? `color-mix(in srgb, ${tint()} 8%, transparent)`
            : undefined,
      }}
    >
      <div style={{ display: 'flex', gap: 'var(--space-sm)', 'align-items': 'flex-start' }}>
        <Show when={filled()}>
          {/* A shape, so severity is not carried by color alone. */}
          <div
            aria-hidden="true"
            style={{
              width: '8px',
              height: '8px',
              flex: '0 0 auto',
              background: tint(),
              'margin-top': 'calc(var(--space-xs) + 2px)',
            }}
          />
        </Show>

        <Show
          when={filled()}
          fallback={
            <Secondary color={props.severity === 'caution' ? 'secondary' : 'tertiary'}>
              {props.message}
            </Secondary>
          }
        >
          <Emphasis color={props.severity === 'blocking' ? 'overdue' : 'primary'}>
            {props.message}
          </Emphasis>
        </Show>

        <Show when={props.onDismiss}>
          <button
            onClick={props.onDismiss}
            aria-label="Dismiss"
            style={{
              'margin-left': 'auto',
              flex: '0 0 auto',
              width: 'var(--touch-target)',
              height: '20px',
              display: 'flex',
              'align-items': 'flex-start',
              'justify-content': 'flex-end',
            }}
          >
            <Body color="tertiary">×</Body>
          </button>
        </Show>
      </div>

      {/* Two labeled outcomes rather than prose. When the app genuinely cannot
          resolve the contradiction, the user needs buttons, not an explanation. */}
      <Show when={props.outcomes?.length}>
        <div style={{ display: 'flex', gap: 'var(--space-sm)', 'flex-wrap': 'wrap' }}>
          <For each={props.outcomes}>
            {(outcome) => (
              <button
                onClick={outcome.onClick}
                style={{
                  flex: '1 1 auto',
                  'min-height': 'var(--touch-target)',
                  padding: '0 var(--space-md)',
                  border: `var(--border-width) solid ${tint()}`,
                  display: 'flex',
                  'align-items': 'center',
                  'justify-content': 'center',
                }}
              >
                <Body>{outcome.label}</Body>
              </button>
            )}
          </For>
        </div>
      </Show>
    </div>
  )
}

/**
 * InsufficientDataNote — one quiet line, never a card whose only content is
 * absence. Replaces ChartPlaceholderCard.
 */
export function InsufficientDataNote(props: { message: string }) {
  return (
    <div style={{ padding: 'var(--space-sm) 0' }}>
      <Secondary color="tertiary">{props.message}</Secondary>
    </div>
  )
}

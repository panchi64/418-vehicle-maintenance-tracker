/*
 * CheckRow — a multi-select option in a form (appointment services).
 *
 * Chosen over outlined toggle chips, whose filled slabs out-shouted every
 * other field once a few were selected, and over plain chips, whose selection
 * was brightness alone. See AppointmentForm's header.
 */
import { Body } from './Text'

/**
 * A 22pt square (outlined → filled with ✓) and the name, full-width and 44pt
 * tall. Selection is shape + colour, and only the square is enclosed, so five
 * of these weigh less than one outlined chip row.
 */
export function CheckRow(props: { label: string; checked: boolean; onClick: () => void }) {
  return (
    <button
      role="checkbox"
      aria-checked={props.checked}
      onClick={props.onClick}
      style={{
        display: 'flex',
        'align-items': 'center',
        gap: 'var(--space-md)',
        'min-height': 'var(--touch-target)',
        'text-align': 'left',
      }}
    >
      <span
        aria-hidden="true"
        style={{
          flex: '0 0 auto',
          width: '22px',
          height: '22px',
          display: 'flex',
          'align-items': 'center',
          'justify-content': 'center',
          border: `var(--border-width) solid ${props.checked ? 'var(--accent)' : 'var(--border-subtle)'}`,
          background: props.checked ? 'var(--accent)' : 'transparent',
          color: 'var(--background-primary)',
          font: 'var(--font-label-bold)',
        }}
      >
        {props.checked ? '✓' : ''}
      </span>
      <Body color={props.checked ? 'primary' : 'secondary'} style={{ 'min-width': '0' }}>
        {props.label}
      </Body>
    </button>
  )
}

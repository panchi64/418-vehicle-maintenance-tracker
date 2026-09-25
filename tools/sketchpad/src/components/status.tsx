/*
 * Status vocabulary — one definition of how a status looks and reads.
 *
 * Cards.tsx and Rows.tsx each carried their own STATUS_COLOR table; two copies
 * of a status palette is how "Due soon" ends up amber on one screen and yellow
 * on another. Extracted on the second occurrence.
 *
 * STATUS IS NEVER COLOR ALONE [REQUIREMENT]. Every status renders as a WORD and
 * a SHAPE, and the shapes differ from each other, so a color-blind user in
 * sunlight still gets three distinct signals:
 *
 *   overdue   filled square      "Overdue"
 *   dueSoon   outlined square    "Due soon"
 *   good      short rule         "On track"
 *   neutral   short rule         "No schedule"
 */
import { Label } from '../ui/Text'
import {
  fmtMileageBare,
  fmtShortDate,
  type Service,
  type ServiceStatus,
  type Vehicle,
} from '../data/fixtures'
import { remaining } from '../data/scenario'

export const STATUS_COLOR: Record<ServiceStatus, string> = {
  overdue: 'var(--status-overdue)',
  dueSoon: 'var(--status-due-soon)',
  good: 'var(--status-good)',
  neutral: 'var(--status-neutral)',
}

export const STATUS_LABEL: Record<ServiceStatus, string> = {
  overdue: 'Overdue',
  dueSoon: 'Due soon',
  good: 'On track',
  neutral: 'No schedule',
}

/** The shape half of a status. Sized in em so it tracks Dynamic Type. */
export function StatusMark(props: { status: ServiceStatus }) {
  const c = () => STATUS_COLOR[props.status]
  const box = { width: '0.62em', height: '0.62em', flex: '0 0 auto' }
  return (
    <span
      aria-hidden="true"
      style={{
        display: 'inline-block',
        ...(props.status === 'overdue'
          ? { ...box, background: c() }
          : props.status === 'dueSoon'
            ? { ...box, border: `2px solid ${c()}` }
            : { width: '0.62em', height: '2px', background: c(), 'align-self': 'center' }),
      }}
    />
  )
}

/** Shape + word, the pair every status surface uses. Uppercase: it is a tag. */
export function StatusTag(props: { status: ServiceStatus; text?: string }) {
  return (
    <span
      style={{
        display: 'inline-flex',
        'align-items': 'center',
        gap: 'var(--space-xs)',
        font: 'var(--font-label-bold)',
        color: STATUS_COLOR[props.status],
      }}
    >
      <StatusMark status={props.status} />
      <Label style={{ color: 'inherit', font: 'inherit' }} tracking={1.2}>
        {props.text ?? STATUS_LABEL[props.status]}
      </Label>
    </span>
  )
}

/** "917 mi over", "in 11 days" — the remaining figure in words. */
export function remainingText(s: Service, v: Vehicle): string {
  const r = remaining(s, v)
  if (r.lead === 'miles' && r.miles != null) {
    return r.miles < 0
      ? `${fmtMileageBare(-r.miles)} mi over`
      : `in ${fmtMileageBare(r.miles)} mi`
  }
  if (r.days == null) return ''
  if (r.days < 0) return `${-r.days} ${-r.days === 1 ? 'day' : 'days'} over`
  if (r.days === 0) return 'Due today'
  return `in ${r.days} ${r.days === 1 ? 'day' : 'days'}`
}

/** "Due 32,500 mi or Jul 4" — both triggers, whichever comes first. */
export function dueLine(s: Service): string {
  const parts: string[] = []
  if (s.dueMileage != null) parts.push(`${fmtMileageBare(s.dueMileage)} mi`)
  if (s.dueDate) parts.push(fmtShortDate(s.dueDate))
  return parts.length ? `Due ${parts.join(' or ')}` : 'No due date'
}


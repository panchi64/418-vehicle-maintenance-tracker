/*
 * Shop visits (appointments) and vehicle notes — fixtures and the few
 * formatters their layouts depend on.
 *
 * Deliberately untidy, like fixtures.ts:
 *   - a shop name long enough to truncate at 375pt ("Firestone Complete Auto
 *     Care — Bayamón (Ave. Main)"), and one with no address at all
 *   - a visit that started an hour ago (the car is at the shop right now) and
 *     one later today, beside the ordinary "in 2 days"
 *   - 0 and 4 linked services, so the support line is tested empty and full
 *   - notes with long titles, notes with several attachments, a pinned note,
 *     two pinned notes, no pinned note, and no notes at all
 *
 * `today` is fixtures.ts's fixed clock (Sat, Jul 25 2026, 10:00), so relative
 * tags are stable between reloads.
 */
import { today, type ServiceLog } from './fixtures'

export interface Appointment {
  id: string
  shop: string
  startsAt: Date
  /** Ids into the scenario's services. Zero is allowed: "just a check-up". */
  serviceIds: string[]
  address?: string
  note?: string
}

export interface Attachment {
  id: string
  kind: 'photo' | 'pdf'
  name: string
}

export interface VehicleNote {
  id: string
  title: string
  body: string
  pinned: boolean
  modifiedAt: Date
  attachments: Attachment[]
}

const HOUR = 60 * 60 * 1000
const DAY = 24 * HOUR

/** A day offset from the fixed clock at a wall-clock time. */
export function at(dayOffset: number, hour: number, minute = 0): Date {
  const d = new Date(today.getFullYear(), today.getMonth(), today.getDate() + dayOffset)
  d.setHours(hour, minute, 0, 0)
  return d
}

// --- Appointments ----------------------------------------------------------

export const appointmentsFull: Appointment[] = [
  {
    id: 'a1',
    shop: 'Toyota de Puerto Rico',
    startsAt: at(2, 9, 30),
    serviceIds: ['s1', 's2'],
    address: 'Carr. 2 Km 11.3, Bayamón',
  },
  { id: 'a2', shop: 'Costco Tire Center', startsAt: at(20, 8, 0), serviceIds: ['s4'] },
]

/** Started an hour ago, long shop name, no address, four services, two more after. */
export const appointmentsToday: Appointment[] = [
  {
    id: 'a3',
    shop: 'Firestone Complete Auto Care — Bayamón (Ave. Main)',
    startsAt: at(0, 9, 0),
    serviceIds: ['s1', 's2', 's4', 's5'],
  },
  { id: 'a4', shop: 'Toyota de Puerto Rico', startsAt: at(6, 7, 30), serviceIds: ['s3'] },
  { id: 'a5', shop: 'Autogermana', startsAt: at(31, 13, 0), serviceIds: [] },
]

/** Later today, nothing linked. */
export const appointmentsLaterToday: Appointment[] = [
  { id: 'a6', shop: 'Estación de Inspección Hato Rey', startsAt: at(0, 14, 0), serviceIds: [] },
]

/** Soonest first, including one that started within the last 12 hours. */
export function upcomingAppointments(list: Appointment[]): Appointment[] {
  return list
    .filter((a) => a.startsAt.getTime() > today.getTime() - 12 * HOUR)
    .sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime())
}

const sameDay = (a: Date, b: Date) =>
  a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()

export const fmtTime = (d: Date) =>
  d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })

/** "Mon, Jul 27" — with fmtTime, Home's Shop Visit primary ("Mon, Jul 27 · 9:30 AM"). */
export const fmtDay = (d: Date) =>
  d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })

/**
 * The relative tag. Words carry it; the status shape is the second channel.
 * "Started" is dueSoon's outlined square, not overdue's filled one: the car
 * being at the shop is the plan working, not something gone wrong.
 */
export function visitTag(d: Date, from: Date = today): { text: string; status: 'dueSoon' | 'neutral' } {
  const diff = d.getTime() - from.getTime()
  if (diff <= 0) {
    const mins = Math.round(-diff / 60_000)
    return { text: mins < 60 ? `Started ${mins} min ago` : `Started ${Math.floor(mins / 60)} h ago`, status: 'dueSoon' }
  }
  if (sameDay(d, from)) return { text: 'Today', status: 'dueSoon' }
  const days = Math.round((new Date(d).setHours(0, 0, 0, 0) - new Date(from).setHours(0, 0, 0, 0)) / DAY)
  return { text: days === 1 ? 'Tomorrow' : `In ${days} days`, status: 'neutral' }
}

/**
 * The two reminders a booking leaves: the day before at the same time, and one
 * hour before. Ones already in the past are dropped rather than shown as fired.
 */
export function reminderTimes(d: Date, from: Date = today): Date[] {
  return [new Date(d.getTime() - DAY), new Date(d.getTime() - HOUR)].filter((r) => r > from)
}

export function reminderText(d: Date): string {
  const rs = reminderTimes(d)
  const fmt = (r: Date) =>
    `${sameDay(r, today) ? 'Today' : r.toLocaleDateString('en-US', { weekday: 'short' })} ${fmtTime(r)}`
  if (!rs.length) return 'None'
  return rs.map(fmt).join(' and ')
}

/** Distinct shops from history and bookings, most recent first. */
export function previousShops(logs: ServiceLog[], appointments: Appointment[]): string[] {
  const seen = new Set<string>()
  const out: string[] = []
  const dated = [
    ...appointments.map((a) => ({ shop: a.shop, at: a.startsAt })),
    ...logs.filter((l) => l.vendor).map((l) => ({ shop: l.vendor!, at: l.performedAt })),
  ].sort((a, b) => b.at.getTime() - a.at.getTime())
  for (const x of dated) {
    if (seen.has(x.shop)) continue
    seen.add(x.shop)
    out.push(x.shop)
  }
  return out
}

// --- Notes -----------------------------------------------------------------

const earlier = (days: number, hour = 10) => at(-days, hour)

export const notesFull: VehicleNote[] = [
  {
    id: 'n1',
    title: 'Costco tire quote — Michelin CrossClimate 2, 225/65R17, four installed',
    body: '$684 out the door incl. road hazard. Price good through Aug 15; ask for Luis.',
    pinned: true,
    modifiedAt: earlier(13),
    attachments: [
      { id: 'at1', kind: 'photo', name: 'Quote front' },
      { id: 'at2', kind: 'photo', name: 'Quote back' },
    ],
  },
  {
    id: 'n2',
    title: 'Rattle behind glovebox',
    body: 'Only over 40 mph on cold mornings. Dealer could not reproduce on Jul 2.',
    pinned: true,
    modifiedAt: earlier(23),
    attachments: [],
  },
  {
    id: 'n3',
    title: 'Parts numbers',
    body: 'Oil filter 04152-YZZA6\nCabin filter 87139-0R010\nWipers 26" / 16"',
    pinned: false,
    modifiedAt: earlier(2),
    attachments: [],
  },
  {
    id: 'n4',
    title: 'Accident report — Plaza Las Américas parking lot, other driver insured with Universal',
    body: 'Claim 2026-PR-118842. Adjuster: M. Rivera, 787-555-0142.',
    pinned: false,
    modifiedAt: earlier(40),
    attachments: [
      { id: 'at3', kind: 'photo', name: 'Rear bumper' },
      { id: 'at4', kind: 'photo', name: 'Other car' },
      { id: 'at5', kind: 'photo', name: 'Plate' },
      { id: 'at6', kind: 'pdf', name: 'Police report.pdf' },
    ],
  },
  {
    id: 'n5',
    title: 'Tire pressure',
    body: '35 psi front and rear (door jamb). Spare 60 psi.',
    pinned: false,
    modifiedAt: earlier(90),
    attachments: [],
  },
]

/** One unpinned note — Home's Notes row then has a count and no preview. */
export const notesSparse: VehicleNote[] = [notesFull[2]]

export function sortedNotes(list: VehicleNote[]): { pinned: VehicleNote[]; rest: VehicleNote[] } {
  const byModified = [...list].sort((a, b) => b.modifiedAt.getTime() - a.modifiedAt.getTime())
  return { pinned: byModified.filter((n) => n.pinned), rest: byModified.filter((n) => !n.pinned) }
}

/** "Jul 12 · 2 attachments" — the meta line; the count falls off first. */
export function noteMeta(n: VehicleNote): string {
  const date = n.modifiedAt.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
  const count = n.attachments.length
  return count ? `${date} · ${count} ${count === 1 ? 'attachment' : 'attachments'}` : date
}

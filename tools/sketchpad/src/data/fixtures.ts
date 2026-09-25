/*
 * Sample data shaped like Checkpoint's models, enough to render every screen.
 *
 * Deliberately not a happy path. The fixtures include an overdue item, a
 * due-soon item, a healthy item, a date-only item with no odometer relationship,
 * a long service name, and a long vehicle nickname — the cases that break
 * layouts. A sketchpad seeded with tidy data proves nothing.
 */

export type ServiceStatus = 'overdue' | 'dueSoon' | 'good' | 'neutral'

export interface Vehicle {
  id: string
  name: string
  year: number
  make: string
  model: string
  trim?: string
  vin: string
  currentMileage: number
  mileageUpdatedAt: Date
  licensePlate?: string
  marbeteMonth?: number
  engine?: string
  transmission?: string
  fuelType?: string
  drivetrain?: string
  milesDrivenYearToDate: number
  milesDrivenSamePeriodLastYear: number
}

export interface Service {
  id: string
  name: string
  status: ServiceStatus
  /** Absent for date-driven items such as an inspection sticker. */
  dueMileage?: number
  dueDate?: Date
  intervalMonths?: number
  intervalMiles?: number
  lastPerformedAt?: Date
  lastPerformedMileage?: number
  isRecurring: boolean
}

export interface ServiceLog {
  id: string
  name: string
  performedAt: Date
  mileage?: number
  cost?: number
  category: CostCategory
  vendor?: string
  bundledCount?: number
}

export type CostCategory =
  | 'maintenance'
  | 'repair'
  | 'fuel'
  | 'insurance'
  | 'registration'
  | 'other'

export const categoryLabels: Record<CostCategory, string> = {
  maintenance: 'Maintenance',
  repair: 'Repair',
  fuel: 'Fuel',
  insurance: 'Insurance',
  registration: 'Registration',
  other: 'Other',
}

const day = 24 * 60 * 60 * 1000
const now = new Date('2026-07-25T10:00:00')
const ago = (days: number) => new Date(now.getTime() - days * day)
const ahead = (days: number) => new Date(now.getTime() + days * day)

export const vehicle: Vehicle = {
  id: 'v1',
  name: 'Daily Driver',
  year: 2026,
  make: 'Toyota',
  model: 'RAV4',
  trim: 'XLE Premium AWD',
  vin: 'JTMRWRFV8ND512847',
  currentMileage: 33_417,
  mileageUpdatedAt: ago(9),
  licensePlate: 'IWK-482',
  marbeteMonth: 11,
  engine: '2.5L I4 Hybrid',
  transmission: 'eCVT',
  fuelType: 'Hybrid',
  drivetrain: 'AWD',
  milesDrivenYearToDate: 8_432,
  milesDrivenSamePeriodLastYear: 7_530,
}

/** A second vehicle so the picker and the header's long-name case are real. */
export const vehicles: Vehicle[] = [
  vehicle,
  {
    ...vehicle,
    id: 'v2',
    name: "Mom's Highlander Hybrid",
    year: 2019,
    make: 'Toyota',
    model: 'Highlander',
    trim: 'LE',
    currentMileage: 112_806,
    milesDrivenYearToDate: 4_190,
    milesDrivenSamePeriodLastYear: 6_020,
  },
  {
    ...vehicle,
    id: 'v3',
    name: '',
    year: 2014,
    make: 'Honda',
    model: 'Civic',
    trim: 'EX',
    currentMileage: 187_442,
    milesDrivenYearToDate: 1_240,
    milesDrivenSamePeriodLastYear: 9_880,
  },
]

export const services: Service[] = [
  {
    id: 's1',
    name: 'Oil & Filter Change',
    status: 'overdue',
    dueMileage: 32_500,
    dueDate: ago(21),
    intervalMonths: 6,
    intervalMiles: 5_000,
    lastPerformedAt: ago(203),
    lastPerformedMileage: 27_500,
    isRecurring: true,
  },
  {
    id: 's2',
    name: 'Tire Rotation & Balance',
    status: 'dueSoon',
    dueMileage: 34_000,
    dueDate: ahead(11),
    intervalMiles: 6_000,
    lastPerformedAt: ago(96),
    lastPerformedMileage: 28_000,
    isRecurring: true,
  },
  {
    id: 's3',
    name: 'Marbete / Inspection Sticker',
    status: 'dueSoon',
    // No dueMileage: a sticker expires on a date and has no odometer relationship.
    dueDate: ahead(38),
    intervalMonths: 12,
    lastPerformedAt: ago(327),
    isRecurring: true,
  },
  {
    id: 's4',
    name: 'Cabin & Engine Air Filter Replacement',
    status: 'good',
    dueMileage: 40_000,
    dueDate: ahead(142),
    intervalMiles: 15_000,
    lastPerformedAt: ago(58),
    lastPerformedMileage: 25_000,
    isRecurring: true,
  },
  {
    id: 's5',
    name: 'Brake Fluid Flush',
    status: 'good',
    dueMileage: 45_000,
    dueDate: ahead(280),
    intervalMonths: 36,
    lastPerformedAt: ago(390),
    lastPerformedMileage: 18_200,
    isRecurring: true,
  },
]

export const serviceLogs: ServiceLog[] = [
  {
    id: 'l1',
    name: 'Oil & Filter Change',
    performedAt: ago(3),
    mileage: 33_290,
    cost: 78.4,
    category: 'maintenance',
    vendor: 'Toyota de Puerto Rico',
  },
  {
    id: 'l2',
    name: 'Front Brake Pads & Rotors',
    performedAt: ago(17),
    mileage: 32_940,
    cost: 612.0,
    category: 'repair',
    vendor: 'Autogermana',
    bundledCount: 3,
  },
  {
    id: 'l3',
    name: 'AutoExpreso Toll Reload',
    performedAt: ago(31),
    cost: 40.0,
    category: 'other',
  },
  {
    id: 'l4',
    name: 'Tire Rotation',
    performedAt: ago(96),
    mileage: 28_000,
    cost: 0,
    category: 'maintenance',
    vendor: 'Costco Tire Center',
  },
  {
    id: 'l5',
    name: 'Annual Policy Renewal',
    performedAt: ago(122),
    cost: 1_284.0,
    category: 'insurance',
  },
  {
    id: 'l6',
    name: 'Wiper Blades',
    performedAt: ago(140),
    mileage: 26_310,
    cost: 32.99,
    category: 'maintenance',
  },
  // Older history, so Costs has a real trend, a YTD-vs-last-year comparison,
  // and more than one month group — and so Services' history spans months.
  { id: 'l7', name: 'Battery Replacement', performedAt: new Date('2026-02-03T10:00:00'), mileage: 24_880, cost: 189.0, category: 'repair', vendor: 'AutoZone' },
  { id: 'l8', name: 'Oil & Filter Change', performedAt: new Date('2026-01-14T10:00:00'), mileage: 24_410, cost: 72.1, category: 'maintenance', vendor: 'Toyota de Puerto Rico' },
  { id: 'l9', name: 'Oil & Filter Change', performedAt: new Date('2025-12-12T10:00:00'), mileage: 22_500, cost: 72.0, category: 'maintenance', vendor: 'Toyota de Puerto Rico' },
  { id: 'l10', name: 'Marbete Renewal', performedAt: new Date('2025-11-03T10:00:00'), cost: 118.0, category: 'registration' },
  { id: 'l11', name: 'Wheel Alignment', performedAt: new Date('2025-09-15T10:00:00'), mileage: 20_120, cost: 95.0, category: 'maintenance', vendor: 'Costco Tire Center' },
  { id: 'l12', name: 'Oil & Filter Change', performedAt: new Date('2025-07-21T10:00:00'), mileage: 17_500, cost: 74.2, category: 'maintenance', vendor: 'Toyota de Puerto Rico' },
  { id: 'l13', name: 'Four New Tires', performedAt: new Date('2025-05-12T10:00:00'), mileage: 15_900, cost: 684.0, category: 'repair', vendor: 'Costco Tire Center' },
  { id: 'l14', name: 'Annual Policy Renewal', performedAt: new Date('2025-03-28T10:00:00'), cost: 1_190.0, category: 'insurance' },
  { id: 'l15', name: 'Oil & Filter Change', performedAt: new Date('2025-01-20T10:00:00'), mileage: 12_500, cost: 69.5, category: 'maintenance', vendor: 'Toyota de Puerto Rico' },
]

// --- Formatting -----------------------------------------------------------
// Mirrors Formatters.swift closely enough to judge line lengths, which is the
// only reason it matters here.

export const fmtMileage = (n: number) => `${n.toLocaleString('en-US')} mi`
export const fmtMileageBare = (n: number) => n.toLocaleString('en-US')

export const fmtCurrency = (n: number) =>
  n.toLocaleString('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 2 })

export const fmtCurrencyWhole = (n: number) =>
  n.toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 })

export const fmtDate = (d: Date) =>
  d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })

export const fmtShortDate = (d: Date) =>
  d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })

/** Sentence-cased, matching TimeSinceFormatter.full(). */
export function timeSince(d: Date, from: Date = now): string {
  const days = Math.floor((from.getTime() - d.getTime()) / day)
  if (days <= 0) return 'Today'
  if (days === 1) return 'Yesterday'
  if (days < 30) return `${days} days ago`
  const months = Math.floor(days / 30)
  if (months < 12) return `${months} ${months === 1 ? 'month' : 'months'} ago`
  const years = Math.floor(months / 12)
  return `${years} ${years === 1 ? 'year' : 'years'} ago`
}

export function daysUntil(d: Date, from: Date = now): number {
  return Math.round((d.getTime() - from.getTime()) / day)
}

export const today = now
export { ago, ahead }

/** Driving pace used for estimates and for comparing mile- vs date-urgency. */
export const MILES_PER_DAY = 31

export const fmtMonthYear = (d: Date) =>
  d.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })

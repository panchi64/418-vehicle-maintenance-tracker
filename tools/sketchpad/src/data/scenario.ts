/*
 * Scenarios — the same screens rendered against different data.
 *
 * A layout that only holds for the populated fixture is not resolved. Readout
 * rule 2 says section order is fixed regardless of data, and rule 3 says absence
 * collapses to one quiet line — neither can be checked without a sparse vehicle.
 * The marbete scenario exists because the hero changes subject when the sticker
 * is the most urgent thing, and that swap has to be seen to be judged.
 */
import { createContext, useContext } from 'solid-js'
import {
  ahead,
  ago,
  daysUntil,
  fmtMonthYear,
  MILES_PER_DAY,
  serviceLogs,
  services,
  vehicle,
  type Service,
  type ServiceLog,
  type Vehicle,
} from './fixtures'

export interface Scenario {
  id: 'full' | 'marbete' | 'sparse' | 'fresh' | 'empty'
  vehicle?: Vehicle
  services: Service[]
  logs: ServiceLog[]
  /** At most one — Home's Suggestions section never holds more. */
  suggestion?: { title: string; detail: string; action: string }
}

const full: Scenario = {
  id: 'full',
  vehicle,
  services,
  logs: serviceLogs,
  // The cluster and seasonal suggestions used to be two sections; they are one
  // slot now, and the more actionable one wins it.
  suggestion: {
    title: 'Rotate the tires on the same visit',
    detail: 'Due in 11 days — one trip instead of two.',
    action: 'Add to visit',
  },
}

const marbete: Scenario = {
  ...full,
  id: 'marbete',
  services: services.map((s) =>
    s.id === 's3'
      ? { ...s, status: 'dueSoon', dueDate: ahead(6) }
      : s.id === 's1'
        ? { ...s, status: 'dueSoon', dueMileage: 33_900, dueDate: ahead(19) }
        : s,
  ),
  suggestion: undefined,
}

const sparse: Scenario = {
  id: 'sparse',
  vehicle: { ...vehicle, name: '', mileageUpdatedAt: ago(1) },
  services: [
    {
      id: 'sp1',
      name: 'Oil & Filter Change',
      status: 'good',
      dueMileage: 37_400,
      dueDate: ahead(128),
      intervalMonths: 6,
      intervalMiles: 5_000,
      lastPerformedAt: ago(12),
      lastPerformedMileage: 32_400,
      isRecurring: true,
    },
  ],
  logs: [
    {
      id: 'spl1',
      name: 'Oil & Filter Change',
      performedAt: ago(12),
      mileage: 32_400,
      cost: 71.5,
      category: 'maintenance',
      vendor: 'Toyota de Puerto Rico',
    },
  ],
}

/** A vehicle and nothing else — the first minute after Add Vehicle. */
const fresh: Scenario = { id: 'fresh', vehicle: { ...vehicle, mileageUpdatedAt: ago(0) }, services: [], logs: [] }

const empty: Scenario = { id: 'empty', services: [], logs: [] }

export const scenarios = { full, marbete, sparse, fresh, empty }

const ScenarioContext = createContext<() => Scenario>(() => full)
export const ScenarioProvider = ScenarioContext.Provider
export const useScenario = () => useContext(ScenarioContext)

// --- Urgency ----------------------------------------------------------------

export interface Remaining {
  miles?: number
  days?: number
  /** Which dimension is closer to (or further past) due, in days-equivalent. */
  lead: 'miles' | 'days'
  /** Days-equivalent of the leading dimension; negative when past due. */
  score: number
}

/**
 * Mirrors `[Service].sortedByUrgency(_:)`: score once, sort on the score. Miles
 * are converted to days at the vehicle's pace so an item due by mileage and one
 * due by date can be compared at all.
 */
export function remaining(s: Service, v: Vehicle): Remaining {
  const miles = s.dueMileage != null ? s.dueMileage - v.currentMileage : undefined
  const days = s.dueDate ? daysUntil(s.dueDate) : undefined
  const milesAsDays = miles != null ? miles / MILES_PER_DAY : Infinity
  const d = days ?? Infinity
  return milesAsDays < d
    ? { miles, days, lead: 'miles', score: milesAsDays }
    : { miles, days, lead: 'days', score: d }
}

export function sortedByUrgency(list: Service[], v: Vehicle): Service[] {
  const scored = list.map((s) => ({ s, score: remaining(s, v).score }))
  return scored.sort((a, b) => a.score - b.score).map((x) => x.s)
}

export interface MonthGroup {
  key: string
  label: string
  logs: ServiceLog[]
  total: number
}

/** Newest month first. Shared by Services' History and Costs' expense list. */
export function groupByMonth(logs: ServiceLog[]): MonthGroup[] {
  const map = new Map<string, MonthGroup>()
  for (const log of [...logs].sort((a, b) => b.performedAt.getTime() - a.performedAt.getTime())) {
    const d = log.performedAt
    const key = `${d.getFullYear()}-${d.getMonth()}`
    const g = map.get(key) ?? { key, label: fmtMonthYear(d), logs: [], total: 0 }
    g.logs.push(log)
    g.total += log.cost ?? 0
    map.set(key, g)
  }
  return [...map.values()]
}

/** A date-only item with no odometer relationship — the marbete. */
export const isMarbete = (s: Service) => s.dueMileage == null && /marbete/i.test(s.name)

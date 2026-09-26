/*
 * What reading a shop receipt produces (`ServiceReceiptDraft` in the app).
 *
 * Deliberately imperfect, like the other fixtures: the odometer was hard to
 * read (low confidence), and the line items are a breakdown whose sum plus
 * tax is the total — the cost rule the app keeps (a visit's total counts
 * once; its items never add on top).
 */
import { ago, vehicle } from './fixtures'

export type Confidence = 'high' | 'medium' | 'low'
export type LineKind = 'parts' | 'labor' | 'supplies' | 'fees' | 'tax' | 'tip' | 'discount' | 'other'

export interface ReceiptLine {
  label: string
  kind: LineKind
  amount: number
}

export interface ReceiptDraft {
  shopName?: string
  date?: Date
  total?: number
  odometer?: number
  /** Matched to a preset or one of the vehicle's services. */
  serviceName?: string
  lineItems: ReceiptLine[]
  confidence: {
    shop: Confidence
    date: Confidence
    total: Confidence
    odometer: Confidence
    service: Confidence
  }
}

export const kindLabels: Record<LineKind, string> = {
  parts: 'Parts',
  labor: 'Labor',
  supplies: 'Supplies',
  fees: 'Fees',
  tax: 'Tax',
  tip: 'Tip',
  discount: 'Discount',
  other: 'Other',
}

export const sampleReceipt: ReceiptDraft = {
  shopName: 'Firestone Complete Auto Care — Bayamón',
  date: ago(2),
  total: 91.91,
  odometer: vehicle.currentMileage + 112,
  serviceName: 'Oil & Filter Change',
  lineItems: [
    { label: 'Synthetic oil 5W-30, 5 qt', kind: 'parts', amount: 32.45 },
    { label: 'Oil filter', kind: 'parts', amount: 9.99 },
    { label: 'Oil change labor', kind: 'labor', amount: 39.99 },
    { label: 'IVU 11.5%', kind: 'tax', amount: 9.48 },
  ],
  confidence: { shop: 'high', date: 'high', total: 'high', odometer: 'low', service: 'medium' },
}

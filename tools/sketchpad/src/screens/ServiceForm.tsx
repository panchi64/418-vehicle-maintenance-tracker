/*
 * The unified service form — Decision surface.
 *
 * ONE FORM, THREE DOORS. The same surface serves:
 *   log       [+] → pick a service → Save          "Log Service"
 *   complete  Mark Done on a card → Save           "Complete Service"
 *   edit      a history row → change → Save        "Edit Entry"
 * and scheduling is not a fourth door: choosing "Not done yet" under When
 * turns the same form into "Schedule Service". Intent is still DERIVED from
 * the answer to "when", never asked as a mode.
 *
 * TAP BUDGETS (measured by the harness, from Home):
 *   Mark Next Up done              2   Mark Done → Save
 *   Log an oil change today + $    4   [+] → Oil row → Cost field → Save
 *   Schedule a future service      4   [+] → service → Not done yet → Save
 *
 * What makes those numbers possible — DEFAULTS DO THE WORK:
 *   - When defaults to Today. The past/future chip grid used to have no
 *     default, so every entry cost a tap to say "today".
 *   - The odometer defaults to the last CONFIRMED reading, never the estimate
 *     (Mark Done once committed the estimate as fact). The estimate is a hint
 *     under the field, one tap away.
 *   - Picking a service that is due LINKS it: saving completes it, and the
 *     form says so (.info "Completes …") instead of asking.
 *   - The next reminder is derived from the service's interval and shown as a
 *     readout with a Remind toggle, ON by default. Turning it off is the
 *     decision; leaving it is free.
 *   - Scheduling defaults to the service's own interval, so "Not done yet"
 *     is immediately saveable.
 *
 * THE SERVICE PICKER ORDERS BY LIKELIHOOD: due-now services first (with their
 * status, because "which one is overdue" is why you opened the form), then
 * services you've logged recently, then Browse all. Typing a name is always
 * available for anything else. Once chosen, the picker collapses to one row
 * with [Change] — the list has done its job and would otherwise push every
 * other field below the fold.
 *
 * DEFAULT-DISCLOSED vs HIDDEN (Decision rule 5): everything that makes the
 * entry WORK is on the default path — service, when, odometer, cost,
 * next reminder. Category (it has a working default), notes, and receipts
 * make it COMPLETE and live under More Details, whose collapsed row names
 * its contents and the category's current value.
 *
 * SAVE IS IN THE TOOLBAR (FormToolbar). A tap on the dim Save scrolls to the
 * blocking field and shows why there (F2).
 *
 * READING A RECEIPT (Sep 2026). The receipt answers most of the form at once —
 * service, when, odometer, total, shop — so its entry point sits FIRST, as a
 * quiet row shaped like the More details trigger (accent 15 + tertiary 13
 * summary), where the draft-resume banner already sits for the same reason:
 * both refill the form. Tried and rejected:
 *   - `[Scan receipt]` in the Details header: in the log door the open service
 *     picker pushes Details below the fold, so the fastest path was hidden.
 *   - A "Receipt" readout section with the total as its primary: the total then
 *     appeared twice (there and in Cost) — two affordances for one value
 *     (Decision rule 7), and the readout outranked the decision.
 * Resolved: values land IN their own fields, each with a "From receipt" note
 * beneath it (the F6 shape: provenance shown only while the value is unchanged —
 * edit it and the note goes). A low-confidence value gets a .caution instead,
 * next to the field that resolves it. One .info line says what the system did,
 * with [Clear] to put the form back. Save confirms — no extra "use these" tap.
 * Shop joins Details only when the receipt names one (it is stored on the
 * visit); line items are completeness, so they live under More details with
 * the one-line reconciliation against the total.
 *   Log from a receipt   3 in-frame  [+] → Scan a receipt → Save
 *                        (+2 in the system camera: shutter, Save)
 */
import type { JSX } from 'solid-js'
import { createMemo, createSignal, For, Show } from 'solid-js'
import { Chip, ChipRow, Field, InlinePicker, Toggle } from '../ui/Controls'
import { FormSection, FormSubgroup } from '../ui/FormSection'
import { FormAdvisory } from '../ui/FormAdvisory'
import { FormToolbar, revealBlocker } from '../ui/FormToolbar'
import { DepthDisclosure } from '../ui/DepthDisclosure'
import { Body, Emphasis, Label, Secondary } from '../ui/Text'
import { remainingText, StatusTag } from '../components/status'
import {
  ago,
  categoryLabels,
  fmtDate,
  fmtMileageBare,
  fmtShortDate,
  MILES_PER_DAY,
  today,
  type CostCategory,
  type Service,
  type ServiceLog,
} from '../data/fixtures'
import { isMarbete, sortedByUrgency, useScenario } from '../data/scenario'
import { kindLabels, sampleReceipt, type Confidence, type ReceiptDraft } from '../data/receipt'

export type FormMode = 'log' | 'complete' | 'edit'

type When = 'today' | 'yesterday' | 'date' | 'later'
type DueKind = 'interval' | 'date' | 'mileage'

/** Catalog intervals for services picked by name rather than from a schedule. */
const CATALOG: Record<string, { months?: number; miles?: number }> = {
  'Oil & Filter Change': { months: 6, miles: 5_000 },
  'Tire Rotation': { months: 6, miles: 6_000 },
  'Wiper Blades': { months: 12 },
  'Wheel Alignment': { months: 24, miles: 24_000 },
}

const DAY = 24 * 60 * 60 * 1000
const addMonths = (d: Date, n: number) => new Date(d.getFullYear(), d.getMonth() + n, d.getDate())
const parseMiles = (s: string) => {
  const n = parseInt(s.replace(/\D/g, ''), 10)
  return Number.isFinite(n) ? n : undefined
}

export function ServiceForm(props: {
  mode: FormMode
  /** complete: the service being marked done. */
  service?: Service
  /** edit: the log being edited. */
  log?: ServiceLog
  /** Open with a receipt already read (the Visual Intelligence / Share door). */
  receipt?: ReceiptDraft
  onClose?: () => void
}) {
  const data = useScenario()
  const v = () => data().vehicle!
  const editing = props.mode === 'edit'
  const orig = props.log

  // --- State ------------------------------------------------------------
  const [name, setName] = createSignal(props.service?.name ?? orig?.name ?? '')
  const [linked, setLinked] = createSignal<Service | undefined>(props.service)
  const [pickerOpen, setPickerOpen] = createSignal(props.mode === 'log')

  const origWhen: When = orig ? 'date' : 'today'
  const origDate = orig ? fmtDate(orig.performedAt) : ''
  const [when, setWhen] = createSignal<When>(origWhen)
  const [customDate, setCustomDate] = createSignal(origDate)

  const origOdo = orig?.mileage != null ? fmtMileageBare(orig.mileage) : fmtMileageBare(v().currentMileage)
  const origCost = orig?.cost != null ? orig.cost.toFixed(2) : ''
  const [odometer, setOdometer] = createSignal(origOdo)
  const [cost, setCost] = createSignal(origCost)
  const [remind, setRemind] = createSignal(true)

  const [dueKind, setDueKind] = createSignal<DueKind>('interval')
  const [dueValue, setDueValue] = createSignal('')

  const [category, setCategory] = createSignal<CostCategory>(orig?.category ?? 'maintenance')
  const [notes, setNotes] = createSignal('')

  const [mileageResolution, setMileageResolution] = createSignal<'adopt' | 'keep'>()
  const [showBlocker, setShowBlocker] = createSignal(false)
  let scrollRef: HTMLDivElement | undefined

  const later = () => when() === 'later'

  // --- Receipt: values land in their own fields, marked until edited -----
  const [receipt, setReceipt] = createSignal<ReceiptDraft>()
  const [shop, setShop] = createSignal('')
  type Snapshot = { name: string; linked?: Service; pickerOpen: boolean; when: When; customDate: string; odometer: string; cost: string }
  let beforeReceipt: Snapshot | undefined
  const receiptValue = {
    name: () => receipt()?.serviceName ?? '',
    date: () => (receipt()?.date ? fmtDate(receipt()!.date!) : ''),
    odometer: () => (receipt()?.odometer != null ? fmtMileageBare(receipt()!.odometer!) : ''),
    cost: () => (receipt()?.total != null ? receipt()!.total!.toFixed(2) : ''),
    shop: () => receipt()?.shopName ?? '',
  }
  /** A field is SUGGESTED while it still holds exactly what the receipt said. */
  const suggested = (field: keyof typeof receiptValue, current: string) =>
    receipt() != null && receiptValue[field]() !== '' && current === receiptValue[field]()

  const applyReceipt = (r: ReceiptDraft) => {
    beforeReceipt = { name: name(), linked: linked(), pickerOpen: pickerOpen(), when: when(), customDate: customDate(), odometer: odometer(), cost: cost() }
    setReceipt(r)
    if (r.serviceName && props.mode === 'log') {
      choose(r.serviceName, data().services.find((s) => s.name === r.serviceName))
    }
    if (r.date) {
      setWhen('date')
      setCustomDate(fmtDate(r.date))
    }
    if (r.odometer != null) setOdometer(fmtMileageBare(r.odometer))
    if (r.total != null) setCost(r.total.toFixed(2))
    setShop(r.shopName ?? '')
  }
  const clearReceipt = () => {
    const b = beforeReceipt
    setReceipt(undefined)
    setShop('')
    if (!b) return
    setName(b.name)
    setLinked(b.linked)
    setPickerOpen(b.pickerOpen)
    setWhen(b.when)
    setCustomDate(b.customDate)
    setOdometer(b.odometer)
    setCost(b.cost)
  }
  const lineSum = () => (receipt()?.lineItems ?? []).reduce((sum, l) => sum + (l.kind === 'discount' ? -l.amount : l.amount), 0)
  const itemsAddUp = () => receipt()?.total == null || Math.abs(lineSum() - receipt()!.total!) < 0.02

  // --- Picker content: due now → recent → browse ------------------------
  const dueNow = () =>
    sortedByUrgency(data().services, v()).filter((s) => s.status === 'overdue' || s.status === 'dueSoon')
  /** Distinct recently-logged names not already offered under Due now. */
  const recent = () => {
    const seen = new Set(dueNow().map((s) => s.name))
    const out: { name: string; at: Date }[] = []
    for (const l of data().logs) {
      if (seen.has(l.name)) continue
      seen.add(l.name)
      out.push({ name: l.name, at: l.performedAt })
    }
    return out.slice(0, 3)
  }

  const choose = (n: string, s?: Service) => {
    setName(n)
    setLinked(s)
    setPickerOpen(false)
    setShowBlocker(false)
  }

  const interval = () => {
    const s = linked()
    if (s && (s.intervalMonths || s.intervalMiles)) return { months: s.intervalMonths, miles: s.intervalMiles }
    return CATALOG[name()]
  }
  const intervalText = () => {
    const i = interval()
    if (!i) return undefined
    return [i.months ? `${i.months} mo` : null, i.miles ? `${fmtMileageBare(i.miles)} mi` : null]
      .filter(Boolean)
      .join(' / ')
  }

  // --- Mileage (MileageCommit rules; SURFACE_DOCTRINE "values that mean two things")
  const entered = () => parseMiles(odometer())
  const isBackfill = () => when() === 'date' && !editing
  const estimate = () =>
    v().currentMileage + Math.round(((today.getTime() - v().mileageUpdatedAt.getTime()) / DAY) * MILES_PER_DAY)
  const confirmedAge = () => Math.round((today.getTime() - v().mileageUpdatedAt.getTime()) / DAY)
  /* A hand-picked date AFTER the last confirmed reading is not backfill in the
     sense that matters: its reading is the newest observation, so it is adopted
     (and said so) like Today's. Found by the receipt flow — a receipt from two
     days ago carries a higher odometer than a nine-day-old reading, and the old
     rule raised a contradiction that blocked Save on nearly every receipt. */
  const pickedDate = () => new Date(customDate())
  const newerThanLastReading = () =>
    when() !== 'date' || (!Number.isNaN(pickedDate().getTime()) && pickedDate() >= v().mileageUpdatedAt)
  const wouldAdopt = () => {
    const r = entered()
    return !later() && r != null && r > v().currentMileage && (!isBackfill() || newerThanLastReading())
  }
  const contradiction = () => {
    const r = entered()
    return !later() && r != null && isBackfill() && !newerThanLastReading() && r > v().currentMileage && !mileageResolution()
  }

  // --- Projection (F4: same calculation as the save path) ---------------
  const performedAt = () => (when() === 'yesterday' ? ago(1) : today)
  const nextDue = () => {
    const i = interval()
    if (!i) return undefined
    const base = later() ? today : performedAt()
    const odo = later() ? v().currentMileage : (entered() ?? v().currentMileage)
    return {
      date: i.months ? addMonths(base, i.months) : undefined,
      miles: i.miles ? odo + i.miles : undefined,
    }
  }
  const nextText = () => {
    const n = nextDue()
    if (!n) return undefined
    return [n.date ? fmtDate(n.date) : null, n.miles ? `${fmtMileageBare(n.miles)} mi` : null]
      .filter(Boolean)
      .join(' or ')
  }
  const scheduleText = () => {
    if (dueKind() === 'interval') return nextText() ?? 'choose when it is due'
    if (!dueValue().trim()) return dueKind() === 'mileage' ? 'once you enter a mileage' : 'once you pick a date'
    return dueKind() === 'mileage' ? `at ${dueValue()} mi` : dueValue()
  }

  // --- Blocking (F2) ----------------------------------------------------
  type BlockKey = 'service' | 'date' | 'due' | 'odometer'
  const blocker = createMemo<{ key: BlockKey; message: string } | undefined>(() => {
    if (!name().trim()) return { key: 'service', message: 'Pick a service, or type its name.' }
    if (when() === 'date' && !customDate().trim()) return { key: 'date', message: 'Pick the date it was done.' }
    if (later() && dueKind() !== 'interval' && !dueValue().trim())
      return { key: 'due', message: 'Enter when it is due, or this reminder will never fire.' }
    if (later() && dueKind() === 'interval' && !interval())
      return { key: 'due', message: 'This service has no usual interval — pick a date or mileage.' }
    if (contradiction()) return { key: 'odometer', message: 'Resolve the odometer conflict first.' }
    return undefined
  })
  const blockerAt = (key: BlockKey) => (
    <Show when={showBlocker() && blocker()?.key === key}>
      <div data-blocker={key}>
        <FormAdvisory severity="blocking" message={blocker()!.message} />
      </div>
    </Show>
  )

  // Edit: Save only once something actually changed.
  const dirty = () =>
    !editing ||
    name() !== orig!.name ||
    odometer() !== origOdo ||
    cost() !== origCost ||
    customDate() !== origDate ||
    when() !== origWhen ||
    category() !== orig!.category ||
    notes() !== ''

  const canSave = () => blocker() == null && dirty()

  const title = () =>
    later()
      ? 'Schedule Service'
      : editing
        ? 'Edit Entry'
        : props.mode === 'complete' || linked()
          ? 'Complete Service'
          : 'Log Service'

  const subtitle = () => {
    const x = v()
    return x.name ? `${x.name} · ${x.year} ${x.model}` : `${x.year} ${x.make} ${x.model}`
  }

  // After `choose` exists: the receipt door opens already filled.
  if (props.receipt) applyReceipt(props.receipt)

  const whenChips: { value: When; label: string }[] = [
    { value: 'today', label: 'Today' },
    { value: 'yesterday', label: 'Yesterday' },
    { value: 'date', label: 'Pick date…' },
    { value: 'later', label: 'Not done yet' },
  ]

  return (
    <div style={{ display: 'flex', 'flex-direction': 'column', flex: '1 1 auto', 'min-height': '0' }}>
      <FormToolbar
        title={title()}
        subtitle={subtitle()}
        canSave={canSave()}
        onCancel={props.onClose}
        onSave={props.onClose}
        onBlocked={() => {
          if (!blocker()) return // edit with no changes: nothing to point at
          setShowBlocker(true)
          if (blocker()!.key === 'service') setPickerOpen(true)
          revealBlocker(scrollRef, blocker()!.key)
        }}
      />

      <div
        ref={scrollRef}
        style={{
          flex: '1 1 auto',
          'min-height': '0',
          'overflow-y': 'auto',
          display: 'flex',
          'flex-direction': 'column',
          gap: 'var(--space-xl)',
          padding: 'var(--space-md) var(--space-screen-h) var(--space-xxl)',
        }}
      >
        {/* ---------- 0. RECEIPT — first, because it answers most of the form ---------- */}
        <Show when={!editing && !later()}>
          <ReceiptRow receipt={receipt()} onScan={() => applyReceipt(sampleReceipt)} onClear={clearReceipt} />
        </Show>

        {/* ---------- 1. SERVICE ---------- */}
        <FormSection title="Service">
          {blockerAt('service')}
          <Show
            when={pickerOpen()}
            fallback={
              <>
                <SelectedService
                  name={name()}
                  onChange={() => setPickerOpen(true)}
                  locked={props.mode === 'complete'}
                />
                <Show when={props.mode === 'log' && suggested('name', name())}>
                  <FromReceipt confidence={receipt()!.confidence.service} />
                </Show>
              </>
            }
          >
            <Field
              value={name()}
              onInput={(n) => {
                setName(n)
                setLinked(undefined)
              }}
              placeholder="Type a service name"
            />

            <Show when={dueNow().length}>
              <FormSubgroup title="Due now">
                <div style={{ display: 'flex', 'flex-direction': 'column' }}>
                  <For each={dueNow()}>
                    {(s) => (
                      <PickRow name={s.name} onClick={() => choose(s.name, s)}>
                        <StatusTag status={s.status} text={remainingText(s, v())} />
                      </PickRow>
                    )}
                  </For>
                </div>
              </FormSubgroup>
            </Show>

            {/* Rows, like Due now — not chips. As plain chips the recent names
                were 11pt tracked caps wrapping into three 44pt rows: the same
                height as rows, but shouted, and a second option vocabulary in
                one picker. */}
            <Show when={recent().length}>
              <FormSubgroup title="Recent">
                <div style={{ display: 'flex', 'flex-direction': 'column' }}>
                  <For each={recent()}>
                    {(r) => (
                      <PickRow name={r.name} onClick={() => choose(r.name)}>
                        <Secondary color="tertiary">{fmtShortDate(r.at)}</Secondary>
                      </PickRow>
                    )}
                  </For>
                </div>
              </FormSubgroup>
            </Show>

            <button style={{ 'min-height': 'var(--touch-target)', display: 'flex', 'align-items': 'center', gap: 'var(--space-sm)' }}>
              <Body color="accent">Browse all services</Body>
              <Body color="tertiary">›</Body>
            </button>
          </Show>

          {/* The system says what it will do: saving completes the schedule. */}
          <Show when={linked() && !pickerOpen() && !later()}>
            <FormAdvisory
              severity="info"
              message={
                isMarbete(linked()!)
                  ? `Renews ${linked()!.name} — it expires ${remainingText(linked()!, v())}.`
                  : `Completes ${linked()!.name} — ${remainingText(linked()!, v())}.`
              }
            />
          </Show>
        </FormSection>

        {/* ---------- 2. WHEN — derives intent; Today is the default ---------- */}
        <FormSection title="When">
          {blockerAt('date')}
          <ChipRow>
            <For each={whenChips}>
              {(c) => (
                <Chip
                  label={c.label}
                  selected={when() === c.value}
                  onClick={() => {
                    setWhen(c.value)
                    setMileageResolution(undefined)
                  }}
                />
              )}
            </For>
          </ChipRow>
          <Show when={when() === 'date'}>
            <Field
              label="Date"
              value={customDate()}
              onInput={setCustomDate}
              placeholder="Aug 14, 2025"
              original={editing ? origDate : undefined}
              below={
                <Show when={suggested('date', customDate())}>
                  <FromReceipt confidence={receipt()!.confidence.date} />
                </Show>
              }
            />
          </Show>
        </FormSection>

        {/* ---------- 3a. DONE: what the visit recorded ---------- */}
        <Show when={!later()}>
          <FormSection title="Details">
            {blockerAt('odometer')}
            <Field
              label="Odometer at service"
              value={odometer()}
              onInput={(x) => {
                setOdometer(x)
                setMileageResolution(undefined)
              }}
              suffix="mi"
              numeric
              original={editing ? origOdo : undefined}
              below={
                <>
                  <Show when={suggested('odometer', odometer())}>
                    <FromReceipt confidence={receipt()!.confidence.odometer} />
                  </Show>
                  <Show when={!editing && !wouldAdopt() && !contradiction()}>
                    <div style={{ display: 'flex', 'align-items': 'baseline', gap: 'var(--space-sm)', 'flex-wrap': 'wrap' }}>
                      <Secondary color="tertiary">
                        Confirmed {confirmedAge()} d ago · est. now ~{fmtMileageBare(estimate())}
                      </Secondary>
                      <Show when={estimate() !== v().currentMileage}>
                        <button onClick={() => setOdometer(fmtMileageBare(estimate()))} style={{ 'min-height': '28px' }}>
                          <Label color="accent" tracking={1}>
                            [Use]
                          </Label>
                        </button>
                      </Show>
                    </div>
                  </Show>
                  <Show when={wouldAdopt()}>
                    <FormAdvisory
                      severity="info"
                      message={`Will update current mileage to ${fmtMileageBare(entered()!)} mi.`}
                    />
                  </Show>
                  <Show when={contradiction()}>
                    <FormAdvisory
                      severity="contradiction"
                      message={`This is dated before your last reading but is higher than it (${fmtMileageBare(v().currentMileage)} mi). Which is right?`}
                      outcomes={[
                        { label: 'Keep my odometer', onClick: () => setMileageResolution('keep') },
                        { label: 'Correct it upward', onClick: () => setMileageResolution('adopt') },
                      ]}
                    />
                  </Show>
                </>
              }
            />

            <Field
              label="Cost"
              prefix="$"
              value={cost()}
              onInput={setCost}
              placeholder="0.00"
              numeric
              original={editing ? origCost : undefined}
              below={
                <Show when={suggested('cost', cost())}>
                  <FromReceipt confidence={receipt()!.confidence.total} />
                </Show>
              }
            />

            {/* Only when the receipt names one: the form keeps no shop otherwise. */}
            <Show when={receiptValue.shop()}>
              <Field
                label="Shop"
                value={shop()}
                onInput={setShop}
                multiline
                below={
                  <Show when={suggested('shop', shop())}>
                    <FromReceipt confidence={receipt()!.confidence.shop} />
                  </Show>
                }
              />
            </Show>
          </FormSection>

          {/* ---------- 4a. NEXT — the reminder this entry leaves behind ----------
              A readout (label + emphasis), not an advisory: it is the value the
              save produces. The toggle is the only decision, and it defaults on. */}
          <Show when={intervalText()}>
            <FormSection title="Next Reminder">
              <div style={{ display: 'flex', 'flex-direction': 'column', gap: '2px' }}>
                <Emphasis color={remind() ? 'primary' : 'tertiary'} as="div">
                  {remind() ? nextText() : 'No reminder'}
                </Emphasis>
                <Secondary color="tertiary" as="div">
                  {remind()
                    ? `Every ${intervalText()}, whichever comes first.`
                    : `${name()} won't come back on its own.`}
                </Secondary>
              </div>
              <Toggle label="Remind me" checked={remind()} onChange={setRemind} />
            </FormSection>
          </Show>
        </Show>

        {/* ---------- 3b. NOT DONE YET: when it is due ---------- */}
        <Show when={later()}>
          <FormSection title="Due">
            {blockerAt('due')}
            <ChipRow>
              <Show when={intervalText()}>
                <Chip label={`In ${intervalText()}`} selected={dueKind() === 'interval'} onClick={() => setDueKind('interval')} />
              </Show>
              <Chip label="Pick date…" selected={dueKind() === 'date'} onClick={() => setDueKind('date')} />
              <Chip label="At mileage…" selected={dueKind() === 'mileage'} onClick={() => setDueKind('mileage')} />
            </ChipRow>
            <Show when={dueKind() !== 'interval'}>
              <Field
                label={dueKind() === 'mileage' ? 'Remind me at' : 'Due date'}
                value={dueValue()}
                onInput={setDueValue}
                suffix={dueKind() === 'mileage' ? 'mi' : undefined}
                numeric={dueKind() === 'mileage'}
                placeholder={dueKind() === 'mileage' ? fmtMileageBare(v().currentMileage + 5_000) : 'Jan 25, 2027'}
              />
            </Show>
            <div style={{ display: 'flex', 'align-items': 'baseline', gap: 'var(--space-md)', 'padding-top': 'var(--space-xs)' }}>
              <Label style={{ flex: '0 0 auto' }}>Fires</Label>
              <Emphasis color={blocker()?.key === 'due' ? 'tertiary' : 'primary'}>{scheduleText()}</Emphasis>
            </div>
            <Toggle
              label="Repeat after each service"
              detail={intervalText() ? `Every ${intervalText()}` : 'Set an interval under More Details'}
              checked={remind()}
              onChange={setRemind}
            />
          </FormSection>
        </Show>

        {/* ---------- 5. DEPTH — what makes it complete ---------- */}
        <DepthDisclosure
          summary={
            later()
              ? 'Notes'
              : receipt()?.lineItems.length
                ? `${categoryLabels[category()]} · ${receipt()!.lineItems.length} receipt items · notes`
                : `${categoryLabels[category()]} · notes · receipt`
          }
        >
              <Show when={!later()}>
                <InlinePicker
                  label="Category"
                  value={category()}
                  onChange={setCategory}
                  options={(Object.keys(categoryLabels) as CostCategory[]).map((c) => ({
                    value: c,
                    label: categoryLabels[c],
                  }))}
                />
              </Show>
              {/* A breakdown of the total, never added on top of it. */}
              <Show when={!later() && receipt()?.lineItems.length}>
                <FormSubgroup title="Receipt items">
                  <div style={{ display: 'flex', 'flex-direction': 'column' }}>
                    <For each={receipt()!.lineItems}>
                      {(item) => (
                        <div
                          style={{
                            display: 'flex',
                            'align-items': 'baseline',
                            gap: 'var(--space-sm)',
                            'min-height': 'var(--touch-target)',
                            'padding-top': 'var(--space-sm)',
                            'border-bottom': '1px solid var(--grid-line)',
                          }}
                        >
                          <div style={{ display: 'flex', 'flex-direction': 'column', flex: '1 1 auto', 'min-width': '0' }}>
                            <Body lines={1}>{item.label}</Body>
                            <Secondary color="tertiary">{kindLabels[item.kind]}</Secondary>
                          </div>
                          <Body style={{ flex: '0 0 auto' }}>
                            {item.kind === 'discount' ? '−' : ''}${item.amount.toFixed(2)}
                          </Body>
                        </div>
                      )}
                    </For>
                  </div>
                  <Show
                    when={itemsAddUp()}
                    fallback={
                      <FormAdvisory
                        severity="caution"
                        message={`The items add up to $${lineSum().toFixed(2)}, not the $${receipt()!.total!.toFixed(2)} total. The total is what's saved.`}
                      />
                    }
                  >
                    <Secondary color="tertiary">Adds up to the total. Only the total counts toward your costs.</Secondary>
                  </Show>
                </FormSubgroup>
              </Show>
              <Field label="Notes" value={notes()} onInput={setNotes} placeholder="Used full synthetic" />
              <Show when={!later()}>
                <button
                  style={{
                    'min-height': 'var(--button-height)',
                    border: 'var(--border-width) solid var(--border-subtle)',
                    display: 'flex',
                    'align-items': 'center',
                    'justify-content': 'center',
                  }}
                >
                  <Body color="secondary">Attach a receipt</Body>
                </button>
              </Show>
        </DepthDisclosure>

        {/* Destructive, last, and only where there is something to delete. */}
        <Show when={editing}>
          <button style={{ 'min-height': 'var(--touch-target)', 'align-self': 'center' }}>
            <Body color="overdue">Delete Entry</Body>
          </button>
        </Show>
      </div>
    </div>
  )
}

/** One option in the service picker: name leading, context trailing. */
function PickRow(props: { name: string; onClick: () => void; children: JSX.Element }) {
  return (
    <button
      onClick={props.onClick}
      data-pick={props.name}
      style={{
        display: 'flex',
        'align-items': 'center',
        gap: 'var(--space-sm)',
        'min-height': 'var(--touch-target)',
        padding: 'var(--space-xs) 0',
        'border-bottom': '1px solid var(--grid-line)',
      }}
    >
      <Emphasis lines={1} style={{ flex: '1 1 auto', 'min-width': '0', 'text-align': 'left' }}>
        {props.name}
      </Emphasis>
      <span style={{ flex: '0 0 auto' }}>{props.children}</span>
    </button>
  )
}

/** The picker, collapsed to its answer. */
function SelectedService(props: { name: string; locked?: boolean; onChange: () => void }) {
  // No status tag here: the .info line beneath ("Completes … — 917 mi over")
  // already says it, and saying it twice was the first thing the eye hit.
  return (
    <div style={{ display: 'flex', 'align-items': 'center', gap: 'var(--space-sm)', 'min-height': 'var(--touch-target)' }}>
      <Emphasis as="div" lines={2} style={{ flex: '1 1 auto', 'min-width': '0' }}>
        {props.name}
      </Emphasis>
      <Show when={!props.locked}>
        <button onClick={props.onChange} style={{ 'min-height': 'var(--touch-target)', padding: '0 var(--space-xs)' }}>
          <Label color="accent" tracking={1}>
            [Change]
          </Label>
        </button>
      </Show>
    </div>
  )
}

/**
 * The receipt door, first in the form. Before a scan it is shaped like the
 * More details trigger — an offer, not a section. After, it becomes the one
 * .info line that says what the system filled in, with [Clear] beside it.
 */
function ReceiptRow(props: { receipt?: ReceiptDraft; onScan: () => void; onClear: () => void }) {
  return (
    <Show
      when={props.receipt}
      fallback={
        <button
          onClick={props.onScan}
          style={{
            display: 'flex',
            'flex-direction': 'column',
            gap: '2px',
            'min-height': '54px',
            'justify-content': 'center',
            'border-bottom': 'var(--border-width) solid var(--grid-line)',
            'text-align': 'left',
          }}
        >
          <Body color="accent">Scan a receipt</Body>
          <Secondary color="tertiary" lines={1} as="div">
            Fills the date, odometer, total and shop
          </Secondary>
        </button>
      }
    >
      <div style={{ display: 'flex', 'align-items': 'flex-start', gap: 'var(--space-sm)' }}>
        <div style={{ flex: '1 1 auto', 'min-width': '0' }}>
          <FormAdvisory severity="info" message="Filled in from your receipt. Check the values marked From receipt, then save." />
        </div>
        <button onClick={props.onClear} style={{ 'min-height': 'var(--touch-target)', padding: '0 var(--space-xs)', flex: '0 0 auto' }}>
          <Label color="accent" tracking={1}>
            [Clear]
          </Label>
        </button>
      </div>
    </Show>
  )
}

/**
 * Provenance under a field, the F6 shape: shown only while the value is still
 * the receipt's. A value the reader was unsure of is a .caution instead — the
 * user must look at it, and it sits beside the field that fixes it.
 */
function FromReceipt(props: { confidence: Confidence }) {
  return (
    <Show
      when={props.confidence !== 'low'}
      fallback={<FormAdvisory severity="caution" message="Hard to read on the receipt — check this value." />}
    >
      <Secondary color="tertiary">From receipt</Secondary>
    </Show>
  )
}

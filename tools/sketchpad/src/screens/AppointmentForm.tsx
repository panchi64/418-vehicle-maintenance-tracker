/*
 * Shop visit sheet — Decision surface. Book or edit an appointment.
 *
 * PROBLEM. Booking a shop visit is three facts — where, when, what for — and
 * the value of recording it is the reminder it leaves. The form has to get
 * those three from the user in a few taps and then PROVE the reminder will
 * fire, without turning into a calendar-event editor.
 *
 * RESOLVED LAYOUT:
 *
 *   Cancel     Book Shop Visit · Daily Driver       [Save]
 *   Shop ────────────────────────────────────
 *     [Toy|                              ]    field, no label (header names it);
 *     Toyota de Puerto Rico                   grows to 2+ lines for long names
 *     …                                       suggestions: plain 15 rows, only
 *                                             while typing, max 3
 *   When ────────────────────────────────────
 *     DATE [Sun, Jul 26]   TIME [9:00 AM]     wrapping pair; default tomorrow 9:00
 *     ▌Already booked that day: …             .caution, only on a same-day clash
 *     REMINDERS                               readout: 11 label over
 *     Sun 9:30 AM and Mon 8:30 AM             a 15 Medium value
 *   Services ────────────────────────────── 1 PICKED
 *     ■ Oil & Filter Change                   check rows, most urgent first;
 *     □ Tire Rotation & Balance               Next Up preselected from Home
 *   More details ⌄  Address · note            depth
 *   Cancel Appointment                        edit only, destructive, last
 *
 * DECISIONS
 *   - Reminders are a READOUT, not an .info advisory: they are the value the
 *     save produces (same resolution as the service form's Next Reminder).
 *     Two fixed rules — the day before at the same time, and an hour before —
 *     so there is nothing to configure and no toggle. FOUND BY RUNNING IT:
 *     the default (tomorrow 9:00) booked any time after 9 AM has already
 *     lost its day-before reminder, so the most common booking showed one
 *     time where the rule promises two. The label drops to "Reminder" and a
 *     tertiary line says why ("The day-before one would already have
 *     passed") — the system saying what it did instead of looking broken.
 *   - Services are CHECK ROWS, not the toggle chips first specified. Outlined
 *     chips were tried first: with the long names each chip took its own
 *     row anyway, and once three or four were selected (filled accent) the
 *     squint showed a stack of bright slabs and nothing else — Services, an
 *     optional field with a working default, out-shouted Shop and When.
 *     Plain chips were tried next: selected vs unselected became brightness
 *     alone, and the rows read exactly like the shop suggestions above them.
 *     A 22pt square (outlined → filled ✓) + name keeps selection on shape
 *     and colour while enclosing only the square.
 *   - Shop suggestions appear only while typing, as plain rows (the service
 *     picker's row vocabulary), never chips. Tapping one fills the field and
 *     the rows go.
 *   - Shop, address and note wrap and grow (Field `multiline`). As
 *     single-line inputs the 50-character Firestone name scrolled out of its
 *     field at 1.0x, and "Toyota de Puerto Rico" did at 2x.
 *   - The same-day clash is .caution beside When — the control that resolves
 *     it — and never blocks: two visits on one day (tires in the morning,
 *     inspection after lunch) is legitimate.
 *   - Address and note are depth: Directions works from the shop's name
 *     alone, so an address only makes the booking complete.
 *   - Required: the shop only (Directions, the reminder text and Home's
 *     secondary line all read it). Zero services is valid — "just a check".
 *
 * TAP BUDGET — book from Home: target ≤ 6, measured 4 in-frame.
 *   [Book] → (Shop autofocused: type "toy") → Toyota de Puerto Rico →
 *   Date field (type) → Save. Keeping tomorrow 9:00 makes it 3; the
 *   preselected Next Up service costs nothing. On device the date is a
 *   compact DatePicker — tap the date, tap the day, tap away — so the
 *   change-the-day path is 6, exactly the budget. Autofocusing Shop is what
 *   pays for it: without it the same path was 7.
 */
import { createSignal, For, Show } from 'solid-js'
import { Field } from '../ui/Controls'
import { FormSection } from '../ui/FormSection'
import { FormAdvisory } from '../ui/FormAdvisory'
import { FormToolbar, revealBlocker } from '../ui/FormToolbar'
import { DepthDisclosure } from '../ui/DepthDisclosure'
import { CheckRow } from '../ui/CheckRow'
import { Body, Emphasis, Label, Secondary } from '../ui/Text'
import { sortedByUrgency, useScenario } from '../data/scenario'
import { today } from '../data/fixtures'
import {
  at,
  fmtDay,
  fmtTime,
  previousShops,
  reminderText,
  reminderTimes,
  type Appointment,
} from '../data/visits'

export function AppointmentForm(props: {
  appointment?: Appointment
  /** Booking from Home preselects the Next Up service. */
  preselectServiceId?: string
  /** Opens on a given start instead of tomorrow 9:00 (the clash fixture). */
  initialStart?: Date
  onClose: () => void
}) {
  const data = useScenario()
  const a = props.appointment
  const editing = !!a
  const start0 = a?.startsAt ?? props.initialStart ?? at(1, 9, 0)

  const [shop, setShop] = createSignal(a?.shop ?? '')
  const [typing, setTyping] = createSignal(false)
  const [dateText, setDateText] = createSignal(fmtDay(start0))
  const [timeText, setTimeText] = createSignal(fmtTime(start0))
  const [serviceIds, setServiceIds] = createSignal<string[]>(
    a?.serviceIds ?? (props.preselectServiceId ? [props.preselectServiceId] : []),
  )
  const [address, setAddress] = createSignal(a?.address ?? '')
  const [note, setNote] = createSignal(a?.note ?? '')
  const [clashDismissed, setClashDismissed] = createSignal(false)
  const [showBlocker, setShowBlocker] = createSignal(false)
  let scrollRef: HTMLDivElement | undefined

  /** Lenient, like the system picker's output: "Sun, Jul 26" + "9:00 AM". */
  const start = () => {
    const d = new Date(`${dateText().replace(/^\w+,\s*/, '')} ${today.getFullYear()} ${timeText()}`)
    return Number.isNaN(d.getTime()) ? undefined : d
  }

  const shops = () => previousShops(data().logs, data().appointments)
  const suggestions = () => {
    const q = shop().trim().toLowerCase()
    if (!typing() || !q) return []
    return shops().filter((s) => s.toLowerCase().includes(q) && s.toLowerCase() !== q).slice(0, 3)
  }

  const clash = () => {
    const s = start()
    if (!s) return undefined
    return data().appointments.find(
      (x) => x.id !== a?.id && x.startsAt.toDateString() === s.toDateString(),
    )
  }

  const services = () => sortedByUrgency(data().services, data().vehicle!)
  const toggleService = (id: string) =>
    setServiceIds(serviceIds().includes(id) ? serviceIds().filter((x) => x !== id) : [...serviceIds(), id])

  type BlockKey = 'shop' | 'when'
  const blocker = (): { key: BlockKey; message: string } | undefined => {
    if (!shop().trim()) return { key: 'shop', message: 'Name the shop — Directions and the reminders use it.' }
    if (!start()) return { key: 'when', message: 'Enter a date like Jul 27 and a time like 9:30 AM.' }
    return undefined
  }
  const blockerAt = (key: BlockKey) => (
    <Show when={showBlocker() && blocker()?.key === key}>
      <div data-blocker={key}>
        <FormAdvisory severity="blocking" message={blocker()!.message} />
      </div>
    </Show>
  )

  const dirty = () =>
    !editing ||
    shop() !== a!.shop ||
    start()?.getTime() !== a!.startsAt.getTime() ||
    serviceIds().join() !== a!.serviceIds.join() ||
    address() !== (a!.address ?? '') ||
    note() !== (a!.note ?? '')

  const subtitle = () => {
    const v = data().vehicle!
    return v.name || `${v.year} ${v.make} ${v.model}`
  }

  return (
    <div style={{ display: 'flex', 'flex-direction': 'column', flex: '1 1 auto', 'min-height': '0' }}>
      <FormToolbar
        title={editing ? 'Edit Shop Visit' : 'Book Shop Visit'}
        subtitle={subtitle()}
        canSave={!blocker() && dirty()}
        onCancel={props.onClose}
        onSave={props.onClose}
        onBlocked={() => {
          if (!blocker()) return
          setShowBlocker(true)
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
        {/* ---------- 1. SHOP ---------- */}
        <FormSection title="Shop">
          {blockerAt('shop')}
          <Field
            value={shop()}
            onInput={(v) => {
              setShop(v)
              setTyping(true)
              setShowBlocker(false)
            }}
            placeholder="Shop name"
            autofocus={!editing}
            multiline
          />
          <Show when={suggestions().length}>
            <div style={{ display: 'flex', 'flex-direction': 'column', 'margin-top': 'calc(var(--space-sm) * -1)' }}>
              <For each={suggestions()}>
                {(s) => (
                  <button
                    data-pick={s}
                    onClick={() => {
                      setShop(s)
                      setTyping(false)
                    }}
                    style={{
                      display: 'flex',
                      'align-items': 'center',
                      'min-height': 'var(--touch-target)',
                      'border-bottom': '1px solid var(--grid-line)',
                      'text-align': 'left',
                    }}
                  >
                    <Body color="secondary" lines={1}>
                      {s}
                    </Body>
                  </button>
                )}
              </For>
            </div>
          </Show>
        </FormSection>

        {/* ---------- 2. WHEN ---------- */}
        <FormSection title="When">
          {blockerAt('when')}
          <div style={{ display: 'flex', 'flex-wrap': 'wrap', gap: 'var(--space-md)' }}>
            <div style={{ flex: '3 1 calc(150px * var(--type-scale))', 'min-width': '0' }}>
              <Field
                label="Date"
                value={dateText()}
                onInput={(v) => {
                  setDateText(v)
                  setClashDismissed(false)
                }}
              />
            </div>
            <div style={{ flex: '2 1 calc(100px * var(--type-scale))', 'min-width': '0' }}>
              <Field label="Time" value={timeText()} onInput={setTimeText} />
            </div>
          </div>

          <Show when={clash() && !clashDismissed()}>
            <FormAdvisory
              severity="caution"
              message={`Already booked that day: ${clash()!.shop} at ${fmtTime(clash()!.startsAt)}.`}
              onDismiss={() => setClashDismissed(true)}
            />
          </Show>

          {/* The proof the booking does something. A value, so label + emphasis. */}
          <Show when={start()}>
            {(s) => (
              /* Label over value, like a Field, at every width. Side by side it
                 fit "Sun 8:00 AM" but wrapped two times onto a second line at
                 375pt 1.0x, so the row changed shape with the data. */
              <div style={{ display: 'flex', 'flex-direction': 'column', gap: '2px' }}>
                <Label>{reminderTimes(s()).length === 1 ? 'Reminder' : 'Reminders'}</Label>
                <Emphasis>{reminderText(s())}</Emphasis>
                {/* Says why one is missing, rather than silently showing one of two. */}
                <Show when={reminderTimes(s()).length < 2}>
                  <Secondary color="tertiary">
                    {reminderTimes(s()).length ? 'The day-before one would already have passed.' : 'Both would already have passed.'}
                  </Secondary>
                </Show>
              </div>
            )}
          </Show>
        </FormSection>

        {/* ---------- 3. SERVICES ---------- */}
        <FormSection title="Services" trailing={serviceIds().length ? `${serviceIds().length} picked` : undefined}>
          <Show
            when={services().length}
            fallback={<Body color="tertiary">No tracked services yet — the visit saves without any.</Body>}
          >
            <div style={{ display: 'flex', 'flex-direction': 'column' }}>
              <For each={services()}>
                {(s) => (
                  <CheckRow
                    label={s.name}
                    checked={serviceIds().includes(s.id)}
                    onClick={() => toggleService(s.id)}
                  />
                )}
              </For>
            </div>
          </Show>
        </FormSection>

        {/* ---------- 4. DEPTH ---------- */}
        <DepthDisclosure
          summary={`${address() || 'Address'} · ${note() || 'note'}`}
          initiallyOpen={editing && !!(a?.address || a?.note)}
        >
          <Field label="Address" value={address()} onInput={setAddress} placeholder="Directions use the shop name without one" multiline />
          <Field label="Note" value={note()} onInput={setNote} placeholder="Ask for Luis" multiline />
        </DepthDisclosure>

        <Show when={editing}>
          <button style={{ 'min-height': 'var(--touch-target)', 'align-self': 'center' }}>
            <Body color="overdue">Cancel Appointment</Body>
          </button>
        </Show>
      </div>
    </div>
  )
}

/*
 * Shop Visit — Home's third section (after Next Up, before Suggestions). Readout.
 *
 * PROBLEM. A booked appointment is the one fact about the car that is about a
 * TIME rather than a mileage, and it was nowhere on Home: you booked it, then
 * had to remember it. The question this section answers is "when am I due at
 * the shop, and where?" — and when the car is already there, "log it".
 *
 * RESOLVED LAYOUT (scheduled):
 *
 *   Shop Visit                                    [Book]
 *   Mon, Jul 27 · 9:30 AM                  ← primary: 20 Medium, text-primary
 *   Toyota de Puerto Rico                  ← secondary: 15 Regular, text-secondary
 *   — IN 2 DAYS  Oil & Filter Change · Tire…  ← tertiary: tag + services, ONE line
 *   [Directions]   [Log Visit]              ← bracket links, 44pt
 *   +1 more booked                          ← quiet 13, only when there are more
 *
 * Primary is the WHEN, on size (20 vs 15) and weight (500 vs 400) — plus
 * colour and position, but those two don't count toward the rule. The shop is
 * second because you know where you go; you forget when. The tag leads the
 * support line so it never truncates; the services are what falls off.
 *
 * Empty: header + one quiet line, "No shop visit booked." Same header, same
 * [Book] — the section's shape does not change with its data (Readout rule 2).
 *
 * TRIED AND REJECTED:
 *   - A bordered card with the relative figure at Hero size ("2 days"), shaped
 *     like Next Up. Under the squint Home showed two cards with two big
 *     numbers and no answer to which one mattered — and the figure dropped
 *     the actual time, which is what you need to show up. The 20pt heading is
 *     the most this section can take without out-shouting the hero; Next Up
 *     stays the only enclosed block on Home.
 *   - The relative tag on the when line ("Mon, Jul 27 · 9:30 AM  IN 2 DAYS").
 *     At 375pt and 1.0x the tag already wrapped under the time, alone.
 *   - An outlined [Log Visit]. It never tied with Mark Done (filled), but
 *     under the squint the box became the loudest thing in its own section,
 *     outranking the when — the section's primary — and making Directions
 *     look secondary for no reason. Brackets, as Suggestions resolved.
 *
 * CONSIDERED AND DECLINED (reasoned, not rendered):
 *   - Hiding [Directions] when there is no address. Maps searches the shop's
 *     name, so it still works — and an action row that changes shape per
 *     appointment is not learnable.
 *   - [Book] only in the empty state. Booking a second visit then had no door
 *     once one existed; keeping it fixed in the header costs nothing.
 *
 * Tapping the when/shop/support block opens the edit sheet (F13: it is a task,
 * so it presents). PORT NOTE: the block is two targets here only because the
 * audit needs the when in the primary slot; in SwiftUI it is one Button.
 */
import { Show } from 'solid-js'
import { ReadoutSection } from '../ui/ReadoutSection'
import { InsufficientDataNote } from '../ui/FormAdvisory'
import { Body, Heading, Label, Secondary } from '../ui/Text'
import { StatusTag } from './status'
import { useScenario } from '../data/scenario'
import { fmtDay, fmtTime, upcomingAppointments, visitTag, type Appointment } from '../data/visits'

export function ShopVisitSection(props: {
  onBook: () => void
  onEdit: (a: Appointment) => void
  onLogVisit: (a: Appointment) => void
}) {
  const data = useScenario()
  const upcoming = () => upcomingAppointments(data().appointments)
  const next = () => upcoming()[0] as Appointment | undefined
  const more = () => upcoming().length - 1

  const serviceNames = (a: Appointment) =>
    a.serviceIds
      .map((id) => data().services.find((s) => s.id === id)?.name)
      .filter(Boolean)
      .join(' · ')

  const openBlock = { display: 'flex', width: '100%', 'text-align': 'left' } as const

  return (
    <ReadoutSection
      title="Shop Visit"
      action={{ label: 'Book', onClick: props.onBook }}
      primary={
        <Show when={next()} fallback={<InsufficientDataNote message="No shop visit booked." />}>
          {(a) => (
            <button onClick={() => props.onEdit(a())} data-open="appointment" style={openBlock}>
              {/* Date and time are unbreakable halves, so 2x wraps between
                  them ("Sat, Jul 25 ·" / "9:00 AM"), never inside "Jul / 25". */}
              <Heading as="div" style={{ 'text-align': 'left' }}>
                <span style={{ 'white-space': 'nowrap' }}>{fmtDay(a().startsAt)} ·</span>{' '}
                <span style={{ 'white-space': 'nowrap' }}>{fmtTime(a().startsAt)}</span>
              </Heading>
            </button>
          )}
        </Show>
      }
      supporting={
        <Show when={next()}>
          {(a) => {
            const tag = () => visitTag(a().startsAt)
            return (
              <div style={{ display: 'flex', 'flex-direction': 'column', gap: '2px', 'margin-top': '-6px' }}>
                <button
                  onClick={() => props.onEdit(a())}
                  style={{ ...openBlock, 'flex-direction': 'column', gap: '2px' }}
                >
                  <Body color="secondary" lines={2} as="div">
                    {a().shop}
                  </Body>
                  <div
                    style={{
                      display: 'flex',
                      'align-items': 'center',
                      gap: 'var(--space-sm)',
                      width: '100%',
                      'min-width': '0',
                      'white-space': 'nowrap',
                      overflow: 'hidden',
                    }}
                  >
                    <StatusTag status={tag().status} text={tag().text} />
                    <Show when={a().serviceIds.length}>
                      <Secondary color="tertiary" style={{ overflow: 'hidden', 'text-overflow': 'ellipsis', 'min-width': '0' }}>
                        {serviceNames(a())}
                      </Secondary>
                    </Show>
                  </div>
                </button>

                {/* Column gap only: at 2x the pair wraps, and a 24pt row gap
                    on top of two 44pt targets left the second link floating. */}
                <div style={{ display: 'flex', 'column-gap': 'var(--space-lg)', 'flex-wrap': 'wrap' }}>
                  <BracketAction label="Directions" />
                  <BracketAction label="Log Visit" onClick={() => props.onLogVisit(a())} />
                </div>

                <Show when={more() > 0}>
                  <Secondary color="tertiary" as="div">
                    +{more()} more booked
                  </Secondary>
                </Show>
              </div>
            )
          }}
        </Show>
      }
    />
  )
}

function BracketAction(props: { label: string; onClick?: () => void }) {
  return (
    <button
      onClick={props.onClick}
      style={{ 'min-height': 'var(--touch-target)', display: 'flex', 'align-items': 'center' }}
    >
      <Label color="accent" tracking={1}>
        [{props.label}]
      </Label>
    </button>
  )
}

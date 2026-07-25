/*
 * Home.
 *
 * The problem being solved: nine sections can stack below the hero, each gated
 * by a different condition, all at uniform weight — so the tab's shape and
 * length are never the same twice and cannot be learned.
 *
 * The fix modelled here: a FIXED section order, every section a ReadoutSection
 * with one primary, and a cap on simultaneous advisory cards.
 */
import { For, Show } from 'solid-js'
import { NextUpCard, MileageReadout } from '../components/Cards'
import { ExpenseRow, ListDivider, ServiceRow } from '../components/Rows'
import { ReadoutSection } from '../ui/ReadoutSection'
import { FormAdvisory } from '../ui/FormAdvisory'
import { Emphasis, Secondary } from '../ui/Text'
import { Screen } from './Screen'
import { serviceLogs, services, vehicle } from '../data/fixtures'
import type { TabId } from '../components/TabBar'

export function HomeTab(props: { onNavigate: (tab: TabId) => void }) {
  const nextUp = () => services[0]
  const upcoming = () => services.slice(1, 4)
  const recent = () => serviceLogs.slice(0, 3)

  return (
    <Screen>
      {/* 1. Advisories, capped. Two at most — a stack of five equal-weight
             warnings is indistinguishable from noise and trains the user to
             scroll past all of them. */}
      <FormAdvisory
        severity="caution"
        message="Odometer last updated 9 days ago. Mileage-based estimates drift without it."
      />

      {/* 2. The hero. One per screen. */}
      <NextUpCard service={nextUp()} vehicle={vehicle} />

      {/* 3. Upcoming. */}
      <ReadoutSection
        title="Upcoming"
        action={{ label: 'View all', onClick: () => props.onNavigate('services') }}
        primary={
          <div style={{ display: 'flex', 'flex-direction': 'column' }}>
            <For each={upcoming()}>
              {(service, i) => (
                <>
                  <Show when={i() > 0}>
                    <ListDivider />
                  </Show>
                  <ServiceRow service={service} />
                </>
              )}
            </For>
          </div>
        }
      />

      {/* 4. Mileage readout — where the YTD/YoY metric belongs. It used to be a
             13pt tertiary subline in the corner of the persistent header, which
             is a genuinely interesting stat rendered where nobody would read it. */}
      <MileageReadout vehicle={vehicle} />

      {/* 5. Recent activity. "View all" lands on Service History, NOT on Costs —
             a maintenance-history list must not point at a financial view. */}
      <ReadoutSection
        title="Recent activity"
        action={{ label: 'View all', onClick: () => props.onNavigate('services') }}
        primary={
          <div style={{ display: 'flex', 'flex-direction': 'column' }}>
            <For each={recent()}>
              {(log, i) => (
                <>
                  <Show when={i() > 0}>
                    <ListDivider />
                  </Show>
                  <ExpenseRow log={log} />
                </>
              )}
            </For>
          </div>
        }
      />
    </Screen>
  )
}

/** The empty state, which must not clip behind the tab bar. */
export function HomeEmpty(props: { onAdd?: () => void }) {
  return (
    <Screen center>
      <div
        style={{
          display: 'flex',
          'flex-direction': 'column',
          gap: 'var(--space-sm)',
          'align-items': 'center',
          'text-align': 'center',
        }}
      >
        <Emphasis rank="primary">Nothing scheduled yet</Emphasis>
        <Secondary color="tertiary">
          Add a service to start tracking. One is enough to get reminders working.
        </Secondary>
        <button
          onClick={props.onAdd}
          style={{
            'margin-top': 'var(--space-sm)',
            'min-height': 'var(--button-height)',
            padding: '0 var(--space-lg)',
            border: 'var(--border-width) solid var(--accent)',
            background: 'var(--accent)',
          }}
        >
          <Emphasis style={{ color: 'var(--background-primary)' }} uppercase tracking={1}>
            Add a service
          </Emphasis>
        </button>
      </div>
    </Screen>
  )
}

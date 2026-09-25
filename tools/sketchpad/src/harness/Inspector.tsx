/*
 * Inspector — turns two of the doctrine's acceptance tests into tooling.
 *
 * 1. THE ONE-PRIMARY AUDIT. SURFACE_DOCTRINE requires exactly one primary
 *    element per section. That is normally checked by eye in review, which is
 *    why the app drifted to thirty data points at one weight. Here it is a DOM
 *    query: every `[data-section]` is checked for exactly one primary among its
 *    own descendants (nested sections are attributed to themselves). Zero
 *    primaries means no reading order; two or more means the rank is a lie.
 *
 * 2. THE SQUINT TEST. Blur the frame. If you can no longer tell what the screen
 *    is about, the hierarchy is carried by content rather than by form — which
 *    is exactly the failure a monospace wall produces. Blur is a stand-in for
 *    the real context: outdoors, one-handed, at arm's length.
 */
import { createEffect, createSignal, For, onCleanup, Show } from 'solid-js'

export interface AuditRow {
  section: string
  primaries: number
}

/** Counts primaries per section, attributing each to its nearest section. */
export function auditHierarchy(root: HTMLElement): AuditRow[] {
  const sections = [...root.querySelectorAll<HTMLElement>('[data-section]')]
  const marks = [...root.querySelectorAll<HTMLElement>('[data-rank="primary"], [data-slot="primary"]')]

  return sections
    .map((section) => {
      const owned = marks.filter((mark) => mark.closest('[data-section]') === section)
      return { section: section.dataset.section ?? '(unnamed)', primaries: owned.length }
    })
    .filter((row) => row.primaries !== 1)
}

export function useAudit(getRoot: () => HTMLElement | undefined, enabled: () => boolean) {
  const [rows, setRows] = createSignal<AuditRow[]>([])

  createEffect(() => {
    if (!enabled()) {
      setRows([])
      return
    }
    const run = () => {
      const root = getRoot()
      if (root) setRows(auditHierarchy(root))
    }
    run()
    // Re-runs so the audit tracks whatever the screen is currently showing,
    // including state the user just changed.
    const id = setInterval(run, 400)
    onCleanup(() => clearInterval(id))
  })

  return rows
}

/**
 * 3. THE TYPE HISTOGRAM, live. CLAUDE.md's "measure the type distribution"
 *    console snippet, promoted to a panel so it is read on every screen rather
 *    than remembered on some. Buckets are size/weight(/CAPS) over visible text
 *    nodes in the frame; the headline number is the share at the most common
 *    size — a wall shows up as one bucket holding most of the screen.
 */
export interface TypeBucket {
  key: string
  count: number
}

export function typeHistogram(root: HTMLElement): { buckets: TypeBucket[]; total: number } {
  const b = new Map<string, number>()
  let total = 0
  const walk = (el: Element) => {
    for (const c of el.children) {
      const own = [...c.childNodes].some((n) => n.nodeType === 3 && n.textContent?.trim())
      if (own && (c as HTMLElement).offsetParent !== null) {
        const s = getComputedStyle(c)
        const key = `${Math.round(parseFloat(s.fontSize))}/${s.fontWeight}${s.textTransform === 'uppercase' ? ' CAPS' : ''}`
        b.set(key, (b.get(key) ?? 0) + 1)
        total++
      }
      walk(c)
    }
  }
  walk(root)
  return {
    buckets: [...b.entries()].map(([key, count]) => ({ key, count })).sort((x, y) => y.count - x.count),
    total,
  }
}

export function useTypeHistogram(getRoot: () => HTMLElement | undefined) {
  const [hist, setHist] = createSignal<{ buckets: TypeBucket[]; total: number }>({ buckets: [], total: 0 })
  const id = setInterval(() => {
    const root = getRoot()?.querySelector<HTMLElement>('.hz-app')
    if (root) setHist(typeHistogram(root))
  }, 600)
  onCleanup(() => clearInterval(id))
  return hist
}

export function HistogramPanel(props: { hist: { buckets: TypeBucket[]; total: number } }) {
  return (
    <ul class="hz-audit">
      <For each={props.hist.buckets.slice(0, 7)}>
        {(b) => (
          <li>
            <span class="hz-audit-name">{b.key}</span>
            <span>
              {b.count} · {Math.round((b.count / Math.max(1, props.hist.total)) * 100)}%
            </span>
          </li>
        )}
      </For>
    </ul>
  )
}

export function AuditPanel(props: { rows: AuditRow[] }) {
  return (
    <Show
      when={props.rows.length}
      fallback={
        <p class="hz-ok">Every section on this screen has exactly one primary element.</p>
      }
    >
      <ul class="hz-audit">
        <For each={props.rows}>
          {(row) => (
            <li>
              <span class={row.primaries === 0 ? 'hz-bad' : 'hz-warn'}>
                {row.primaries === 0 ? 'no primary' : `${row.primaries} primaries`}
              </span>
              <span class="hz-audit-name">{row.section}</span>
            </li>
          )}
        </For>
      </ul>
    </Show>
  )
}

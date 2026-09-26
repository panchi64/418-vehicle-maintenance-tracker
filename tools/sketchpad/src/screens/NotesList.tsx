/*
 * Notes — Readout, pushed from the Notes row in Home's specs panel (F13).
 *
 * PROBLEM. A vehicle had one free-text notes field, previewed as 50 characters
 * in the specs panel. People keep several unrelated things about a car — a tire
 * quote photographed at the counter, a rattle to mention to the dealer, parts
 * numbers — and one field made them one blob with no way to find or order them.
 *
 * RESOLVED LAYOUT:
 *
 *   ‹ Home                                   [+]
 *   NOTES                                        large title
 *   [⌕ Search notes]                             `.searchable`
 *   Pinned                                       group header, only if any pinned
 *     Costco tire quote — Michelin Cross…        title: 15 Medium, primary ← row primary
 *     $684 out the door incl. road hazard…       first body line: 13, secondary
 *     Jul 12 · 2 attachments                     meta: 13, tertiary
 *   Other Notes
 *     …newest modified first
 *
 * Each row's primary is the TITLE, on size (15 vs 13) and weight (500 vs 400).
 * Body line vs meta line differ on colour only; acceptable because they are
 * not adjacent RANKS — both are the row's support. The meta line is ordered so
 * the attachment count truncates before the date.
 *
 * Titles are ONE line at normal sizes, TWO at large type (`.clamp-1-2`). Two
 * lines always was tried: the long-title fixtures made 4-line rows beside
 * 3-line rows and the list stopped scanning as a column of titles. One line
 * always failed at 2x, where it kept ~12 characters ("Costco tire qu…").
 *
 * GROUP HEADERS exist only when something is pinned. With nothing pinned an
 * "Other Notes" header over the whole list labels nothing. These are list
 * groups, not Home-style fixed sections, so omitting one is not a Readout
 * rule 2 violation (same call as Services' status groups).
 *
 * Empty: one quiet line. No headers, no card (Readout rule 3). Search with no
 * match: one quiet line naming the query.
 *
 * ROW ACTIONS (swipe + context menu, F14): Pin/Unpin · Delete (full swipe =
 * Delete, with undo).
 */
import { createSignal, Show } from 'solid-js'
import { PushedNavBar } from '../components/TabBar'
import { RowList, RowShell } from '../components/Rows'
import { ReadoutSection } from '../ui/ReadoutSection'
import { InsufficientDataNote } from '../ui/FormAdvisory'
import { Emphasis, Secondary } from '../ui/Text'
import { Screen } from './Screen'
import { useScenario } from '../data/scenario'
import { noteMeta, sortedNotes, type VehicleNote } from '../data/visits'

export function NotesList(props: {
  onBack: () => void
  onAdd: () => void
  onOpen: (n: VehicleNote) => void
  revealActions: boolean
}) {
  const data = useScenario()
  const [query, setQuery] = createSignal('')

  const matches = (n: VehicleNote) => {
    const q = query().trim().toLowerCase()
    return !q || n.title.toLowerCase().includes(q) || n.body.toLowerCase().includes(q)
  }
  const groups = () => sortedNotes(data().notes.filter(matches))
  const any = () => groups().pinned.length + groups().rest.length > 0

  const list = (notes: VehicleNote[]) => (
    <RowList each={notes}>
      {(n) => <NoteRow note={n} onClick={() => props.onOpen(n)} revealActions={props.revealActions} />}
    </RowList>
  )

  return (
    <>
      <PushedNavBar
        title="Notes"
        back="Home"
        onBack={props.onBack}
        onAdd={props.onAdd}
        search={data().notes.length ? { placeholder: 'Search notes', value: query(), onInput: setQuery } : undefined}
      />
      <Screen>
        <Show
          when={any()}
          fallback={
            <InsufficientDataNote
              message={query().trim() ? `No notes match “${query().trim()}”.` : 'No notes yet. Add one with +.'}
            />
          }
        >
          <Show when={groups().pinned.length} fallback={list(groups().rest)}>
            <ReadoutSection title="Pinned" primary={list(groups().pinned)} />
            <Show when={groups().rest.length}>
              <ReadoutSection title="Other Notes" primary={list(groups().rest)} />
            </Show>
          </Show>
        </Show>
      </Screen>
    </>
  )
}

function NoteRow(props: { note: VehicleNote; onClick: () => void; revealActions: boolean }) {
  const n = () => props.note
  const firstLine = () => n().body.split('\n')[0]
  const oneLine = { 'white-space': 'nowrap', overflow: 'hidden', 'text-overflow': 'ellipsis', width: '100%', 'text-align': 'left' } as const

  return (
    <RowShell
      section={`Note: ${n().title}`}
      onClick={props.onClick}
      actions={[n().pinned ? 'Unpin' : 'Pin', 'Delete']}
      revealActions={props.revealActions}
    >
      <div style={{ flex: '1 1 auto', 'min-width': '0', display: 'flex', 'flex-direction': 'column', gap: '2px' }}>
        {/* A span: `as="div"` sets an inline display that beats the class. */}
        <Emphasis rank="primary" class="clamp-1-2" style={{ width: '100%', 'text-align': 'left' }}>
          {n().title}
        </Emphasis>
        <Show when={firstLine()}>
          <Secondary as="div" style={oneLine}>
            {firstLine()}
          </Secondary>
        </Show>
        <Secondary color="tertiary" as="div" style={oneLine}>
          {noteMeta(n())}
        </Secondary>
      </div>
      <Secondary color="tertiary" style={{ flex: '0 0 auto' }}>
        ›
      </Secondary>
    </RowShell>
  )
}

/*
 * Note sheet — Decision surface (a task, so it presents; F13).
 *
 * PROBLEM. The most common reason to write a note about a car is standing at a
 * shop counter with a quote in hand. The old notes field was text only, buried
 * behind Edit Vehicle, so the quote got photographed into the camera roll and
 * lost. The sheet has to make "title + photo, pinned" the short path.
 *
 * RESOLVED LAYOUT (default path, nothing collapsed):
 *
 *   Cancel        New Note · Daily Driver         [Save]
 *   Note ───────────────────────────────────
 *     [Title                             ]   single rule, autofocused on new
 *     [Body, multi-line, grows           ]   single rule
 *     Pin                            [==]   detail: "Listed first, and shown
 *                                            under Specs on Home"
 *   Attachments ────────────────────  2
 *     Add Photo or File                      accent 15, the only door
 *     [thumb][thumb][thumb]                  72pt squares, wrap
 *   ...
 *   Delete Note                              edit only, last, destructive
 *
 * ATTACHMENTS ARE ON THE DEFAULT PATH, not in depth. Decision rule 5 hides
 * what makes a thing complete — but for a note photographed from a quote, the
 * photo IS the note; hiding it behind "More details" would make the core use
 * two taps longer and invisible. There is no depth section at all: every field
 * here either makes the note or is the one toggle that places it.
 *
 * NOTHING IS REQUIRED ON ITS OWN. A title-less photo note is valid; so is a
 * body-only note. Save blocks (F2) only when all three are empty, and the
 * blocker sits on the Title field. The saved title falls back to the body's
 * first line, or "Photo — Jul 25". (Considered, not rendered: a required
 * title — at the counter it forces typing before the photo, and the photo
 * is why the sheet was opened.)
 *
 * PIN IS A TOGGLE, not a toolbar pin glyph (considered, not rendered): the
 * trailing slot is Save's (F1), and a pin state read only from an icon's fill
 * says nothing about what pinning does. The toggle's detail line says it.
 *
 * Attachments' count sits in the section header's trailing slot; Delete Note
 * is last, edit only. Title and Body wrap and grow (`Field multiline`) — the
 * 70-character fixture title scrolled out of a single-line field.
 *
 * TAP BUDGET — add a pinned note with a photo, from Home: budget 6,
 * measured 6 in-frame.
 *   specs strip → Notes row → [+] → (title autofocused: type) → Pin →
 *   Add Photo or File → Save   (+ in the system picker: source, shutter, Use)
 * Every tap is load-bearing; the only one to cut would be the specs strip,
 * i.e. a Notes door on Home itself, which Home's fixed order has no room for.
 */
import { createSignal, For, Show } from 'solid-js'
import { Field, Toggle } from '../ui/Controls'
import { FormSection } from '../ui/FormSection'
import { FormAdvisory } from '../ui/FormAdvisory'
import { FormToolbar, revealBlocker } from '../ui/FormToolbar'
import { Body, Secondary } from '../ui/Text'
import { useScenario } from '../data/scenario'
import type { Attachment, VehicleNote } from '../data/visits'

export function NoteSheet(props: { note?: VehicleNote; onClose: () => void }) {
  const data = useScenario()
  const editing = !!props.note
  const [title, setTitle] = createSignal(props.note?.title ?? '')
  const [body, setBody] = createSignal(props.note?.body ?? '')
  const [pinned, setPinned] = createSignal(props.note?.pinned ?? false)
  const [attachments, setAttachments] = createSignal<Attachment[]>(props.note?.attachments ?? [])
  const [showBlocker, setShowBlocker] = createSignal(false)
  let scrollRef: HTMLDivElement | undefined

  const empty = () => !title().trim() && !body().trim() && attachments().length === 0
  const dirty = () =>
    !editing ||
    title() !== props.note!.title ||
    body() !== props.note!.body ||
    pinned() !== props.note!.pinned ||
    attachments().length !== props.note!.attachments.length
  const canSave = () => !empty() && dirty()

  // Stand-in for the system picker returning one photo.
  const addPhoto = () =>
    setAttachments([...attachments(), { id: `new${attachments().length}`, kind: 'photo', name: `Photo ${attachments().length + 1}` }])

  const vehicleName = () => {
    const v = data().vehicle!
    return v.name || `${v.year} ${v.make} ${v.model}`
  }

  return (
    <div style={{ display: 'flex', 'flex-direction': 'column', flex: '1 1 auto', 'min-height': '0' }}>
      <FormToolbar
        title={editing ? 'Edit Note' : 'New Note'}
        subtitle={vehicleName()}
        canSave={canSave()}
        onCancel={props.onClose}
        onSave={props.onClose}
        onBlocked={() => {
          if (!empty()) return
          setShowBlocker(true)
          revealBlocker(scrollRef, 'note')
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
        <FormSection title="Note">
          <Show when={showBlocker() && empty()}>
            <div data-blocker="note">
              <FormAdvisory severity="blocking" message="Write something or add a photo." />
            </div>
          </Show>
          <Field label="Title" value={title()} onInput={setTitle} placeholder="Tire quote" autofocus={!editing} multiline />
          <Field
            label="Body"
            value={body()}
            onInput={setBody}
            placeholder="What was quoted, who you talked to…"
            multiline={4}
          />
          <Toggle
            label="Pin"
            detail="Listed first, and shown under Specs on Home"
            checked={pinned()}
            onChange={setPinned}
          />
        </FormSection>

        <FormSection title="Attachments" trailing={attachments().length ? String(attachments().length) : undefined}>
          <button
            onClick={addPhoto}
            data-action="add-attachment"
            style={{
              display: 'flex',
              'align-items': 'center',
              'min-height': 'var(--touch-target)',
              'border-bottom': '1px solid var(--grid-line)',
            }}
          >
            <Body color="accent">Add Photo or File</Body>
          </button>
          <Show when={attachments().length}>
            <div style={{ display: 'flex', 'flex-wrap': 'wrap', gap: 'var(--space-sm)' }}>
              <For each={attachments()}>{(a) => <Thumb attachment={a} />}</For>
            </div>
          </Show>
        </FormSection>

        <Show when={editing}>
          <button style={{ 'min-height': 'var(--touch-target)', 'align-self': 'center' }}>
            <Body color="overdue">Delete Note</Body>
          </button>
        </Show>
      </div>
    </div>
  )
}

/** 72pt square, fixed (an image does not scale with Dynamic Type): a photo
    stand-in, or the file's type for a PDF. */
function Thumb(props: { attachment: Attachment }) {
  return (
    <div
      aria-label={props.attachment.name}
      style={{
        width: '72px',
        height: '72px',
        display: 'flex',
        'align-items': 'flex-end',
        padding: 'var(--space-xs)',
        border: '1px solid var(--grid-line)',
        background:
          props.attachment.kind === 'photo'
            ? 'linear-gradient(135deg, var(--background-subtle), var(--grid-line))'
            : 'var(--background-elevated)',
      }}
    >
      <Show when={props.attachment.kind === 'pdf'} fallback={<span />}>
        <Secondary color="tertiary">PDF</Secondary>
      </Show>
    </div>
  )
}

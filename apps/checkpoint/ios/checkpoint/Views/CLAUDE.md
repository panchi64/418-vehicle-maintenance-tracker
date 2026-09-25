# Views — UI Layer

All SwiftUI views, organized by feature area.

**Before designing or changing any screen, read [`docs/SURFACE_DOCTRINE.md`](../../../../../docs/SURFACE_DOCTRINE.md).** It defines the three surface classes (Readout / Switchboard / Decision), the hierarchy and disclosure rules, the advisory severity ladder, the required/optional vocabulary, and the `F*` invariants that this directory's components cite in their comments. Available tokens and modifiers are catalogued in [`DesignSystem/CLAUDE.md`](../DesignSystem/CLAUDE.md).

**Non-trivial layout changes start in [`tools/sketchpad/`](../../../../../tools/sketchpad/CLAUDE.md), not here.** It mirrors these views in SolidJS against the real themes and fonts, so an arrangement can be tried in a second instead of a 40-second rebuild — and it audits the one-primary rule mechanically. Port the settled design into this directory, then verify on the Simulator. The sketchpad's resolved screens — the unified service form, the collapsed Services and Costs chrome, the single-scroll Add Vehicle — **now all ship here**. Its custom tab bar and banded vehicle header do not: the shell is now the system's (see Navigation patterns), and only the header's odometer/specs band survives, as Home content. Where the two disagree on content, that is drift: fix whichever is wrong rather than assuming the sketchpad leads.

Every `#Preview` in this directory hot-reloads in roughly a second in Xcode. Reach for that before a full rebuild — a full `xcodebuild` cycle is only needed to verify an integrated screen end to end.

## Directory structure

```
Views/
├── Tabs/                # Home, Services, Costs
├── Vehicle/             # Vehicle CRUD
├── Service/             # Service CRUD + completion sheets
├── Settings/            # Settings, CSV import
├── Onboarding/          # Guided intro, tour overlay
└── Components/
    ├── Attachments/     # Photo/document handling
    ├── Camera/          # Vision OCR views
    ├── Cards/           # Dashboard cards
    ├── Inputs/          # Form controls
    ├── Lists/           # List/timeline components
    └── Navigation/      # Navigation & structural chrome
```

For component inventories, see [`docs/ARCHITECTURE.md`](../../../../../docs/ARCHITECTURE.md).

## Navigation patterns

**System shell, brand content.** Tab bar, navigation bars, toolbar, search and sheets are native (Liquid Glass) — never add `.toolbarBackground(...)` or `.presentationBackground(...)`; put the theme background behind *content* (`AtmosphericBackground`, `.background(Theme.backgroundPrimary)`). Brand lives in the content: fonts, themes, sharp corners, readouts.

- **Details push, tasks present.** Anything read and backed out of is an `AppRoute` pushed with `appState.push(_:)` onto the visible tab's stack (`AppState.paths`). Anything filled in and saved/cancelled is a sheet. Pushed screens get a navigation title and put Edit in the toolbar — no close buttons.
- **Root sheets go through the router.** Present with `appState.present(.someCase)` (`ActiveSheet`), never a new root `.sheet(isPresented:)`. It queues a sheet requested while another is up until that one has dismissed, so chaining sheets needs no delays or `onDismiss` flags. A sheet *inside* a sheet (Settings → paywall, a form's attachment viewer) stays local to that sheet.
- **Tab roots share `TabRootStack`**: vehicle name as the title with a `.toolbarTitleMenu` switcher, Settings leading, add service as the single prominent trailing action. Don't add per-tab headers above content.
- **Switch vehicles with `appState.selectVehicle(_:)`**, which pops every stack (their details belong to the old vehicle).
- **Toasts show above sheets** (`ToastWindow`), so an Undo toast from inside a sheet is visible.
- **Tour spotlights target content**, via `.tourTarget(_:)`. System chrome (title menu, toolbar items, search field, tab bar) exposes no frame to spotlight.

## State patterns

- `@Environment(AppState.self)` for global navigation state
- `@Query` for declarative SwiftData fetching — scope it to the vehicle in `init` with a `#Predicate` rather than filtering in a computed property
- `@Environment(\.modelContext)` for mutations

### Derive a screen's data once per body, not per mention

**A computed property re-runs every time the body mentions it.** `if !rows.isEmpty`,
a count in the section title, the `ForEach`, and a `count - 1` divider test are
four full re-derivations of the same list — and anything reading a SwiftData
relationship (`log.vehicle`, `log.visit`, `vehicle.services`) faults it again on
each pass. This was the cause of the pause when switching tabs.

Each tab resolves its data in **one** value up front and passes it down:
`HomeTab.Content`, `ServicesTabContent`, `CostsMetrics`. Follow that shape for
any new screen with derived collections:

- Compute it once at the top of `body` (`let content = makeContent()`), hand it to
  sections as a parameter.
- **Store** anything that iterates; leave computed only arithmetic and formatting
  over already-stored values.
- Don't re-filter what the `@Query` predicate already scoped — that's a
  relationship fault per row for an answer the store gave you.
- Mileage: take `vehicle.mileageEstimate` once and pass
  `.effective` / `.isEstimated` / `.pace` down. `vehicle.effectiveMileage` and
  friends each recompute the driving pace across every snapshot, so reading them
  per row is the same walk repeated.
- Sorting by urgency or status: score once and sort on that
  (`[Service].sortedByUrgency(_:)`), never inside the comparator.

## Form conventions

These are enforced invariants, not style suggestions. Each is defined in `SURFACE_DOCTRINE.md` Part 3.

- **Save lives in the sheet's toolbar, via `.formToolbar(...)`** (F1): Cancel is the `.cancellationAction`, a prominent Save the `.confirmationAction`, and the title carries `.navigationSubtitle` = the vehicle. No bottom action bar — it cost ~96pt of every form and had to hide behind the keyboard. Destructive actions (Delete Entry) go last in the scroll, never beside Save.
- **Never `.disabled()` Save** (F2). `formToolbar` draws it dim and keeps it tappable: the tap fires the error haptic and calls `onBlocked`, where the form scrolls to the blocking field and shows a `.blocking` `FormAdvisory` *at that field*. VoiceOver hears "unavailable" plus where it goes.
- **Every form is dismiss-protected.** Pass `isDirty`: a dirty form can't be swiped away, and Cancel asks "Discard changes?" first (`onDiscard` clears a stored draft). Service forms also keep F10 drafts per door (`ServiceFormDraftStore.Scope`).
- **One service form.** Logging, Mark Done, editing a history entry, and scheduling are all `ServiceLogForm` (`ServiceLogFormMode`: `.log` / `.complete` / `.edit`; "Not done yet" schedules). Don't add a parallel sheet — add a door or a prefill. `AddServiceView`, `MarkServiceVisitDoneSheet`, `MarkServiceDoneSheet`, `EditServiceLogView` are presenter shims onto it.
- **Use `Components/Inputs/` controls** — `InstrumentTextField`, `InstrumentNumberField`, `InstrumentDatePicker`, `InstrumentSegmentedControl`, `LabeledInstrumentToggle`.
- **Any screen with a text input gets `.keyboardDismissToolbar()` on its container.** Single-line fields dismiss on Return on their own (`.submitLabel(.done)`, set inside the control), but a number pad has no return key and an editor's return key means newline — those need the toolbar's DONE, and the same modifier turns on drag-to-dismiss. Keyboard avoidance is otherwise the system's job; the one place it does not reach is a first responder inside a `UIViewRepresentable`, which `RichNotesEditor` handles itself.
- **Never label a field with its own section's title.** `InstrumentSectionHeader(title: "Notes")` wrapping a field labelled "Notes" renders the word twice and reads as a bug. Pass `label: nil` — every input control takes an optional label for exactly this case.
- **Advisories go through the severity ladder** (F12), not ad-hoc `Text(...)`. A blocking problem must not render like a countdown.
- **Required vs. optional uses one vocabulary** (F5) — not a mix of parameters, asterisks, section tags, and post-hoc validation rows.
- **Secondary fields go in `CollapsibleDetailsSection`** — but only completeness-oriented ones. Anything the feature needs in order to *function* belongs on the default path.
- **Projection previews share the save path's calculation** (F4). A preview that can disagree with what gets scheduled is worse than none.

## Localization

All user-facing strings go through `L10n` (EN + ES). **No display strings built by concatenation** — use format keys so grammar survives translation, and so enum `rawValue` never leaks to screen (expose `displayName` instead).

Accessors live in per-area `L10n+<Area>.swift` files beside the code that uses them; code that runs off the main actor (CSV parsing, PDF rendering, OCR, Siri, NHTSA) uses `nonisolated` accessors. `Text(verbatim:)` is for numbers and typographic framing only. Previews may use literals. Still English-only data: service preset names (`ServicePresets.json`), theme names/descriptions (`Themes.json`), and App Shortcut phrases.

## Previews

Every view includes a `#Preview` with an in-memory `ModelContainer`. Prefer previewing more than one theme when the view carries status color.

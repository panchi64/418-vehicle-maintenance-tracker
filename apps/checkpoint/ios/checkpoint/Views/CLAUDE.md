# Views — UI Layer

All SwiftUI views, organized by feature area.

**Before designing or changing any screen, read [`docs/SURFACE_DOCTRINE.md`](../../../../../docs/SURFACE_DOCTRINE.md).** It defines the three surface classes (Readout / Switchboard / Decision), the hierarchy and disclosure rules, the advisory severity ladder, the required/optional vocabulary, and the `F*` invariants that this directory's components cite in their comments. Available tokens and modifiers are catalogued in [`DesignSystem/CLAUDE.md`](../DesignSystem/CLAUDE.md).

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

- **Sheets** for create/edit operations (modal, cancelable)
- **Push navigation** for detail views (back navigation)
- Vehicle selector persists at the top of all tabs via `AppState`

## State patterns

- `@Environment(AppState.self)` for global navigation state
- `@Query` for declarative SwiftData fetching — scope it to the vehicle in `init` with a `#Predicate` rather than filtering in a computed property
- `@Environment(\.modelContext)` for mutations

## Form conventions

These are enforced invariants, not style suggestions. Each is defined in `SURFACE_DOCTRINE.md` Part 3.

- **`FormActionBar` in a bottom `safeAreaInset` is the only place Save lives** (F1). Do not put a Save button in the toolbar — Save must be in the same location on every surface. The bar also owns disabled-save feedback (F2) and hides itself behind the keyboard (F3); callers supply only a scroll-to-field closure.
- **Use `Components/Inputs/` controls** — `InstrumentTextField`, `InstrumentNumberField`, `InstrumentDatePicker`, `InstrumentSegmentedControl`, `LabeledInstrumentToggle`.
- **Advisories go through the severity ladder** (F12), not ad-hoc `Text(...)`. A blocking problem must not render like a countdown.
- **Required vs. optional uses one vocabulary** (F5) — not a mix of parameters, asterisks, section tags, and post-hoc validation rows.
- **Secondary fields go in `CollapsibleDetailsSection`** — but only completeness-oriented ones. Anything the feature needs in order to *function* belongs on the default path.
- **Projection previews share the save path's calculation** (F4). A preview that can disagree with what gets scheduled is worse than none.

## Localization

All user-facing strings go through `L10n` (EN + ES). **No display strings built by concatenation** — use format keys so grammar survives translation, and so enum `rawValue` never leaks to screen (expose `displayName` instead).

This is not yet true everywhere; a sweep is in progress. Don't add to the backlog.

## Previews

Every view includes a `#Preview` with an in-memory `ModelContainer`. Prefer previewing more than one theme when the view carries status color.

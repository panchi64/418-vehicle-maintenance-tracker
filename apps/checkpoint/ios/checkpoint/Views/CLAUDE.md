# Views - UI Layer

This directory contains all SwiftUI views organized by feature area.

## Directory Structure

```
Views/
├── Tabs/                # Main tab views (Home, Services, Costs)
├── Vehicle/             # Vehicle CRUD views
├── Service/             # Service CRUD views
├── Settings/            # Settings views (includes CSVImportView)
├── Onboarding/          # Guided intro, tour overlay, get started card
└── Components/          # Reusable UI components
    ├── Attachments/     # Photo/document handling
    ├── Camera/          # Vision framework OCR views
    ├── Cards/           # Dashboard cards
    ├── Inputs/          # Form input controls
    ├── Lists/           # List/timeline components
    └── Navigation/      # Navigation & structural
```

For component inventories, see `docs/ARCHITECTURE.md`.

## Navigation Patterns

- **Sheets** for create/edit operations (modal, cancelable)
- **Push navigation** for detail views (back navigation)
- Vehicle selector persists at top of all tabs via `AppState`

## State Patterns

- `@Environment(AppState.self)` for global navigation state
- `@Query` for declarative SwiftData fetching
- `@Environment(\.modelContext)` for mutations

## Form Conventions

- Use `InstrumentTextField` and other `Components/Inputs/` controls
- Group fields in `Section` with descriptive headers
- Save button uses `.buttonStyle(.primary)`
- All views include `#Preview` with in-memory ModelContainer

# App Intents & Siri AI — Checkpoint

How Checkpoint plugs into Siri, Shortcuts, Spotlight, Controls, and on-device models. Minimum deployment stays **iOS 26**; iOS 27 and Apple Intelligence features are layered on top.

Every availability below was checked against the Xcode 27.0 SDK (`iPhoneOS27.0.sdk`), not blog posts. Re-check the swiftinterface before trusting anything added later.

## Device tiers

Siri AI and Foundation Models need Apple Intelligence hardware (iPhone 15 Pro and later). A large share of users won't have it, so every feature must degrade to the tier below.

| Capability | Min iOS | iOS 26 | iOS 27, no AI | iOS 27 + AI |
|---|---|---|---|---|
| `AppIntent`, `AppEntity`, `AppShortcutsProvider`, `requestValue` / `requestDisambiguation` | 16 | ✅ | ✅ | ✅ |
| `requestConfirmation(conditions:actionName:dialog:)` | 18 | ✅ | ✅ | ✅ |
| `SnippetIntent` (interactive snippets), `requestConfirmation(…snippetIntent:)` | 26 | ✅ | ✅ | ✅ |
| `IntentDonationManager` | 16 | ✅ | ✅ | ✅ |
| `RelevantIntentManager` | 17 | ✅ | ✅ | ✅ |
| `IndexedEntity`, `CSSearchableIndex.indexAppEntities` | 18 | ✅ | ✅ | ✅ |
| `NSUserActivity.appEntityIdentifier` | 18.2 | ✅ | ✅ | ✅ (Siri acts on "this") |
| SwiftUI `.appEntityIdentifier(_:)` | 18.4 | ✅ | ✅ | ✅ (Siri acts on "this") |
| `ControlWidget` (Control Center, Lock Screen, Action button) | 18 | ✅ | ✅ | ✅ |
| `AppDependencyManager` / `@Dependency` | 16 | ✅ | ✅ | ✅ |
| Visual Intelligence: `IntentValueQuery` over `SemanticContentDescriptor` | 26 | AI hw | — | ✅ |
| Schema `.system.search` (deprecated in 27) | 18 | ✅ | ✅ | ✅ |
| Schemas `.system.searchInApp`, `.system.open`, `.reminders.*` | 27 | — | ✅ | ✅ |
| `RelevantEntities`, `IndexedEntityQuery`, `LongRunningIntent`, `allowedExecutionTargets` | 27 | — | ✅ | ✅ |
| `UNNotificationContent.appEntityIdentifiers` | 27 | — | ✅ | ✅ |
| `AppIntentsTesting` (test framework) | 27 | — | ✅ | ✅ |
| Foundation Models, text in (`SystemLanguageModel`, `@Generable`) | 26 | AI hw | — | ✅ |
| Foundation Models `Attachment` (image in), `OCRTool`, `BarcodeReaderTool` | 27 | — | — | ✅ |
| Vision `RecognizeDocumentsRequest` | 26 | ✅ | ✅ | ✅ |

Check at runtime with `SystemLanguageModel.default.availability`. It reports `.unavailable(.deviceNotEligible | .appleIntelligenceNotEnabled | .modelNotReady)`.

`@AssistantIntent` / `@AssistantEntity` are deprecated. Use `@AppIntent(schema:)` / `@AppEntity(schema:)`.

## Which schema domains Checkpoint adopts

Apple's rules come from [Making actions and content discoverable by Apple Intelligence](https://developer.apple.com/documentation/appintents/making-actions-and-content-discoverable-by-apple-intelligence).

- **Mix domains freely.** An app can adopt schemas from several domains. Apple's own example is a houseplant-journaling app that uses both Notes and Photos.
- **Only real matches.** Apply a schema only where the content genuinely matches what the domain is for.
- **All-or-nothing only for Mail, Clock and Messages.** Every other domain, Reminders included, lets you adopt just the schemas that fit.
- **Unused fields can be empty.** Set schema properties the app doesn't support to `nil`.
- **Extra fields are Shortcuts-only.** Additional optional properties are visible in Shortcuts but ignored by Apple Intelligence.

| Domain | Siri AI? | Checkpoint mapping | Verdict |
|---|---|---|---|
| Reminders | ✅ | service = reminder, vehicle = list | **Adopt** |
| Photos | ✅ | image documents and receipts = assets, vehicle = album; `openAsset`, `createAssets` ("save this photo to Checkpoint"), `deleteAssets` stays in-app | **Adopt** for image documents |
| System (`searchInApp`, `open`) | ✅ | every entity | **Adopt** |
| Visual intelligence | ✅ (camera) | receipt / odometer / VIN recognition | **Adopt** |
| Files | Shortcuts only | documents library, including PDFs; `openFile`, `file` | **Adopt** (cheap) |
| Notes | ✅ | new `VehicleNote` = note, vehicle = folder; `createNote`, `updateNote` | **Adopt** once vehicle notes ship |
| Calendar | ✅ | new `Appointment` (a scheduled shop visit) = event, vehicle = calendar; `createEvent`, `updateEvent`, `deleteEvent`. Service due dates stay reminders, not events. | **Adopt** once appointments ship |
| Maps, Camera, Clock, Mail, Messages, Phone, Audio, Assistant | ✅ | none; Checkpoint isn't a navigation, camera, clock or messaging app | No |
| Books, Browser, Journaling, Presentation, Reader, Spreadsheet, Whiteboard, Word processor | Shortcuts only | none | No |

## Reminders schema (iOS 27)

The shapes below come from Xcode 27's snippet library (`AppShortcutsEditor.framework/.../IDEAppShortcutsEditor.codesnippets`); property names are the contract. **Only the schemas that fit are adopted.** Sections, groups and `createSection` are skipped, because Reminders isn't an all-or-nothing domain.

- **`.reminders.reminder` entity**
  - Required: `title`, `note: AttributedString?`, `tags: Set<String>`, `urls: [URL]`, `dueDate: DateComponents?`, `recurrence: Calendar.RecurrenceRule?`, `isCompleted`, `isFlagged: Bool?`, `creationDate?`, `completionDate?`, `list: ListEntity`, `locationTrigger: LocationTriggerEntity?`.
- **`.reminders.list` entity**: `name`, `type: ListType`.
- **Other entities**
  - `.reminders.section`: `name`, `list`
  - `.reminders.group`: `name`, `lists`
  - `.reminders.locationTrigger`: `place: PlaceDescriptor`, `event`
- **Enums**
  - `.reminders.listType`: `standard`
  - `.reminders.locationTriggerEvent`: `arrive`, `depart`
- **Intents**
  - `createReminder`: `title`, `list?`, `note?`, `isFlagged?`, `images: [IntentFile]`, `tags`, `urls`, `dueDate?`, `recurrence?`, `locationTrigger?`, `section?` → returns the reminder
  - `updateReminder`: `target` plus optional versions of every field, including `isCompleted` → returns the reminder
  - `deleteReminders`: `entities: [Reminder]`, conforms to `DeleteIntent`
  - `createList`: `type`, `name` → returns the list
  - `createSection`: `name`, `list` → returns the section

**How Checkpoint's fields map onto the schema**
- Due date goes in `dueDate`.
- A month interval becomes `recurrence` (`Calendar.RecurrenceRule.monthly(interval:)`).
- Mileage-based due and interval values have no schema field. They go in `note` and on the non-schema `ServiceEntity`.
- `isCompleted = true` runs `ServiceCompletionService`, which logs the service and schedules the next occurrence.
- Checkpoint has no sections, groups or location triggers. The `locationTrigger` property is `nil`. If the macro still insists on a `LocationTriggerEntity` type existing, add one whose query returns nothing — check this at build time.

**iOS 26 coexistence**
- The schema types are **separate `@available(iOS 27, *)` types**, e.g. `ServiceReminderEntity` and `VehicleListEntity`.
- They wrap the same store adapter as the iOS 26 `ServiceEntity` / `VehicleEntity`. A schema macro can't be added conditionally to a type that already exists on iOS 26.

## Other signatures confirmed in the SDK

- **`.system.searchInApp`** (27): `ShowInAppSearchResultsIntent` with `static var searchScopes: [StringSearchScope]` and `var criteria: StringSearchCriteria`. On iOS 26, use `.system.search`.
- **`.system.open`** (27): `OpenIntent` with `var target: some AppEntity`.
- **`.visualIntelligence.semanticContentSearch`** (26): Xcode's snippet names `VisualIntelligence.SceneDescriptor`, **but that type does not exist in the SDK.** Use `SemanticContentDescriptor` (`labels: [String]`, `pixelBuffer: CVReadOnlyPixelBuffer?`). It conforms to `IntentValueConvertible` only on iOS 27.
- **`Attachment`** (27):
  - Initializers: `init(_: CGImage)`, `init(_: CIImage)`, `init(_: CVPixelBuffer)`, `init(imageURL:)`, each taking an optional `orientation:`.
  - **No `UIImage` initializer** — convert with `.cgImage`.
  - `.label(_:)`.
  - Conforms to `PromptRepresentable`.
- **`OCRTool` / `BarcodeReaderTool`** (27, in `_Vision_FoundationModels`): `init(name:description:)`, conforming to `Tool`.
- **Token budget:** `SystemLanguageModel.contextSize` and `tokenCount(for:)` take prompts, instructions, tools or schemas. Read the size at runtime; don't hard-code it.
- **`AppDependencyManager.shared.add(dependency:)`**: the dependency must be `Sendable`. `@Dependency` resolves from the manager only inside the system's perform flow; outside it (unit tests) the value must be set on the intent first, or access traps. `AppDependency.wrappedValue` has a setter for this.
- **App Shortcuts:** up to 10 per app (Human Interface Guidelines, "App Shortcuts"). Every phrase must contain `\(.applicationName)`. Localized phrases go in `AppShortcuts.xcstrings`; Xcode 27's metadata processor reads that file name and emits `<lang>.lproj/AppShortcuts.strings` plus an NLU model per language.
- **`requestConfirmation`:** `(conditions:actionName:dialog:)` is iOS 18; the `snippetIntent:` overload is iOS 26. `ConfirmationActionName` has no `.delete`; use the default (`.continue`) with a dialog that names the delete. Outside a Siri/Shortcuts session it throws at once, so the write behind it never runs.
- **`RelevantIntent`** (iOS 17) only takes a `WidgetConfigurationIntent` plus a widget kind — it ranks widgets in the Smart Stack, not Siri suggestions. Siri learns from `IntentDonationManager` donations.

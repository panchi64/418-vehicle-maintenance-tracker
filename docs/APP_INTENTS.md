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
| Schemas `.files.*`, `.photos.album` / `.albumType` / `.assetType` / `.filterType` | 18 | ✅ | ✅ | ✅ |
| Schemas `.system.searchInApp`, `.system.open`, `.reminders.*`, `.photos.asset` | 27 | — | ✅ | ✅ |
| `.photos.openAsset`, `.photos.search` (deprecated in 27: use `.system.open` / `.system.searchInApp`) | 18 | ✅ | ✅ | ✅ |
| `RelevantEntities`, `IndexedEntityQuery`, `LongRunningIntent`, `allowedExecutionTargets` | 27 | — | ✅ | ✅ |
| `UNNotificationContent.appEntityIdentifiers` | 27 | — | ✅ | ✅ |
| `AppIntentsTesting` (test framework) | 27 | — | ✅ | ✅ |
| Foundation Models, text in (`SystemLanguageModel`, `@Generable`) | 26 | AI hw | — | ✅ |
| Foundation Models `Attachment` (image in), `OCRTool`, `BarcodeReaderTool` | 27 | — | — | ✅ |
| Foundation Models `tokenCount(for:)` | 26.4 | AI hw | — | ✅ |
| Vision `RecognizeDocumentsRequest`, `DetectLensSmudgeRequest` | 26 | ✅ | ✅ | ✅ |

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
| Notes | ✅ | `VehicleNote` = note, vehicle = folder; `createNote`, `updateNote` (no note deletes by voice) | **Adopted** (Phase 6) |
| Calendar | ✅ | `Appointment` (a booked shop visit) = event, vehicle = calendar; `createEvent`, `updateEvent`, `deleteEvent` (cancels, after asking). Service due dates stay reminders, not events. | **Adopted** (Phase 6) |
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
- Checkpoint has no sections, groups or location triggers. The `locationTrigger` property is always `nil`.

**What the metadata processor required (Xcode 27 build, checked 2026-09-25).** Swift compiles a schema type that leaves fields out; `appintentsmetadataprocessor` then halts the export:
- `Missing required property 'locationTrigger' from AppSchemaEntity 'reminders.reminder'` — so a `.reminders.locationTrigger` entity (and its `.reminders.locationTriggerEvent` enum) has to exist.
- `Missing required parameter 'section' from AppSchemaIntent 'reminders.createReminder'` — so a `.reminders.section` entity has to exist, even though `createSection` isn't adopted.
- `AppSchemaIntent … requires 'NoLocationTriggerEntity' to conform to 'IndexedEntity', 'UniqueAppEntity', 'TransientAppEntity', provide a default 'EntityStringQuery', or provide an 'IntentValueQuery'` — every entity a schema intent takes needs a string query.
- `.photos.asset` needs the *long* snippet: `aperture`, `exposure`, `saturation`, `warmth`, `filter` (a `.photos.filterType` enum) and `isPortraitModeEnabled`, all declared and `nil`.
- The `images: [IntentFile]` parameter expands to `@Parameter(supportedContentTypes: [.image])`, so the file needs `import UniformTypeIdentifiers`.
- Assigning a macro-wrapped property in `init` needs `self` complete, so plain `let` properties are set first.

Checkpoint's placeholders are `NoLocationTriggerEntity` and `NoSectionEntity`, whose queries return nothing.

**iOS 26 coexistence**
- The schema types are **separate `@available(iOS 27, *)` types**, e.g. `ServiceReminderEntity` and `VehicleListEntity`.
- They wrap the same store adapter as the iOS 26 `ServiceEntity` / `VehicleEntity`. A schema macro can't be added conditionally to a type that already exists on iOS 26.
- Create, update and delete overlap Add / Edit / Mark Done / Delete Service, so they set `isAssistantOnly = true` and Shortcuts lists each action once. `createList` (add a vehicle) has no twin and is visible.

## What Checkpoint ships (Phase 3)

| Schema | Type | Maps to | Notes |
|---|---|---|---|
| `.reminders.reminder` / `.list` / `.listType` | `ServiceReminderEntity`, `VehicleListEntity`, `ReminderListType` | service, vehicle | Field mapping in `ReminderMapping` |
| `.reminders.createReminder` / `updateReminder` / `deleteReminders` / `createList` | `CreateServiceReminderIntent`, `UpdateServiceReminderIntent`, `DeleteServiceRemindersIntent`, `CreateVehicleListIntent` | `ServiceScheduling`, `Service.apply`, `ServiceLogging.markDone`, `DeleteServiceIntent.delete`, `VehicleService` | Completing and deleting ask first; Create List respects the free vehicle limit |
| `.photos.asset` / `.album` (+ enums) | `DocumentPhotoEntity`, `VehicleAlbumEntity` | image documents, vehicle | PDFs aren't photos |
| `.system.open` over photos | `OpenDocumentPhotoIntent` | document detail | Not `.photos.openAsset`, which 27 deprecates |
| `.photos.createAssets` | `SaveDocumentPhotosIntent` | new image documents, with OCR text | Extra `album` parameter (Shortcuts only) picks the vehicle. No `deleteAssets`: document deletes stay in-app |
| `.files.file` / `.openFile` | `DocumentFileEntity`, `OpenDocumentFileIntent` | every document | iOS 18 schema, so available on iOS 26. IDs are draft `FileEntityIdentifier`s carrying the UUID: documents live in SwiftData, not on disk |
| `.system.search` (26) / `.searchInApp` (27) | `SearchCheckpointIntent`, `SearchInCheckpointIntent` | Services tab or Documents search | The 27 one is `isAssistantOnly` |
| `.system.open` | `Open{Vehicle, ServiceDetail, ServiceLog, Visit, Document, ServiceReminder, VehicleList}Intent` | `PendingRoute` via `EntityRoutes` | One intent per target type |

**Notifications.** `SERVICE_DUE`, `MILEAGE_REMINDER`, `MARBETE_DUE` and `YEARLY_ROUNDUP` content is tagged with `appEntityIdentifiers` on iOS 27 (`NotificationEntityTags`): the services as `ServiceEntity` and `ServiceReminderEntity`, then the vehicle as `VehicleEntity`.

**`RelevantEntities` is not adopted.** Its only context in the SDK is `AppEntityContext.audio(.nowPlaying)`, and Apple documents it as "donate your app's songs, albums, artists, and other media items to play during workouts". Nothing in Checkpoint fits. Revisit if a later SDK adds a non-media context.

**Spotlight.** The schema types are not indexed. Each wraps a model an indexed iOS 26 entity already covers, so indexing both would list every service and document twice. Siri resolves them through their `EntityStringQuery`.

**`AppIntentsTesting`** runs intents out of process, in a live, team-signed app. Apple puts these tests in a **UI testing** target that launches the app. In the unit-test host, lookups fail with "Underlying session was cancelled (transportCancelled)". Command-line simulator builds are ad-hoc signed, so this also needs a signed build. The schema intents are unit-tested directly instead.

## What Checkpoint ships (Phase 4: receipts and documents)

On-device only (no Private Cloud Compute) and free. Code in `Services/Intelligence/` (its CLAUDE.md has the rules).

| Piece | What it does | Tiers |
|---|---|---|
| `ReceiptOCRService.scan` | `DetectLensSmudgeRequest` gate → `RecognizeDocumentsRequest` → `ReceiptScan` (lines, tables, detected amounts/dates) | all |
| `ReceiptTextParser` | Rule-based draft: shop, date, total (labelled, else largest at low confidence), tax (IVU lines summed), odometer, line items, services (EN/ES) | all — the whole reader without Apple Intelligence |
| `OnDeviceLanguageModel` | `@Generable GeneratedReceipt` over the transcript with `ServiceNameTool`; on 27 also `Attachment` + `OCRTool` (device only); context fitted with `tokenCount` | 26 + AI (image on 27) |
| `ReceiptDraftValidator` | Merge model with rules (agree → high), then items ≈ total, plausible date, odometer ≥ last reading; `Issue`s shown as cautions | all |
| `DocumentClassifier` | `DocumentType` from text (`.contentTagging` model), else keywords, else filename; used by the Documents picker and Save Photos | all |
| Service form | "Scan a receipt" first row; values land in their fields marked "From receipt"; shop and line items go on a visit on save | all |
| `LogReceiptIntent` (App Shortcut 10/10) | Image or PDF → draft → `ServiceRecordSnippetIntent` confirmation → `ServiceLogging` | all |
| Visual Intelligence | `CheckpointVisualSearchQuery` → `VisualCaptureEntity` (log receipt / update mileage / add vehicle by VIN) → `OpenVisualCaptureIntent`; `ShowVisualSearchResultsIntent` for "More results" | 26 + AI hardware, device only |

**Share Sheet.** There is no share extension; `LogReceiptIntent`'s file parameter is what makes it a Shortcuts action that accepts images and PDFs, which Shortcuts can show in the Share Sheet.

## What Checkpoint ships (Phase 5: remaining surfaces)

All iOS 26, every device tier. Code in `Services/Intents/Vehicles/`, `Documents/`, `History/` and `CheckpointWidget/`.

| Piece | What it does | Notes |
|---|---|---|
| `AddVehicleIntent` | Make/model/year or a VIN (decoded by `VehicleService.fillingFromVIN` over `NHTSAClient`), odometer asked, then one `requestChoice`: with the starter schedule (`StarterScheduleWriter`, the sheet's defaults) or without | Free limit checked first; dismissing the choice saves nothing. A failed lookup asks for the make |
| `SwitchVehicleIntent` | Opens the app on a vehicle's Home | `.foreground` intent, not `OpenIntent` (one per target type); iOS 27's `OpenVehicleIntent` is now `isAssistantOnly` |
| `GetVehicleDetailsIntent` | Plate, VIN, oil, tires, marbete (`VehicleDetail` enum), or everything on file | Returns the value as a `String` for shortcuts; says what's missing and where to add it |
| `RenewMarbeteIntent` | Same month next year (`Vehicle.renewedMarbeteExpiration`), confirmed, written by `MarbeteRenewal` | Home's Mark Renewed donates it |
| `CheckRecallsIntent` | NHTSA recalls filtered as Home shows them (`RecallVisibility`), `RecallsSnippetView`, then `requestChoice` to add unplanned ones as planned services | Planned = the recall sheet's one-off service (`RecallInfo.plannedServiceName`, due in 7 days) + status `.scheduled` |
| `AddDocumentIntent` | Image or PDF → `DocumentImport` (Vision, or the PDF's text layer, else its first page) → `DocumentClassifier`; asks the type only when nothing matched | No confirmation (additive); no document deletes by voice |
| `FindDocumentIntent` | Newest document by type and/or text, the showing vehicle first; `DocumentSnippetView` shows it; returns `DocumentEntity` | App Shortcut; `DocumentEntity` is `Transferable` (PDF or JPEG), so "share my registration" and Mail chains work |
| `ExportServiceHistoryIntent` | The Services tab's PDF as an `IntentFile` | Chains in Shortcuts |
| Controls | Update Mileage, Scan Receipt, Log Service (`ControlWidgetButton` + `OpenCheckpointScreenIntent`) | Route through `PendingWidgetRoute` (`.screen`) → `PendingRoute.updateMileage` / `.scanReceipt` / `.logService` on the showing vehicle |
| Siri tips | `ScreenSiriTip` (Apple's `SiriTipView`) last on Home (Check Next Due), the mileage sheet (Update Mileage), Costs (Spending), Documents (Find Document) | One per screen, dismissed for good; placement resolved in tools/sketchpad |

**App Shortcuts (still 10).** Find Document took List Upcoming Services' slot: Check Next Due's snippet already lists everything coming up (it took the "coming up" phrases), Find Document is the traffic-stop case, and the Documents tip needs an App Shortcut to show at all. Recalls and export stay Shortcuts/Siri AI actions.

**Donations added:** Add Vehicle (no parameters: a repeat is a different car), a document added to the library (vehicle + type), Mark Renewed.

## What Checkpoint ships (Phase 6: shop appointments and vehicle notes)

New models in `CheckpointSchemaV2` (`Appointment`, `VehicleNote`; see Models/CLAUDE.md for the migration). Code in `Services/Appointments/`, `Services/Notes/`, `Services/Intents/Appointments/`, `Notes/`, `Schema/Calendar/`, `Schema/Notes/`.

| Piece | What it does | Notes |
|---|---|---|
| `ScheduleAppointmentIntent` | Shop + date (asked when missing), optional services, address, note → `AppointmentService.schedule` | No confirmation (additive). Reminders the day before and an hour before |
| `RescheduleAppointmentIntent` | The named appointment, else the next one on the showing vehicle → new start, same length | No confirmation (the old time is one edit away) |
| `CancelAppointmentIntent` | Same resolution → `requestConfirmation` → status `cancelled` (kept, not deleted) | The one voice "delete" in this phase |
| `AddVehicleNoteIntent` | Text (asked), title, pinned, image/PDF files (read by `DocumentImport`, kept as Documents on the note) | No note deletes by voice |
| `FindNoteIntent` | Best match: title beats text, the showing vehicle first; reads the first line | Returns `VehicleNoteEntity` |
| `AppointmentEntity`, `VehicleNoteEntity` | `IndexedEntity`, Spotlight-indexed; `.onScreenEntity` on Home's appointment card and each Notes row | `.system.open` on 27 via `EntityRoutes` → `PendingRoute.appointment` / `.vehicleNote` |
| `.calendar.calendar` / `.event` (+ `eventStatus`, `eventSpan`, `attendee`, `attendeeStatus`, `attendeeType`, `EventLocation`/`EventAlarm` unions) | `VehicleCalendarEntity`, `AppointmentEventEntity`; `CalendarMapping` | Organizers and attendees always empty (`NoAttendeeEntity`, a query that finds nothing); alarms = the two reminder dates; location = `PlaceDescriptor` (coordinate + address, shop as common name) |
| `.calendar.createEvent` / `updateEvent` / `deleteEvent` | `CreateAppointmentEventIntent`, `UpdateAppointmentEventIntent`, `DeleteAppointmentEventIntent` — all `isAssistantOnly` | Title → shop (a place's common name wins); tracked service names in the title link those services. Delete cancels after asking. Moving to another vehicle's calendar is refused |
| `.notes.folder` / `.note` / `.account` | `VehicleFolderEntity`, `VehicleNoteSchemaEntity`, `NoNotesAccountEntity` (placeholder) | Snapshot `attachments` are empty: the files are Documents and export through `DocumentEntity` |
| `.notes.createNote` / `updateNote` | `CreateVehicleNoteIntent` (`isAssistantOnly`), `UpdateVehicleNoteIntent` | Update has no content field in the schema, so only title, pin and more files |
| Notifications | Appointment reminders tagged with `AppointmentEntity`, `AppointmentEventEntity` (27) and the vehicle | Tone: docs/NOTIFICATION_TONE.md |

**App Shortcuts: unchanged (still 10).** No slot was swapped. Booking and note-taking are rare next to logging, mileage and "what's due", and every new intent is still a Shortcuts action and, on iOS 27, reachable by Siri AI through the Calendar and Notes schemas without a phrase.

**What the SDK and metadata processor required (Xcode 27, checked 2026-09-26).**
- Calendar and Notes schemas are iOS 27 (`anyAppleOS 27.0`); GeoToolbox `PlaceDescriptor` and `MKMapItemRequest(placeDescriptor:)` are iOS 26.
- `.calendar.deleteEvent` takes one `entity`, so it can't conform to `DeleteIntent` (which takes `entities`).
- `.calendar.attendeeType` accepts a `person` case; the snippet library leaves its cases as a placeholder.
- `IntentPerson` has no `displayName`; the placeholder attendee shows a fixed label.

## Other signatures confirmed in the SDK

- **`requestChoice(between:dialog:)`** (iOS 26) returns the chosen `IntentChoiceOption`; choosing `.cancel` (or a `.cancel`-styled option) throws. Use it for a question whose "no" should let the intent finish — `requestConfirmation` throws on "no".
- **Controls opening the app** (WidgetKit, "Creating controls to perform actions across the system"): the action is an `OpenIntent`, and the intent must be a member of both the app and the widget extension. `ControlWidgetButton` is iOS 18. Any control can go on the Action button.
- **`OpenIntent` targets must be unique.** `appintentsmetadataprocessor` halts with "OpenIntent targets should be unique" when two open the same entity type.
- **`SiriTipView(intent:isVisible:)`** (iOS 16) shows the App Shortcut phrase for the intent, and is empty when the intent isn't an App Shortcut. `ShortcutsLink` (iOS 16) opens the app's page in Shortcuts.
- **`Transferable.exported(as:)` / `exportedContentTypes(_:)`** are iOS 18.2; `.exportingCondition` keeps a representation to the documents it fits.

- **`.system.searchInApp`** (27): `ShowInAppSearchResultsIntent` with `static var searchScopes: [StringSearchScope]` and `var criteria: StringSearchCriteria`. On iOS 26, use `.system.search`.
- **`.system.open`** (27): `OpenIntent` with `var target: some AppEntity`.
- **`.visualIntelligence.semanticContentSearch`** (26): Xcode's snippet names `VisualIntelligence.SceneDescriptor`, **but that type does not exist in the SDK.** Use `SemanticContentDescriptor` (`labels: [String]`, `pixelBuffer: CVReadOnlyPixelBuffer?`). It conforms to `IntentValueConvertible` only on iOS 27.
- **`Attachment`** (27):
  - Initializers: `init(_: CGImage)`, `init(_: CIImage)`, `init(_: CVPixelBuffer)`, `init(imageURL:)`, each taking an optional `orientation:`.
  - **Correction (Phase 4):** FoundationModels itself has no `UIImage` initializer, but the UIKit cross-import overlay (`_FoundationModels_UIKit`) adds `init(_: UIImage, orientation: UIImage.Orientation?)`. Checkpoint passes a `CGImage` plus its `CGImagePropertyOrientation` anyway, so the same path serves Vision.
  - `.label(_:)`.
  - Conforms to `PromptRepresentable`.
- **`OCRTool` / `BarcodeReaderTool`** (27, in the `_Vision_FoundationModels` cross-import overlay — import Vision and FoundationModels): `init(name:description:)`, conforming to `Tool`. **Not in the Simulator SDK** (Apple: "isn't available in Simulator"), so it's behind `#if canImport(_Vision_FoundationModels)`.
- **Token budget:** `SystemLanguageModel.contextSize` (back-deployed to 26.0) and `tokenCount(for:)` (**iOS 26.4+**) take prompts, instructions, tools or schemas. Read the size at runtime; don't hard-code it. Below 26.4, estimate.
- **`Tool.call(arguments:)`** is declared `@concurrent`; a `Tool` is `Sendable`, so it can't touch SwiftData — hand it a snapshot.
- **`@Generable`** types must be `nonisolated` under the project's default MainActor isolation. `Decimal`, `Int`, `String`, optionals, arrays and enums are all `Generable` on iOS 26.
- **Vision `RecognizeDocumentsRequest`** (26): `DocumentObservation.document` → `text.transcript`, `text.lines`, `text.detectedData` (`DataDetection` matches: `.moneyAmount(currency, amount: Decimal)`, `.calendarEvent(startDate…)`, with a `range` into the transcript), `tables[].rows[][].content.text`. `textRecognitionOptions.recognitionLanguages` takes `Locale.Language`.
- **Vision `DetectLensSmudgeRequest`** (26): returns a `SmudgeObservation` whose `confidence` is the probability of a smudge; Apple's sample rejects at ≥ 0.9. Needs an A14 or later.
- **`VisualIntelligence` is not in the Simulator SDK.** `SemanticContentDescriptor.pixelBuffer` is a `CVReadOnlyPixelBuffer`; read it with `withUnsafeBuffer { CIImage(cvPixelBuffer: $0) }`.
- **`AppDependencyManager.shared.add(dependency:)`**: the dependency must be `Sendable`. `@Dependency` resolves from the manager only inside the system's perform flow; outside it (unit tests) the value must be set on the intent first, or access traps. `AppDependency.wrappedValue` has a setter for this.
- **App Shortcuts:** up to 10 per app (Human Interface Guidelines, "App Shortcuts"). Every phrase must contain `\(.applicationName)`. Localized phrases go in `AppShortcuts.xcstrings`; Xcode 27's metadata processor reads that file name and emits `<lang>.lproj/AppShortcuts.strings` plus an NLU model per language.
- **`requestConfirmation`:** `(conditions:actionName:dialog:)` is iOS 18; the `snippetIntent:` overload is iOS 26. `ConfirmationActionName` has no `.delete`; use the default (`.continue`) with a dialog that names the delete. Outside a Siri/Shortcuts session it throws at once, so the write behind it never runs.
- **`RelevantIntent`** (iOS 17) only takes a `WidgetConfigurationIntent` plus a widget kind — it ranks widgets in the Smart Stack, not Siri suggestions. Siri learns from `IntentDonationManager` donations.

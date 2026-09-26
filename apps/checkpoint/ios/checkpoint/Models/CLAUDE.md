# Models - SwiftData Entities

This directory contains all SwiftData model classes that define the app's data schema.

## Entity Overview

| Model | Purpose | Relationships |
|-------|---------|---------------|
| `Vehicle` | Core entity representing a user's vehicle | Has many: services, serviceLogs, mileageSnapshots, serviceVisits, appointments, vehicleNotes; documents (many-to-many) |
| `Service` | Scheduled/tracked maintenance service | Belongs to: Vehicle; Has many: logs; appointments (many-to-many) |
| `ServiceLog` | Record of completed service | Belongs to: Vehicle, Service (optional), ServiceVisit (optional); Has many: attachments |
| `ServiceVisit` / `VisitLineItem` | One shop visit, one total, N logs | Belongs to: Vehicle |
| `ServiceAttachment` (= `Document`) | Photo/PDF: a receipt, a library document, a note's file | Belongs to: ServiceLog and/or VehicleNote (optional); vehicles (many-to-many) |
| `Appointment` (V2) | A booked shop visit: start/end, shop, place, note, status | Belongs to: Vehicle; services (many-to-many) |
| `VehicleNote` (V2) | A note about a vehicle, pinnable, with files | Belongs to: Vehicle; Has many: attachments |
| `MileageSnapshot` | Mileage reading for pace calculation | Belongs to: Vehicle |
| `ServicePreset` | Bundled service type templates | Standalone (loaded from JSON) |

## Schema versions and migration

`CheckpointSchema.swift` holds the rules (read its header before touching a model). In short:
- **V1 is frozen** in `CheckpointSchemaV1.swift` as nested copies of the shipped models — never edit it. A new version freezes the previous one the same way; two versions listing the same live classes hash alike.
- **CloudKit: additive only.** Never remove or rename a stored property (older app versions sync the same container). New attributes optional or defaulted, relationships optional with inverses, no `.unique`.
- **V1 → V2** is one custom stage: lightweight schema change, then `VehicleNoteMigration.reconcile` turns each `Vehicle.notes` into a pinned legacy note (ID derived from the vehicle's). `Vehicle.notes` stays as its mirror for V1 clients; the same reconcile runs every launch (`ServiceMigrationService`) because an old client can write the field any time.
- `CheckpointMigrationTests` opens a real V1 store (`checkpointTests/Fixtures/CheckpointV1.store`). Add a fixture for each shipped version.
- New record types must be deployed to the CloudKit production schema before release.

## Key Patterns

### Cascade Deletes
All relationships use `.cascade` delete rule:
```swift
@Relationship(deleteRule: .cascade, inverse: \Service.vehicle)
var services: [Service]? = []
```
Deleting a Vehicle automatically deletes all its services, logs, and snapshots.

### Status Computation
`Service.status(currentMileage:currentDate:)` returns `.overdue`, `.dueSoon`, `.good`, or `.neutral`:
- **Overdue:** Past due date OR over due mileage
- **Due Soon:** Within 30 days OR within 500 miles
- **Good:** Has due date/mileage but not urgent
- **Neutral:** No due tracking configured

### Urgency Scoring
`Service.urgencyScore(currentMileage:dailyPace:)` returns an integer for sorting:
- Lower score = more urgent (appears first)
- Combines date and mileage factors
- Uses driving pace to project mileage-based urgency

### Pace Calculation (EWMA)
`MileageSnapshot.calculateDailyPace(from:)` uses Exponentially Weighted Moving Average:
- Requires minimum 7 days of data
- Recent snapshots weighted more heavily (30-day half-life)
- Returns nil if insufficient data

### UpcomingItem Protocol
Both `Service` and `MarbeteUpcomingItem` conform to `UpcomingItem`:
```swift
protocol UpcomingItem: Identifiable {
    var id: UUID { get }
    var itemName: String { get }
    var itemStatus: ServiceStatus { get }
    var daysRemaining: Int? { get }
    var urgencyScore: Int { get }
    var itemType: UpcomingItemType { get }
}
```
This enables unified sorting and display in "Next Up" views.

# Models - SwiftData Entities

This directory contains all SwiftData model classes that define the app's data schema.

## Entity Overview

| Model | Purpose | Relationships |
|-------|---------|---------------|
| `Vehicle` | Core entity representing a user's vehicle | Has many: services, serviceLogs, mileageSnapshots |
| `Service` | Scheduled/tracked maintenance service | Belongs to: Vehicle; Has many: logs |
| `ServiceLog` | Record of completed service | Belongs to: Vehicle, Service (optional); Has many: attachments |
| `ServiceAttachment` | Photo/document attached to a log | Belongs to: ServiceLog |
| `MileageSnapshot` | Mileage reading for pace calculation | Belongs to: Vehicle |
| `ServicePreset` | Bundled service type templates | Standalone (loaded from JSON) |

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

## Vehicle Computed Properties

Key computed properties on `Vehicle`:
- `effectiveMileage` - Current or estimated mileage
- `dailyMilesPace` - Calculated driving pace (miles/day)
- `paceConfidence` - `.high`, `.medium`, or `.low`
- `allUpcomingItems` - Services + marbete sorted by urgency
- `nextUpItem` - Most urgent item

## CostCategory
Enum for categorizing service costs:
- `.maintenance` - Regular upkeep
- `.repair` - Fix/replacement
- `.upgrade` - Improvements
- `.inspection` - Checks/certifications
- `.other` - Miscellaneous

## MileageSource
Enum for tracking how mileage was recorded:
- `.manual` - User entered directly
- `.serviceCompletion` - Captured when logging service

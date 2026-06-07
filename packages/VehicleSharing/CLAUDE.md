# VehicleSharing

Cross-app odometer bridge shared between **Checkpoint** (source of truth) and
**Biombo** (read + queue updates). Pure data layer — no UI, no SwiftData, no
networking. Both apps depend on this package so the wire format can't drift.

## Contract

- **App Group:** `group.com.418-studio.shared` (`SharedAppGroup.identifier`).
  This is a *neutral, cross-product* group, distinct from Checkpoint's
  widget/Siri group (`group.com.418-studio.checkpoint.shared`). Both apps must
  declare it in their entitlements; the group must be registered in the Apple
  Developer portal and added to each app's provisioning profile.
- **Storage:** JSON blobs in the shared `UserDefaults` suite. Two keys:
  - `sharedVehicleOdometers` — array of `SharedVehicleOdometer`, published by
    Checkpoint whenever vehicle/mileage data changes.
  - `pendingOdometerUpdates` — append-only queue of `PendingOdometerUpdate`,
    written by Biombo and **drained** by Checkpoint on foreground.

## Data flow

```
Checkpoint                       group.com.418-studio.shared        Biombo
  publish(vehicles) ───────────▶ sharedVehicleOdometers ──────────▶ readVehicles()
  drainPendingUpdates() ◀─────── pendingOdometerUpdates ◀────────── queueUpdate()
        │
        └─ validates, writes MileageSnapshot(source: .biombo), saves
```

Checkpoint stays the source of truth: Biombo only *queues* a reading; Checkpoint
decides whether/how to commit it. All mileage values cross the wire in **miles**
(Checkpoint's internal storage unit). `distanceUnit` rides along so Biombo can
display and accept input in the user's preferred unit.

## Testing

`swift test` from this directory. The bridge takes an injected `UserDefaults`,
so tests run against an isolated in-memory suite (no app-group entitlement
needed).

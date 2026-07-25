//
//  MileageCommit.swift
//  checkpoint
//
//  The one place a service's odometer reading becomes the vehicle's current
//  mileage (F11).
//
//  ## What this fixes
//
//  Three save paths previously did this three different ways:
//
//    - `AddServiceView+Save` hand-rolled `if mileage > vehicle.currentMileage
//      { vehicle.currentMileage = mileage }`. It bypassed
//      `Vehicle.recordMileage`, so `mileageUpdatedAt` was never advanced and
//      no `MileageSnapshot` was written. The odometer moved while the app
//      still believed the reading was weeks old — feeding `dailyMilesPace`,
//      `estimatedMileage`, and `paceConfidence` a mileage delta measured over
//      a stale interval. Adopting the reading actively degraded the estimate
//      engine it was supposed to inform.
//
//    - `MarkServiceVisitDoneSheet` advanced `mileageUpdatedAt` and wrote a
//      snapshot, but inlined both instead of calling `recordMileage`.
//
//    - Neither had a date guard. Both compared magnitude only, so logging a
//      2023 service at 40,000 mi silently overwrote a current odometer of
//      33,000. `ServiceFormValidation.recencyWindow` exists precisely to tell
//      backfill from current entry — but only the *validation* layer knew
//      about dates. The *save* layer did not.
//
//  ## The rule
//
//  A reading is adopted only when it is **the newest reading for the vehicle**
//  and higher than what's on file. "Higher" alone is not sufficient: an old
//  service with a high odometer is a data-entry fact about the past, not news
//  about the present.
//
//  Adoption is never silent. Callers surface `Outcome.adoptionSummary` as a
//  `FormAdvisory.info` *before* saving, because adopting shifts every due-date
//  projection on the vehicle — see docs/SURFACE_DOCTRINE.md, "Mileage, and
//  values that mean two things".
//
//  ## What this is not for
//
//  Future *targets* — `dueMileage`, "remind me at" — never pass through here.
//  A target above the current odometer is the entire point of a reminder and
//  says nothing about where the odometer is today.
//
//  **Manual odometer entry also does not pass through here.** When the user
//  opens the mileage sheet and types a number, that is an authoritative
//  statement about the present, including a correction of a previous
//  over-entry. Gating it on newest-and-higher would make a too-high reading
//  permanently uncorrectable. Manual entry calls
//  `Vehicle.recordMileage(_:recordedAt:source:in:)` directly — see
//  `ContentView+Helpers.updateMileage`.
//
//  The distinction is intent: this type is for readings that arrive as a *side
//  effect* of logging something else, where the user is not being asked about
//  their odometer and so must not be surprised by it changing.
//

import Foundation
import SwiftData

enum MileageCommit {

    /// The result of considering a reading. `didAdopt == false` is the normal,
    /// expected outcome for backfill and for readings at or below the current
    /// odometer — it is not an error.
    struct Outcome: Equatable {
        let didAdopt: Bool
        let previousMileage: Int
        let reading: Int
        /// True when the reading was rejected specifically because a newer
        /// reading already exists. Lets a caller distinguish "this is history"
        /// from "this is lower than current".
        let wasSupersededByNewerReading: Bool

        static func notAdopted(
            previousMileage: Int,
            reading: Int,
            superseded: Bool = false
        ) -> Outcome {
            Outcome(
                didAdopt: false,
                previousMileage: previousMileage,
                reading: reading,
                wasSupersededByNewerReading: superseded
            )
        }
    }

    /// Whether `reading`, observed at `observedAt`, would be adopted as the
    /// vehicle's current mileage. Pure — safe to call from a view body to
    /// drive the pre-save advisory.
    ///
    /// - Note: when the vehicle has no recorded reading yet
    ///   (`mileageUpdatedAt == nil`) any higher reading is adopted regardless
    ///   of age. It is the only odometer information available, and
    ///   `recordMileage` dates it honestly, so the estimate engine projects
    ///   forward from the real observation date rather than from today.
    static func wouldAdopt(
        reading: Int,
        observedAt: Date,
        for vehicle: Vehicle
    ) -> Bool {
        guard reading > vehicle.currentMileage else { return false }
        guard let lastRecordedAt = vehicle.mileageUpdatedAt else { return true }
        return observedAt >= lastRecordedAt
    }

    /// Adopt `reading` as the vehicle's current mileage when it is the newest
    /// and highest reading on file. Routes through
    /// `Vehicle.recordMileage(_:recordedAt:source:in:)` so `currentMileage`,
    /// `mileageUpdatedAt`, and the `MileageSnapshot` always move together.
    ///
    /// Performs only model mutation. Callers own side effects — widget
    /// refresh, notification rescheduling, saving the context.
    @discardableResult
    static func commitIfNewest(
        reading: Int,
        observedAt: Date,
        source: MileageSource,
        for vehicle: Vehicle,
        in context: ModelContext
    ) -> Outcome {
        let previousMileage = vehicle.currentMileage

        guard reading > previousMileage else {
            return .notAdopted(previousMileage: previousMileage, reading: reading)
        }

        if let lastRecordedAt = vehicle.mileageUpdatedAt, observedAt < lastRecordedAt {
            // Backfill. The odometer on file is newer and stays authoritative.
            return .notAdopted(
                previousMileage: previousMileage,
                reading: reading,
                superseded: true
            )
        }

        vehicle.recordMileage(
            reading,
            recordedAt: observedAt,
            source: source,
            in: context
        )

        return Outcome(
            didAdopt: true,
            previousMileage: previousMileage,
            reading: reading,
            wasSupersededByNewerReading: false
        )
    }
}

// MARK: - Advisory copy

extension MileageCommit.Outcome {
    /// Localized "here is what saving will also change" line, or nil when
    /// nothing else changes. Rendered as `FormAdvisory.info`.
    var adoptionSummary: String? {
        guard didAdopt else { return nil }
        return L10n.mileageAlsoUpdates(
            Formatters.mileage(previousMileage),
            Formatters.mileage(reading)
        )
    }
}

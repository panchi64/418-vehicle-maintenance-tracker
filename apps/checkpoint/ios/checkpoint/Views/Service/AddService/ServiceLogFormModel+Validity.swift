//
//  ServiceLogFormModel+Validity.swift
//  checkpoint
//
//  What saving would do to the odometer (F11), and what stops a save (F2).
//

import Foundation

extension ServiceLogFormModel {

    // MARK: - Mileage reasoning (F11)

    /// Whether saving would also advance the vehicle's odometer. Mirrors
    /// `MileageCommit.wouldAdopt` so the advisory can't disagree with the save.
    var wouldAdoptMileage: Bool {
        guard isLogging, !mode.isEdit, let reading = mileageAtService else { return false }
        guard mileageResolution != .keepCurrent else { return false }
        return MileageCommit.wouldAdopt(reading: reading, observedAt: performedDate, for: vehicle)
    }

    /// The one case the app genuinely cannot resolve: a backfilled entry
    /// carrying a reading above the current odometer.
    var hasUnresolvedMileageContradiction: Bool {
        guard isLogging, !mode.isEdit, timing.isBackfill else { return false }
        guard let reading = mileageAtService, reading > vehicle.currentMileage else { return false }
        return mileageResolution == nil
    }

    // MARK: - Validity (F2)

    /// The field a dim Save points at.
    enum BlockingField: Hashable {
        case service
        case odometer
        case due
    }

    struct Blocker: Equatable {
        let field: BlockingField
        let message: String
    }

    /// Why this cannot be saved yet, phrased as the next thing to do, and
    /// where. Nil means it can be saved.
    var blocker: Blocker? {
        if serviceName.trimmingCharacters(in: .whitespaces).isEmpty {
            return Blocker(field: .service, message: L10n.formServiceTypeRequired)
        }
        if mode.isEdit, mileageAtService == nil {
            return Blocker(field: .odometer, message: L10n.editLogMileageRequired)
        }
        if hasUnresolvedMileageContradiction {
            return Blocker(field: .odometer, message: L10n.formResolveOdometerConflict)
        }
        // A mileage-triggered reminder with no mileage has no trigger and would
        // never fire.
        if isScheduling, resolvedDueKind == .mileage, nextDueMileage == nil {
            return Blocker(field: .due, message: L10n.formRemindMileageRequired)
        }
        return nil
    }

    var blockingReason: String? { blocker?.message }
    var isFormValid: Bool { blocker == nil }

    /// Edit: Save stays dim until something would actually change.
    var canSave: Bool {
        isFormValid && (!mode.isEdit || hasEditChanges)
    }

    /// Whether Cancel would throw something away.
    var isDirty: Bool {
        hasContentChanges || !pendingAttachments.isEmpty
    }

    /// Content edits only — what a draft can carry (attachments can't).
    var hasContentChanges: Bool {
        contentSnapshot != baselineSnapshot
    }
}

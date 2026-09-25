//
//  LoggedServiceWriter.swift
//  checkpoint
//
//  Persists the service form's log path ([+] and Mark Done). Separate from the view so the two
//  outcomes — completing a tracked service, or creating a standalone one — are
//  testable without a view hierarchy.
//

import Foundation
import SwiftData

enum LoggedServiceWriter {

    /// Save `model` as a performed service.
    ///
    /// - Parameter target: the tracked service this entry completes (see
    ///   `[Service].activeMatch`). When present, the entry goes through
    ///   `ServiceCompletionService.recordCompletion` — the same path as Mark
    ///   Done — instead of creating a duplicate service.
    /// - Returns: an undo that reverses exactly what was written.
    static func save(
        _ model: ServiceLogFormModel,
        completing target: Service?,
        in context: ModelContext
    ) -> RecordedServiceUndo {
        let vehicle = model.vehicle
        let mileage = model.logAnchorMileage
        let cost = Decimal(string: model.cost)
        let entry = ServiceCompletionService.Entry(
            performedDate: model.performedDate,
            mileage: mileage,
            cost: cost,
            costCategory: model.costCategory,
            notes: model.notes.isEmpty ? nil : model.notes,
            attachments: model.pendingAttachments
        )

        let change: RecordedServiceUndo.ServiceChange
        let log: ServiceLog
        let attachments: [ServiceAttachment]

        if let target {
            let prior = ServiceScheduleState(capturing: target)
            // The form's recurrence is the user's answer for this completion —
            // seeded from the target's own cadence, and possibly switched off.
            // Apply it before completing so the successor matches the preview.
            target.isRecurring = model.isRecurringSchedule
            if model.isRecurringSchedule {
                target.intervalMonths = model.intervalMonths
                target.intervalMiles = model.intervalMiles
            }
            let completion = ServiceCompletionService.recordCompletion(
                of: target,
                vehicle: vehicle,
                entry: entry,
                in: context
            )
            change = .completed(target, prior: prior, successor: completion.successor)
            log = completion.log
            attachments = completion.attachments
        } else {
            let service = Service(
                name: model.serviceName,
                lastPerformed: entry.performedDate,
                lastMileage: mileage,
                intervalMonths: model.isRecurring ? model.intervalMonths : nil,
                intervalMiles: model.isRecurring ? model.intervalMiles : nil,
                isRecurring: model.isRecurring
            )
            service.vehicle = vehicle
            if model.isRecurring {
                service.deriveDueFromIntervals(anchorDate: entry.performedDate, anchorMileage: mileage)
            }
            context.insert(service)

            log = ServiceLog(
                service: service,
                vehicle: vehicle,
                performedDate: entry.performedDate,
                mileageAtService: mileage,
                cost: cost,
                costCategory: cost != nil ? entry.costCategory : nil,
                notes: entry.notes
            )
            context.insert(log)
            attachments = ServiceCompletionService.insertAttachments(
                entry.attachments,
                on: log,
                in: context
            )
            change = .created(service)
        }

        // F11: one commit path. Gated on the reading being the *newest* rather
        // than merely the highest, so backfilling an old service can't
        // overwrite a current odometer — and routed through `recordMileage` so
        // `mileageUpdatedAt` and the snapshot move with it.
        //
        // `keepCurrent` is the user's explicit answer to the one contradiction
        // the app cannot settle, so it wins over the automatic rule.
        var mileageRevert: MileageCommit.Revert?
        if model.mileageResolution != .keepCurrent {
            mileageRevert = MileageCommit.commitIfNewestRevertibly(
                reading: mileage,
                observedAt: entry.performedDate,
                source: .serviceCompletion,
                for: vehicle,
                in: context
            )
        }

        return RecordedServiceUndo(
            change: change,
            log: log,
            attachments: attachments,
            vehicle: vehicle,
            mileageRevert: mileageRevert
        )
    }
}

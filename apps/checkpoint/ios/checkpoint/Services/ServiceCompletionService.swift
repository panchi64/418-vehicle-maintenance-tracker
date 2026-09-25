//
//  ServiceCompletionService.swift
//  checkpoint
//
//  Shared chain-spawn logic for completing a scheduled service.
//  One occurrence completes (becomes a closed record); if the service was
//  marked recurring, the next occurrence is spawned with dates derived from
//  the actual completion date/mileage. Used by all completion entry points
//  (in-app Mark Done, widget, watch) so behavior stays consistent.
//

import Foundation
import SwiftData

struct ServiceCompletionService {

    /// Close `service` and, if it was recurring, spawn the next occurrence.
    /// Caller is responsible for inserting the `ServiceLog` so origin-specific
    /// wiring (`ServiceVisit`, attachments) stays at the call site.
    ///
    /// - Returns: the spawned successor `Service`, or `nil` if no successor was created.
    @MainActor
    @discardableResult
    static func completeService(
        _ service: Service,
        performedDate: Date,
        mileage: Int,
        in context: ModelContext
    ) -> Service? {
        let wasRecurring = service.isRecurring
        let hasPolicy = service.hasIntervalPolicy
        let name = service.name
        let intervalMonths = service.intervalMonths
        let intervalMiles = service.intervalMiles
        let notes = service.notes
        let vehicle = service.vehicle

        service.lastPerformed = performedDate
        service.lastMileage = mileage
        service.dueDate = nil
        service.dueMileage = nil
        service.intervalMonths = nil
        service.intervalMiles = nil

        guard wasRecurring, hasPolicy, let vehicle else {
            // Still rebuild: clearing the due date above means the completed
            // service must drop out of its bundles. The old code cancelled the
            // service's own requests up front instead, which left this path
            // — a non-recurring completion — with nothing to remove them from
            // the pending set until the next launch sweep.
            if let vehicle = service.vehicle {
                ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)
            }
            return nil
        }

        let next = Service(
            name: name,
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles,
            notes: notes,
            isRecurring: true
        )
        next.vehicle = vehicle
        next.deriveDueFromIntervals(anchorDate: performedDate, anchorMileage: mileage)
        context.insert(next)

        // Reschedule the vehicle, not just `next`: reminders are bundled per
        // day, so the completed service has to leave its bundle in the same
        // pass that the follow-up occurrence joins one.
        ServiceNotificationScheduler.rescheduleNotifications(for: vehicle)

        return next
    }

    // MARK: - Logged completion

    /// What the user entered about a performed service.
    struct Entry {
        let performedDate: Date
        let mileage: Int
        let cost: Decimal?
        let costCategory: CostCategory?
        let notes: String?
        let attachments: [AttachmentPicker.AttachmentData]
    }

    struct Completion {
        let log: ServiceLog
        let attachments: [ServiceAttachment]
        /// The next occurrence, when the completed service was recurring.
        let successor: Service?
    }

    /// Log `entry` against an existing tracked `service` and close it — the
    /// single "this service was done" path shared by Mark Done and by the add
    /// form when a logged entry matches a service already on the schedule.
    /// It was previously only reachable from Mark Done, so logging the same
    /// service from [+] created a duplicate beside the one still counting down.
    ///
    /// Performs only model mutation for the log. The odometer is the
    /// caller's (`MileageCommit`), because callers differ on whether the
    /// reading may be adopted.
    @MainActor
    @discardableResult
    static func recordCompletion(
        of service: Service,
        vehicle: Vehicle,
        entry: Entry,
        in context: ModelContext
    ) -> Completion {
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: entry.performedDate,
            mileageAtService: entry.mileage,
            cost: entry.cost,
            costCategory: entry.cost != nil ? entry.costCategory : nil,
            notes: entry.notes
        )
        context.insert(log)

        let attachments = insertAttachments(entry.attachments, on: log, in: context)
        let successor = completeService(
            service,
            performedDate: entry.performedDate,
            mileage: entry.mileage,
            in: context
        )
        return Completion(log: log, attachments: attachments, successor: successor)
    }

    /// Persist picked attachments onto `log`, generating thumbnails.
    @MainActor
    @discardableResult
    static func insertAttachments(
        _ pending: [AttachmentPicker.AttachmentData],
        on log: ServiceLog,
        in context: ModelContext
    ) -> [ServiceAttachment] {
        pending.map { data in
            let attachment = ServiceAttachment(
                serviceLog: log,
                data: data.data,
                thumbnailData: ServiceAttachment.generateThumbnailData(
                    from: data.data,
                    mimeType: data.mimeType
                ),
                fileName: data.fileName,
                mimeType: data.mimeType,
                extractedText: data.extractedText
            )
            context.insert(attachment)
            return attachment
        }
    }
}

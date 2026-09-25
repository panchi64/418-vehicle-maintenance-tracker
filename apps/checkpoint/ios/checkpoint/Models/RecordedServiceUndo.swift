import Foundation
import SwiftData

/// Snapshot of a logged-service save so the success toast can offer UNDO.
///
/// Undo reverses the save exactly, rather than approximating it with new
/// writes: a created service is deleted, a completed one gets its prior
/// schedule back (and loses the successor the completion spawned), and an
/// adopted odometer reading is *restored* via `MileageCommit.Revert` — not
/// re-recorded, which would leave a false snapshot behind (F11).
struct RecordedServiceUndo {
    enum ServiceChange {
        /// The save created this service. Undo deletes it.
        case created(Service)
        /// The save completed an existing tracked service. Undo restores its
        /// schedule and deletes the successor it spawned, if any.
        case completed(Service, prior: ServiceScheduleState, successor: Service?)
    }

    let change: ServiceChange
    let log: ServiceLog
    let attachments: [ServiceAttachment]
    let vehicle: Vehicle?
    /// Nil when the save did not adopt the reading as the vehicle's odometer.
    let mileageRevert: MileageCommit.Revert?

    /// Whether the save left a future reminder in place — a recurring created
    /// service, or a successor spawned by completing a tracked one.
    var leftFutureReminder: Bool {
        switch change {
        case .created(let service): return service.hasDueTracking
        case .completed(_, _, let successor): return successor != nil
        }
    }

    @MainActor
    func perform(in context: ModelContext) {
        mileageRevert?.perform(in: context)
        for attachment in attachments { context.delete(attachment) }
        context.delete(log)

        switch change {
        case .created(let service):
            context.delete(service)
        case .completed(let service, let prior, let successor):
            if let successor { context.delete(successor) }
            prior.restore(to: service)
        }
    }
}

/// The schedule fields `ServiceCompletionService.completeService` overwrites,
/// captured so a completion can be taken back.
struct ServiceScheduleState: Equatable {
    let lastPerformed: Date?
    let lastMileage: Int?
    let dueDate: Date?
    let dueMileage: Int?
    let intervalMonths: Int?
    let intervalMiles: Int?
    let isRecurring: Bool

    init(capturing service: Service) {
        lastPerformed = service.lastPerformed
        lastMileage = service.lastMileage
        dueDate = service.dueDate
        dueMileage = service.dueMileage
        intervalMonths = service.intervalMonths
        intervalMiles = service.intervalMiles
        isRecurring = service.isRecurring
    }

    func restore(to service: Service) {
        service.lastPerformed = lastPerformed
        service.lastMileage = lastMileage
        service.dueDate = dueDate
        service.dueMileage = dueMileage
        service.intervalMonths = intervalMonths
        service.intervalMiles = intervalMiles
        service.isRecurring = isRecurring
    }
}

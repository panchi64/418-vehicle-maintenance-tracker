//
//  ServiceLogDeletion.swift
//  checkpoint
//
//  Deleting a log is not just removing a row. A log is the evidence other
//  records were computed from, so removing it has to put those records back
//  on the evidence that remains:
//
//  - The log's own service: `lastPerformed` / `lastMileage` move to its newest
//    remaining log, or clear when none remain.
//  - The reminder anchored on it: completing a recurring service spawns a
//    successor whose due date is derived from the completion's log. When that
//    log is deleted, the successor re-derives from the newest remaining log of
//    the same service name. Only a reminder whose due still matches the
//    interval derived from the deleted log is moved — one the user set by
//    hand, or re-anchored by a later edit, is left alone.
//  - The visit: a visit is one trip to the shop. It keeps its total while any
//    service remains in it; when the last one goes, the visit goes too — with
//    no services it is unreachable from every screen, and a stranded total is
//    dead data.
//
//  Services are never deleted here, even when they lose their last log: one
//  may still carry the reminder the user set up, and one may be on screen
//  (Service Detail) while its history is edited.
//
//  Attachments survive (`ServiceLog.attachments` is `.nullify`) and stay in
//  the Documents library.
//
//  The returned value is the undo: `undo(in:)` puts back the log, its links,
//  every schedule this changed, and a deleted visit.
//

import Foundation
import SwiftData

struct ServiceLogDeletion {

    // MARK: - Snapshot types

    /// A service's schedule fields as they were before the deletion.
    struct ScheduleState {
        let service: Service
        let lastPerformed: Date?
        let lastMileage: Int?
        let dueDate: Date?
        let dueMileage: Int?

        init(_ service: Service) {
            self.service = service
            self.lastPerformed = service.lastPerformed
            self.lastMileage = service.lastMileage
            self.dueDate = service.dueDate
            self.dueMileage = service.dueMileage
        }

        func restore() {
            service.lastPerformed = lastPerformed
            service.lastMileage = lastMileage
            service.dueDate = dueDate
            service.dueMileage = dueMileage
        }
    }

    /// A visit deleted along with its last log.
    struct VisitSnapshot {
        struct LineItem {
            let id: UUID
            let label: String
            let kind: VisitLineItemKind
            let amount: Decimal
            let createdAt: Date
        }

        let id: UUID
        let vehicle: Vehicle?
        let performedDate: Date
        let mileageAtVisit: Int
        let totalCost: Decimal?
        let costCategory: CostCategory?
        let isItemized: Bool
        let shopName: String?
        let notes: String?
        let createdAt: Date
        let lineItems: [LineItem]

        init(_ visit: ServiceVisit) {
            id = visit.id
            vehicle = visit.vehicle
            performedDate = visit.performedDate
            mileageAtVisit = visit.mileageAtVisit
            totalCost = visit.totalCost
            costCategory = visit.costCategory
            isItemized = visit.isItemized
            shopName = visit.shopName
            notes = visit.notes
            createdAt = visit.createdAt
            lineItems = (visit.lineItems ?? []).map {
                LineItem(id: $0.id, label: $0.label, kind: $0.kind, amount: $0.amount, createdAt: $0.createdAt)
            }
        }

        func recreate(in context: ModelContext) -> ServiceVisit {
            let visit = ServiceVisit(
                vehicle: vehicle,
                performedDate: performedDate,
                mileageAtVisit: mileageAtVisit,
                totalCost: totalCost,
                costCategory: costCategory,
                isItemized: isItemized,
                shopName: shopName,
                notes: notes,
                createdAt: createdAt
            )
            visit.id = id
            context.insert(visit)
            for item in lineItems {
                let restored = VisitLineItem(
                    visit: visit,
                    label: item.label,
                    kind: item.kind,
                    amount: item.amount,
                    createdAt: item.createdAt
                )
                restored.id = item.id
                context.insert(restored)
            }
            return visit
        }
    }

    // MARK: - Captured state

    let logID: UUID
    let service: Service?
    let vehicle: Vehicle?
    let performedDate: Date
    let mileageAtService: Int
    let cost: Decimal?
    let costCategory: CostCategory?
    let notes: String?
    let createdAt: Date
    let attachments: [ServiceAttachment]

    /// The visit the log belonged to, when it survives the deletion.
    let survivingVisit: ServiceVisit?
    /// The visit the log belonged to, when the deletion removed it.
    let deletedVisit: VisitSnapshot?

    /// Every service whose schedule the deletion changed, as it was before.
    let priorSchedules: [ScheduleState]

    // MARK: - Delete

    /// Deletes `log` and recomputes what was derived from it. Returns the
    /// snapshot that undoes it.
    @discardableResult
    static func delete(_ log: ServiceLog, in context: ModelContext) -> ServiceLogDeletion {
        let parent = log.service
        let vehicle = log.vehicle
        let attachments = log.attachments ?? []

        let reanchored = reanchoredServices(for: log)
        var touched: [Service] = reanchored
        if let parent, !touched.contains(where: { $0.id == parent.id }) {
            touched.append(parent)
        }
        let priorSchedules = touched.map(ScheduleState.init)

        let visit = log.visit
        let visitIsEmptied = visit.map { remaining($0.logs, excluding: log).isEmpty } ?? false

        let snapshot = ServiceLogDeletion(
            logID: log.id,
            service: parent,
            vehicle: vehicle,
            performedDate: log.performedDate,
            mileageAtService: log.mileageAtService,
            cost: log.cost,
            costCategory: log.costCategory,
            notes: log.notes,
            createdAt: log.createdAt,
            attachments: attachments,
            survivingVisit: visitIsEmptied ? nil : visit,
            deletedVisit: visitIsEmptied ? visit.map(VisitSnapshot.init) : nil,
            priorSchedules: priorSchedules
        )

        // A receipt stays in the Documents library after its log is gone. One
        // linked to no vehicle would otherwise be swept by the orphan purge.
        if let vehicle {
            for attachment in attachments where (attachment.vehicles ?? []).isEmpty {
                attachment.vehicles = [vehicle]
            }
        }

        if let parent {
            let newest = newestLog(in: remaining(parent.logs, excluding: log))
            parent.lastPerformed = newest?.performedDate
            parent.lastMileage = newest?.mileageAtService
        }

        if !reanchored.isEmpty, let anchor = newestSameNameLog(as: log) {
            for service in reanchored {
                service.deriveDueFromIntervals(anchorDate: anchor.performedDate, anchorMileage: anchor.mileageAtService)
            }
        }

        context.delete(log)
        if visitIsEmptied, let visit {
            context.delete(visit)
        }

        return snapshot
    }

    // MARK: - Undo

    /// Puts the log back with its original identity, links, and every schedule
    /// the deletion moved.
    @discardableResult
    func undo(in context: ModelContext) -> ServiceLog {
        let log = ServiceLog(
            service: service,
            vehicle: vehicle,
            performedDate: performedDate,
            mileageAtService: mileageAtService,
            cost: cost,
            costCategory: costCategory,
            notes: notes,
            createdAt: createdAt
        )
        log.id = logID
        context.insert(log)

        if let survivingVisit {
            log.visit = survivingVisit
        } else if let deletedVisit {
            log.visit = deletedVisit.recreate(in: context)
        }

        for attachment in attachments {
            attachment.serviceLog = log
        }

        for state in priorSchedules {
            state.restore()
        }

        return log
    }

    // MARK: - Helpers

    private static func remaining(_ logs: [ServiceLog]?, excluding log: ServiceLog) -> [ServiceLog] {
        (logs ?? []).filter { $0.id != log.id && !$0.isDeleted }
    }

    private static func newestLog(in logs: [ServiceLog]) -> ServiceLog? {
        logs.max { $0.performedDate < $1.performedDate }
    }

    private static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// The newest remaining log for the same service name on the same vehicle.
    private static func newestSameNameLog(as log: ServiceLog) -> ServiceLog? {
        guard let vehicle = log.vehicle, let name = log.service?.name else { return nil }
        let others = remaining(vehicle.serviceLogs, excluding: log)
        return others.mostRecent(serviceName: name, vehicle: vehicle)
    }

    /// Services on the log's vehicle whose current reminder was derived from
    /// this log: same service name, an active interval policy, and a due that
    /// still equals the interval measured from this log. Empty when this log is
    /// not the newest of its name — the reminder was never anchored on it.
    static func reanchoredServices(for log: ServiceLog) -> [Service] {
        guard let vehicle = log.vehicle, let name = log.service?.name else { return [] }
        let needle = normalized(name)

        if let newestOther = newestSameNameLog(as: log), newestOther.performedDate > log.performedDate {
            return []
        }

        return (vehicle.services ?? []).filter { service in
            !service.isDeleted
                && normalized(service.name) == needle
                && dueWasDerived(from: log, for: service)
        }
    }

    /// Whether every deadline `service` carries is exactly the one its
    /// intervals derive from `log` — the same computation as
    /// `Service.deriveDueFromIntervals`, so an equal value means it came from
    /// this log rather than from the user.
    static func dueWasDerived(from log: ServiceLog, for service: Service) -> Bool {
        guard service.hasIntervalPolicy else { return false }
        if let months = service.intervalMonths, months > 0 {
            let expected = Calendar.current.date(byAdding: .month, value: months, to: log.performedDate)
            guard service.dueDate == expected else { return false }
        }
        if let miles = service.intervalMiles, miles > 0 {
            guard service.dueMileage == log.mileageAtService + miles else { return false }
        }
        return true
    }
}

//
//  ServiceVisitWriter.swift
//  checkpoint
//
//  Persists one shop visit: several services performed together, one honest
//  total on a `ServiceVisit`, and a child `ServiceLog` per service with no
//  cost of its own (never the total divided by N). Extracted from
//  `ClusterDoneForm` so "Mark all done" and Siri's "log an oil change and a
//  tire rotation, $120 at Firestone" write the same shape.
//
//  Model mutation only, plus the odometer (F11). Callers own the refresh of
//  derived surfaces and any toast.
//

import Foundation
import SwiftData

enum ServiceVisitWriter {

    /// One service on the visit.
    enum Item {
        /// A service already on the schedule: this visit completes it, and a
        /// recurring one chains forward (`ServiceCompletionService`).
        case tracked(Service)
        /// A service the vehicle doesn't track yet. It is created as a record
        /// of this visit, recurring from here when given a cadence.
        case new(name: String, intervalMonths: Int?, intervalMiles: Int?)
    }

    /// What the visit recorded.
    struct Details {
        var performedDate: Date
        var mileage: Int
        var totalCost: Decimal?
        var costCategory: CostCategory = .maintenance
        var shopName: String?
        var notes: String?
    }

    @discardableResult
    static func record(
        _ items: [Item],
        on vehicle: Vehicle,
        details: Details,
        attachments: [AttachmentPicker.AttachmentData] = [],
        in context: ModelContext
    ) -> ServiceVisit {
        let visit = ServiceVisit(
            vehicle: vehicle,
            performedDate: details.performedDate,
            mileageAtVisit: details.mileage,
            totalCost: details.totalCost,
            costCategory: details.totalCost != nil ? details.costCategory : nil,
            isItemized: false,
            shopName: details.shopName,
            notes: details.notes
        )
        context.insert(visit)

        // The first child log carries any attachments.
        var firstLog: ServiceLog?
        for item in items {
            let service = service(for: item, on: vehicle, details: details, in: context)
            let log = ServiceLog(
                service: service,
                vehicle: vehicle,
                performedDate: details.performedDate,
                mileageAtService: details.mileage,
                cost: nil,
                costCategory: nil,
                notes: nil
            )
            log.visit = visit
            context.insert(log)
            if firstLog == nil { firstLog = log }

            if case .tracked(let tracked) = item {
                ServiceCompletionService.completeService(
                    tracked,
                    performedDate: details.performedDate,
                    mileage: details.mileage,
                    in: context
                )
            }
        }
        if let firstLog {
            ServiceCompletionService.insertAttachments(attachments, on: firstLog, in: context)
        }

        // F11: one commit path, gated on the reading being the newest.
        MileageCommit.commitIfNewest(
            reading: details.mileage,
            observedAt: details.performedDate,
            source: .serviceCompletion,
            for: vehicle,
            in: context
        )
        return visit
    }

    private static func service(
        for item: Item,
        on vehicle: Vehicle,
        details: Details,
        in context: ModelContext
    ) -> Service {
        switch item {
        case .tracked(let service):
            return service
        case .new(let name, let intervalMonths, let intervalMiles):
            let isRecurring = Service.hasIntervalPolicy(intervalMonths: intervalMonths, intervalMiles: intervalMiles)
            let service = Service(
                name: name,
                lastPerformed: details.performedDate,
                lastMileage: details.mileage,
                intervalMonths: isRecurring ? intervalMonths : nil,
                intervalMiles: isRecurring ? intervalMiles : nil,
                isRecurring: isRecurring
            )
            service.vehicle = vehicle
            if isRecurring {
                service.deriveDueFromIntervals(anchorDate: details.performedDate, anchorMileage: details.mileage)
            }
            context.insert(service)
            return service
        }
    }
}

//
//  L10n+Services.swift
//  checkpoint
//
//  Strings for the Services tab, its rows, and the service / log / visit
//  detail screens. Kept apart from L10n.swift so parallel work doesn't collide
//  in one file. Keys are prefixed `services.`.
//

import Foundation

extension L10n {
    private static func services(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Status groups

    /// Group headers are headers, so they take Title Case.
    static func servicesGroupTitle(_ status: ServiceStatus) -> String {
        switch status {
        case .overdue: return services("services.group.overdue")
        case .dueSoon: return services("services.group.dueSoon")
        case .good, .neutral: return services("services.group.onTrack")
        }
    }

    // MARK: - Row actions

    static var servicesActionEdit: String { services("services.action.edit") }
    static var servicesActionMarkDone: String { services("services.action.markDone") }
    static var servicesActionDuplicate: String { services("services.action.duplicate") }
    static var servicesActionStopTracking: String { services("services.action.stopTracking") }
    static var servicesActionSelect: String { services("services.action.select") }
    static func servicesActionMarkDoneCount(_ count: Int) -> String {
        String(format: services("services.action.markDoneCount"), count)
    }
    static func servicesActionDeleteCount(_ count: Int) -> String {
        String(format: services("services.action.deleteCount"), count)
    }

    static func servicesBulkDeleteTitle(_ count: Int) -> String {
        String(format: services("services.bulkDelete.title"), count)
    }
    static var servicesBulkDeleteMessage: String { services("services.bulkDelete.message") }

    static func servicesToastStoppedTracking(_ name: String) -> String {
        String(format: services("services.toast.stoppedTracking"), name)
    }

    // MARK: - Row

    /// "Due 32,500 mi or Oct 4" — both triggers, whichever comes first.
    static func servicesRowDueEither(_ mileage: String, _ date: String) -> String {
        String(format: services("services.row.dueEither"), mileage, date)
    }
    /// "Due 32,500 mi" / "Due Oct 4".
    static func servicesRowDue(_ trigger: String) -> String {
        String(format: services("services.row.due"), trigger)
    }

    // MARK: - Empty state

    static var servicesEmptyTitle: String { services("services.empty.title") }
    static var servicesEmptyMessage: String { services("services.empty.message") }
    static var servicesEmptyAdd: String { services("services.empty.add") }

    // MARK: - Service detail

    static var servicesDetailSchedule: String { services("services.detail.schedule") }
    static var servicesDetailRepeats: String { services("services.detail.repeats") }
    static var servicesDetailHistory: String { services("services.detail.history") }
    static var servicesDetailInsights: String { services("services.detail.insights") }
    static var servicesDetailTimeSinceLast: String { services("services.detail.timeSinceLast") }
    static var servicesDetailDistanceSinceLast: String { services("services.detail.distanceSinceLast") }
    static var servicesDetailAverageCost: String { services("services.detail.averageCost") }
    static var servicesDetailVisitCount: String { services("services.detail.visitCount") }
    static var servicesDetailTimesServiced: String { services("services.detail.timesServiced") }
    static var servicesDetailSetUpReminder: String { services("services.detail.setUpReminder") }
    static var servicesDetailPartOfVisit: String { services("services.detail.partOfVisit") }
    static var servicesDetailStopTrackingHint: String { services("services.detail.stopTrackingHint") }

    // MARK: - Log / visit detail

    static var servicesLogTitle: String { services("services.log.title") }
    static var servicesVisitTotal: String { services("services.visit.total") }
    static var servicesVisitShop: String { services("services.visit.shop") }
    static var servicesVisitServicesPerformed: String { services("services.visit.servicesPerformed") }
    static var servicesVisitIncluded: String { services("services.visit.included") }
    static var servicesVisitIncludedInTotal: String { services("services.visit.includedInTotal") }
}

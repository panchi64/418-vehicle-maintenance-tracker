//
//  RecallInfo+PlannedService.swift
//  checkpoint
//
//  What "add as planned service" means for a recall: a one-off service named
//  after the recalled component, due a week out — a nudge to book the free
//  dealer repair. The recall sheet prefills the service form with it; Siri's
//  Check Recalls adds it directly.
//

import Foundation

extension RecallInfo {
    /// Days from today the planned repair is due.
    static let plannedServiceLeadDays = 7

    /// "Recall: Air Bags".
    var plannedServiceName: String {
        L10n.recallPlannedServiceName(component.localizedCapitalized)
    }

    func plannedServiceDueDate(from now: Date = .now) -> Date {
        Calendar.current.date(byAdding: .day, value: Self.plannedServiceLeadDays, to: now) ?? now
    }
}

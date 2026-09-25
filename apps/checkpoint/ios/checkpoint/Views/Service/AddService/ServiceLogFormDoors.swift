//
//  ServiceLogFormDoors.swift
//  checkpoint
//
//  Presenter shims: the names routing and detail screens already present.
//  Each is one door of `ServiceLogForm` — none is a form of its own. (Mark Done
//  lives in `MarkServiceVisitDoneSheet`, which also routes clusters.)
//

import SwiftUI

/// [+] — `ActiveSheet.addService`.
struct AddServiceView: View {
    let vehicle: Vehicle
    var seasonalPrefill: SeasonalPrefill?
    var postRecordPrefill: PostRecordPrefill?

    var body: some View {
        ServiceLogForm(vehicle: vehicle, seasonalPrefill: seasonalPrefill, postRecordPrefill: postRecordPrefill)
    }
}

/// A history entry's Edit.
struct EditServiceLogView: View {
    let log: ServiceLog
    /// Asks the presenter to delete the entry once the form has dismissed.
    var onDelete: (() -> Void)?

    var body: some View {
        if let vehicle = log.vehicle {
            ServiceLogForm(vehicle: vehicle, mode: .edit(log), onDelete: onDelete)
        } else {
            ContentUnavailableView(L10n.serviceFallbackName, systemImage: "wrench.and.screwdriver")
        }
    }
}

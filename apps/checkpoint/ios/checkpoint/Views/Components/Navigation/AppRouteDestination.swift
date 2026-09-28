//
//  AppRouteDestination.swift
//  checkpoint
//
//  The screen for each `AppRoute`, whichever stack or column shows it.
//

import SwiftUI

/// The screen for each pushed `AppRoute`.
struct AppRouteDestination: View {
    let route: AppRoute

    @Environment(AppState.self) private var appState

    var body: some View {
        switch route {
        case .service(let service):
            if let vehicle = service.vehicle ?? appState.selectedVehicle {
                ServiceDetailView(service: service, vehicle: vehicle)
            }
        case .serviceLog(let log):
            ServiceLogDestination(log: log)
        case .visit(let visit):
            ServiceVisitDetailView(visit: visit)
        case .document(let document):
            DocumentDetailView(document: document)
        case .documents(let vehicle):
            Text(verbatim: "EXP").navigationTitle("Documents") //EXP DocumentsView(vehicle: vehicle)
        case .notes(let vehicle):
            VehicleNotesView(vehicle: vehicle)
        }
    }
}

/// A pushed log detail that deletes its log only after it has popped: a model
/// deleted while its screen is still animating away can be read by a view that
/// no longer has it. Deletion offers Undo — the toast renders above everything.
///
/// In a detail column, picking another row also makes this disappear; nothing
/// is deleted then, since `pendingDeletion` is only set by the detail's Delete.
private struct ServiceLogDestination: View {
    let log: ServiceLog

    @State private var pendingDeletion: ServiceLog?

    var body: some View {
        ServiceLogDetailView(log: log, onDelete: { pendingDeletion = $0 })
            .onDisappear {
                guard let log = pendingDeletion else { return }
                pendingDeletion = nil
                ServiceLogDeleteAction.perform(log, offerUndo: true)
            }
    }
}

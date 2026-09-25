//
//  ServicesTab+Sheets.swift
//  checkpoint
//
//  The tasks a Services row starts, and the confirmations its destructive
//  actions need. One `.sheet(item:)`, so two row sheets can't race.
//

import SwiftUI

enum ServicesTabSheet: Identifiable {
    case editService(Service)
    case editLog(ServiceLog)
    case duplicateLog(ServiceLog)
    case export

    var id: String {
        switch self {
        case .editService(let service): return "editService-\(service.id)"
        case .editLog(let log): return "editLog-\(log.id)"
        case .duplicateLog(let log): return "duplicateLog-\(log.id)"
        case .export: return "export"
        }
    }
}

/// A delete waiting on confirmation. Deleting a service cascades to its
/// history, so it is confirmed rather than undone.
enum ServicesPendingDelete {
    case service(Service)
    /// Everything selected in edit mode.
    case selection(count: Int)

    var title: String {
        switch self {
        case .service: return L10n.serviceDeleteConfirmTitle
        case .selection(let count): return L10n.servicesBulkDeleteTitle(count)
        }
    }

    var message: String {
        switch self {
        case .service: return L10n.serviceDeleteConfirmMessage
        case .selection: return L10n.servicesBulkDeleteMessage
        }
    }
}

extension ServicesTab {

    @ViewBuilder
    func sheetContent(_ sheet: ServicesTabSheet) -> some View {
        if let vehicle {
            switch sheet {
            case .editService(let service):
                EditServiceView(service: service, vehicle: vehicle)
            case .editLog(let log):
                EditServiceLogView(log: log, onDelete: { logPendingDeletion = log })
            case .duplicateLog(let log):
                ServiceLogForm(duplicating: log, vehicle: vehicle)
            case .export:
                ExportOptionsSheet(
                    vehicle: vehicle,
                    // The whole history, not the search-narrowed list — and
                    // already newest-first from the query.
                    serviceLogs: serviceLogs,
                    isExporting: $isExporting
                ) { url in
                    AnalyticsService.shared.capture(.serviceHistoryExported)
                    exportPDFURL = url
                    ToastService.shared.show(L10n.toastPDFReady, icon: "doc.text", style: .info)
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    func confirmDelete(_ pending: ServicesPendingDelete, content: ServicesTabContent) {
        guard let vehicle else { return }
        switch pending {
        case .service(let service):
            ServiceDeleteAction.delete([service], vehicle: vehicle, in: modelContext)
        case .selection:
            let selection = appState.servicesTab.selection
            let services = content.services.filter { selection.contains(.service($0.id)) }
            // A selected log whose service is also being deleted goes with it
            // by cascade. Deleting it on its own first would also recompute
            // that service's schedule, which is about to be gone.
            // Confirmed as a batch, so no per-log Undo toasts.
            let serviceIDs = Set(services.map(\.id))
            let logs = content.logs.filter {
                selection.contains(.log($0.id)) && !serviceIDs.contains($0.service?.id ?? UUID())
            }
            for log in logs {
                ServiceLogDeleteAction.perform(log, offerUndo: false)
            }
            ServiceDeleteAction.delete(services, vehicle: vehicle, in: modelContext)
            appState.servicesTab.setSelecting(false)
        }
    }
}

//
//  ServicesTab+Selection.swift
//  checkpoint
//
//  Edit mode. Select (in the shared toolbar, `TabRootActions`) turns the list's
//  edit mode on; rows grow the system selection circle, and a bottom toolbar
//  replaces the tab bar with the bulk actions and their counts:
//
//    Mark Done (2)                         Delete (3)
//
//  Mark Done counts selected services only — a log is already done. Several
//  services complete together as one Service Visit, like a notification's
//  "Mark as Done" on a bundle.
//

import SwiftUI

extension ServicesTab {

    @ToolbarContentBuilder
    func selectionToolbar(_ content: ServicesTabContent) -> some ToolbarContent {
        if appState.servicesTab.isSelecting {
            let selection = appState.servicesTab.selection
            let services = content.services.filter { selection.contains(.service($0.id)) }

            ToolbarItem(placement: .bottomBar) {
                ToolbarTextButton(
                    L10n.servicesActionMarkDoneCount(services.count),
                    systemImage: "checkmark.circle"
                ) {
                    guard let vehicle else { return }
                    appState.present(.markDone(MarkDoneRequest(services: services, vehicle: vehicle)))
                    appState.servicesTab.setSelecting(false)
                }
                .disabled(services.isEmpty)
            }
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                ToolbarTextButton(
                    L10n.servicesActionDeleteCount(selection.count),
                    systemImage: "trash",
                    role: .destructive
                ) {
                    pendingDelete = .selection(count: selection.count)
                }
                .disabled(selection.isEmpty)
            }
        }
    }
}

/// Select / Done for the Services tab root. Shown by `TabRootActions` only while
/// the list has something to select.
struct ServicesSelectButton: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let isSelecting = appState.servicesTab.isSelecting
        ToolbarTextButton(
            isSelecting ? L10n.commonDone : L10n.servicesActionSelect,
            systemImage: isSelecting ? "checkmark" : "checkmark.circle"
        ) {
            appState.servicesTab.setSelecting(!isSelecting)
        }
        .accessibilityIdentifier("toolbar.servicesSelect")
    }
}

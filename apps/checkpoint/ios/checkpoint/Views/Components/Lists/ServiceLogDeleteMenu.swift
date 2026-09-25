//
//  ServiceLogDeleteMenu.swift
//  checkpoint
//
//  Row-level delete for a service log. The log rows (Home activity, Services
//  history and timeline, Costs expenses, Service Detail history) live in
//  scroll stacks rather than a `List`, so there is no swipe action to hang it
//  on — a long-press context menu is the row affordance everywhere.
//

import SwiftUI

extension View {
    /// nil attaches no menu, for rows that are only sometimes logs (the
    /// timeline mixes completed logs with upcoming services).
    @ViewBuilder
    func serviceLogDeleteMenu(_ onDelete: (() -> Void)?) -> some View {
        if let onDelete {
            contextMenu {
                Button(role: .destructive, action: onDelete) {
                    Label(L10n.logDeleteAction, systemImage: "trash")
                }
            }
            // A long-press is hard to find with VoiceOver; the same action
            // is offered in the Actions rotor.
            .accessibilityAction(named: L10n.logDeleteAction, onDelete)
        } else {
            self
        }
    }
}

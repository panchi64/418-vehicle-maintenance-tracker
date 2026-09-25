//
//  ServiceLogDeleteMenu.swift
//  checkpoint
//
//  Row-level delete for a service log in a scroll stack (Home activity, Costs
//  expenses, Service Detail history), where there is no `List` swipe action
//  to hang it on — a long-press context menu is the row affordance. The
//  Services tab is a `List` and carries the full swipe + menu set itself.
//

import SwiftUI

extension View {
    /// nil attaches no menu, for rows that are only sometimes logs.
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

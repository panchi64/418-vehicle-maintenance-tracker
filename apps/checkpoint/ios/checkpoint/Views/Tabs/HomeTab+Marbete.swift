//
//  HomeTab+Marbete.swift
//  checkpoint
//
//  "Mark Renewed" on the marbete's Next Up card.
//
//  The marbete renews for a year in the same month, so a renewal has exactly
//  one outcome and needs no form: Mark Renewed → confirm (2 taps), with Undo.
//  It previously opened Edit Vehicle, where the user had to find the marbete
//  section and re-pick the year.
//

import SwiftUI
import SwiftData

extension HomeTab {
    func renewMarbete(of vehicle: Vehicle, to expiration: Vehicle.MarbeteExpiration) {
        guard let previous = vehicle.marbeteExpiration else { return }
        MarbeteRenewal.apply(expiration, to: vehicle)
        HapticService.shared.success()

        ToastService.shared.show(
            L10n.homeMarbeteRenewedToast(Vehicle.marbeteExpirationLabel(expiration)),
            icon: "checkmark",
            style: .success,
            action: ToastService.ToastAction(label: L10n.commonUndo.uppercased()) {
                MarbeteRenewal.apply(previous, to: vehicle)
                HapticService.shared.selectionChanged()
            }
        )
    }
}

/// The model change plus the surfaces computed from it.
private enum MarbeteRenewal {
    static func apply(_ expiration: Vehicle.MarbeteExpiration, to vehicle: Vehicle) {
        vehicle.applyMarbeteExpiration(expiration)
        try? vehicle.modelContext?.save()
        NotificationService.shared.scheduleMarbeteNotifications(for: vehicle)
        WidgetDataService.shared.updateWidget(for: vehicle)
    }
}

extension View {
    /// Confirms a pending marbete renewal. Set `pending` to open it.
    func marbeteRenewalDialog(
        pending: Binding<Vehicle.MarbeteExpiration?>,
        onConfirm: @escaping (Vehicle.MarbeteExpiration) -> Void
    ) -> some View {
        confirmationDialog(
            L10n.homeMarbeteRenewTitle,
            isPresented: Binding(
                get: { pending.wrappedValue != nil },
                set: { if !$0 { pending.wrappedValue = nil } }
            ),
            titleVisibility: .visible,
            presenting: pending.wrappedValue
        ) { expiration in
            Button(L10n.homeMarbeteRenewConfirm(Vehicle.marbeteExpirationLabel(expiration))) {
                onConfirm(expiration)
            }
            Button(L10n.commonCancel, role: .cancel) {}
        }
    }
}

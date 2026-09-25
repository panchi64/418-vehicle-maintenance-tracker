//
//  RestorePurchasesAction.swift
//  checkpoint
//
//  Restore Purchases from Settings or the paywall, with the outcome stated.
//  The restore used to return silently, which reads as "nothing happened"
//  whether it worked, found nothing, or failed. Toasts render above sheets,
//  so the answer is visible from either door.
//

import Foundation

enum RestorePurchasesAction {
    static func run() async {
        switch await StoreManager.shared.restorePurchases() {
        case .restored:
            HapticService.shared.success()
            ToastService.shared.show(L10n.settingsRestoreSuccess, icon: "checkmark.seal", style: .success)
        case .nothingToRestore:
            ToastService.shared.show(L10n.settingsRestoreNothing, icon: "info.circle", style: .info)
        case .cancelled:
            break
        case .failed:
            HapticService.shared.error()
            ToastService.shared.show(L10n.settingsRestoreFailed, icon: "exclamationmark.triangle", style: .error)
        }
    }
}

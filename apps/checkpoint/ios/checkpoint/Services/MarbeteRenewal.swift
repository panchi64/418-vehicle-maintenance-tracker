//
//  MarbeteRenewal.swift
//  checkpoint
//
//  Recording a marbete renewal: the model change plus the surfaces computed
//  from it (the marbete reminders and the widget). Home's Mark Renewed and
//  Siri's Renew Marbete both write through here; which expiration a renewal
//  moves to is `Vehicle.renewedMarbeteExpiration`.
//

import Foundation
import SwiftData

enum MarbeteRenewal {
    static func apply(_ expiration: Vehicle.MarbeteExpiration, to vehicle: Vehicle) {
        vehicle.applyMarbeteExpiration(expiration)
        try? vehicle.modelContext?.save()
        NotificationService.shared.scheduleMarbeteNotifications(for: vehicle)
        WidgetDataService.shared.updateWidget(for: vehicle)
    }
}

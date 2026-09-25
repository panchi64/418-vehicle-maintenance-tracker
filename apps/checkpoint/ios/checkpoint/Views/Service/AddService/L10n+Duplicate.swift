//
//  L10n+Duplicate.swift
//  checkpoint
//
//  Strings for duplicating a log entry to another vehicle: the form's vehicle
//  field and the row's "Duplicate To" submenu.
//

import Foundation

extension L10n {
    /// The duplicate form's target-vehicle field. VoiceOver: "Vehicle, <name>".
    static var formVehicle: String { NSLocalizedString("form.vehicle", comment: "") }

    /// A log row's submenu: duplicate the entry onto a chosen vehicle.
    static var servicesActionDuplicateTo: String {
        NSLocalizedString("services.action.duplicateTo", comment: "")
    }

    /// Subtitle under the source vehicle in the "Duplicate To" submenu.
    static var servicesActionDuplicateCurrentVehicle: String {
        NSLocalizedString("services.action.duplicateCurrentVehicle", comment: "")
    }
}

//
//  IntentDonations.swift
//  checkpoint
//
//  Tells Siri when the user does in the app what an intent can do by voice,
//  so it can learn the habit ("you usually log mileage on Sundays") and
//  suggest the shortcut. Called from the in-app save paths only — an intent
//  Siri or Shortcuts ran is donated by the system already.
//
//  Each donation carries the parameters that would repeat the action.
//  Fire-and-forget: a failed donation changes nothing for the user.
//

import AppIntents

@MainActor
enum IntentDonations {

    /// After Mark Done. Donated against the next occurrence, the service a
    /// repeat of this action would complete; a completion that left none
    /// (not recurring) has nothing to repeat.
    static func markedDone(successor: Service?) {
        guard let successor else { return }
        donate(MarkServiceDoneIntent(service: ServiceEntity(model: successor)))
    }

    /// After logging performed services from [+] or "Mark all done".
    static func loggedServices(_ names: [String], on vehicle: Vehicle) {
        guard !names.isEmpty else { return }
        donate(LogServiceIntent(vehicle: VehicleEntity(model: vehicle), services: names))
    }

    /// After an odometer update from the mileage sheet. The reading is left
    /// out: a suggestion to repeat it should ask for today's, not replay the
    /// last one.
    static func updatedMileage(on vehicle: Vehicle) {
        let intent = UpdateMileageIntent()
        intent.vehicle = VehicleEntity(model: vehicle)
        donate(intent)
    }

    /// After putting a service on the schedule.
    static func addedService(_ service: Service) {
        donate(AddServiceIntent(vehicle: service.vehicle.map { VehicleEntity(model: $0) }, name: service.name))
    }

    private static func donate(_ intent: some AppIntent) {
        IntentDonationManager.shared.donate(intent: intent)
    }
}

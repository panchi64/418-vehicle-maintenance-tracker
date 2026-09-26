//
//  AppState+PendingRoute.swift
//  checkpoint
//
//  Turns a `PendingRoute` — where a notification, widget or intent asked to
//  go — into navigation state. Every route first closes whatever sheet is up,
//  then switches tab, then pushes or presents.
//

import Foundation
import UIKit

extension AppState {

    func apply(_ route: PendingRoute, vehicles: [Vehicle], now: Date = Date()) {
        // A route for a vehicle deleted since it was requested has nowhere to go.
        guard let vehicle = vehicles.first(where: { $0.id == route.vehicleID }) else { return }
        selectVehicle(vehicle)

        switch route {
        case .updateMileage:
            showTabRoot(.home)
            present(.mileageUpdate)

        case .costs:
            showTabRoot(.costs)

        case .editVehicle:
            // `present` closes any sheet already up before this one shows.
            present(.editVehicle)

        case .vehicle:
            showTabRoot(.home)

        case .services(_, let serviceIDs):
            let services = Self.services(serviceIDs, in: vehicle)
            if services.count == 1 {
                navigate(to: .service(services[0]), on: .services)
            } else {
                showTabRoot(.services)
            }

        case .markDone(_, let serviceIDs):
            // Services completed or deleted since the reminder was scheduled
            // drop out, so a stale banner can't log one twice. Nothing left:
            // show the services where they stand instead.
            let stillDue = ServiceNotificationScheduler.stillDueServiceIDs(for: vehicle, now: now)
            let services = Self.services(serviceIDs, in: vehicle).filter { stillDue.contains($0.id.uuidString) }
            if services.isEmpty {
                showTabRoot(.services)
            } else {
                present(.markDone(MarkDoneRequest(services: services, vehicle: vehicle)))
            }

        // A detail deleted since falls back to the tab it would have opened on.
        case .serviceLog(_, let logID):
            if let log = (vehicle.serviceLogs ?? []).first(where: { $0.id == logID }) {
                navigate(to: .serviceLog(log), on: .services)
            } else {
                showTabRoot(.services)
            }

        case .visit(_, let visitID):
            if let visit = (vehicle.serviceVisits ?? []).first(where: { $0.id == visitID }) {
                navigate(to: .visit(visit), on: .costs)
            } else {
                showTabRoot(.costs)
            }

        case .document(_, let documentID):
            if let document = (vehicle.documents ?? []).first(where: { $0.id == documentID }) {
                // Over the library, so Back lands where the document lives.
                navigate(to: [.documents(vehicle), .document(document)], on: .home)
            } else {
                showTabRoot(.home)
            }

        case .searchServices(_, let term):
            showTabRoot(.services)
            servicesTab.searchText = term

        case .searchDocuments(_, let term):
            documentsSearchSeed = term
            navigate(to: [.documents(vehicle)], on: .home)

        case .logReceipt(_, let captureID):
            // A capture older than its lifetime has nothing left to read.
            if let capture = VisualCaptureStore.shared.capture(id: captureID) {
                showTabRoot(.home)
                present(.addService(receipt: UIImage(cgImage: capture.image)))
            } else {
                showTabRoot(.home)
            }

        case .mileageReading(_, let reading):
            mileageReadingSeed = reading
            showTabRoot(.home)
            present(.mileageUpdate)

        case .addVehicle(_, let vin):
            showTabRoot(.home)
            // Seeded only when Add Vehicle opens: behind the paywall nothing
            // would take it, and a later Add Vehicle would start from it.
            if !VehicleService.requiresPro(toAddTo: vehicles.count, isPro: StoreManager.shared.isPro) {
                addVehicleVINSeed = vin
            }
            requestAddVehicle(vehicleCount: vehicles.count)

        case .logService:
            showTabRoot(.home)
            present(.addService())

        case .scanReceipt:
            showTabRoot(.home)
            present(.addService(scansReceipt: true))

        // Appointments live on Home; a closed or deleted one lands there too.
        case .appointment(_, let appointmentID):
            showTabRoot(.home)
            if let appointment = (vehicle.appointments ?? []).first(where: { $0.id == appointmentID }),
               appointment.isScheduled {
                present(.appointment(AppointmentEditorRequest(target: .edit(appointment))))
            }

        case .vehicleNote(_, let noteID):
            // Over the Notes list, so closing the note lands where it lives.
            navigate(to: [.notes(vehicle)], on: .home)
            if let note = (vehicle.vehicleNotes ?? []).first(where: { $0.id == noteID }) {
                present(.vehicleNote(VehicleNoteEditorRequest(target: .edit(note))))
            }
        }
    }

    /// Close any sheet, bring `tab` forward, and pop it to its root.
    private func showTabRoot(_ tab: Tab) {
        navigate(to: [], on: tab)
    }

    private static func services(_ ids: [UUID], in vehicle: Vehicle) -> [Service] {
        let wanted = Set(ids)
        return (vehicle.services ?? []).filter { wanted.contains($0.id) }
    }
}

//
//  ActiveSheet.swift
//  checkpoint
//
//  Every task the app root can present, as one value. ContentView renders it
//  through a single `.sheet(item:)`, so two root sheets can never race for the
//  one presentation slot — the failure the old stack of ~17 independent
//  `.sheet(isPresented:)` modifiers kept reintroducing.
//
//  Details (service, log, visit, document, the documents library) are not
//  here: they are pushed (`AppRoute`). Onboarding's full-screen covers are not
//  here either: they are driven by `OnboardingState`'s phase.
//

import Foundation
import UIKit

enum ActiveSheet: Identifiable {
    case vehiclePicker
    case addVehicle
    case editVehicle
    /// `receipt`: an image to read on open (Visual Intelligence).
    /// `scansReceipt`: open with the receipt scanner up (Scan Receipt Control).
    case addService(
        seasonal: SeasonalPrefill? = nil,
        postRecord: PostRecordPrefill? = nil,
        receipt: UIImage? = nil,
        scansReceipt: Bool = false
    )
    case mileageUpdate
    case settings
    case proPaywall
    case tipModal
    case themeReveal(ThemeDefinition)
    /// Services a notification's "Mark as Done" asked to complete.
    case markDone(MarkDoneRequest)
    case clusterDetail(ServiceCluster)
    case clusterMarkDone(ServiceCluster)
    /// Offered after a vehicle is added: common services with default intervals.
    case starterSchedule(Vehicle)
    /// Book a shop visit (`preselected`: services to start with) or edit one.
    case appointment(AppointmentEditorRequest)
    /// An appointment's Log Visit: the service form prefilled from it.
    case completeAppointment(Appointment)
    /// Add a note to a vehicle, or edit one.
    case vehicleNote(VehicleNoteEditorRequest)

    var id: String {
        switch self {
        case .vehiclePicker: return "vehiclePicker"
        case .addVehicle: return "addVehicle"
        case .editVehicle: return "editVehicle"
        case .addService: return "addService"
        case .mileageUpdate: return "mileageUpdate"
        case .settings: return "settings"
        case .proPaywall: return "proPaywall"
        case .tipModal: return "tipModal"
        case .themeReveal(let theme): return "themeReveal-\(theme.id)"
        case .markDone(let request): return "markDone-\(request.id)"
        case .clusterDetail(let cluster): return "clusterDetail-\(cluster.id)"
        case .clusterMarkDone(let cluster): return "clusterMarkDone-\(cluster.id)"
        case .starterSchedule(let vehicle): return "starterSchedule-\(vehicle.id)"
        case .appointment(let request): return "appointment-\(request.id)"
        case .completeAppointment(let appointment): return "completeAppointment-\(appointment.id)"
        case .vehicleNote(let request): return "vehicleNote-\(request.id)"
        }
    }

    /// Whether the sheet holds SwiftData models, which must be released before
    /// the app swaps its `ModelContainer`.
    var retainsModels: Bool {
        switch self {
        case .markDone, .clusterDetail, .clusterMarkDone, .starterSchedule,
             .appointment, .completeAppointment, .vehicleNote:
            return true
        default: return false
        }
    }
}

/// What the appointment sheet opens on.
struct AppointmentEditorRequest: Identifiable {
    enum Target {
        /// Book a visit, starting with these services ticked.
        case new(Vehicle, preselected: [Service])
        case edit(Appointment)
    }

    let id = UUID()
    let target: Target

    var vehicle: Vehicle? {
        switch target {
        case .new(let vehicle, _): vehicle
        case .edit(let appointment): appointment.vehicle
        }
    }
}

/// What the note sheet opens on.
struct VehicleNoteEditorRequest: Identifiable {
    enum Target {
        case new(Vehicle)
        case edit(VehicleNote)
    }

    let id = UUID()
    let target: Target
}

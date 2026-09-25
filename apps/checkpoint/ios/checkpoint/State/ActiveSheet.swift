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

enum ActiveSheet: Identifiable {
    case vehiclePicker
    case addVehicle
    case editVehicle
    case addService(seasonal: SeasonalPrefill? = nil, postRecord: PostRecordPrefill? = nil)
    /// `prefilled` carries a Siri intent's reading.
    case mileageUpdate(prefilled: Int? = nil)
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
        }
    }

    /// Whether the sheet holds SwiftData models, which must be released before
    /// the app swaps its `ModelContainer`.
    var retainsModels: Bool {
        switch self {
        case .markDone, .clusterDetail, .clusterMarkDone, .starterSchedule: return true
        default: return false
        }
    }
}

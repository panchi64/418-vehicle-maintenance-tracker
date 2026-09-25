//
//  MarkServiceVisitDoneSheet.swift
//  checkpoint
//
//  Mark Done, routed by what is being completed:
//
//    .singleService → the unified `ServiceLogForm` in its `.complete` door —
//                     the same form, save path, and defaults as [+], with the
//                     service preselected and locked.
//    .cluster       → `ClusterDoneForm`: one visit, N services, one honest
//                     total on a `ServiceVisit` (never divided per service).
//
//  Kept under this name because notification routing (`ActiveSheet.markDone`)
//  and the detail screens present it.
//

import SwiftData
import SwiftUI

struct MarkServiceVisitDoneSheet: View {
    enum Origin {
        case singleService(Service, Vehicle)
        case cluster(ServiceCluster)
    }

    let origin: Origin
    var onSaved: (() -> Void)? = nil

    var body: some View {
        switch origin {
        case .singleService(let service, let vehicle):
            ServiceLogForm(vehicle: vehicle, mode: .complete(service), onSaved: onSaved)
        case .cluster(let cluster):
            ClusterDoneForm(cluster: cluster, onSaved: onSaved)
        }
    }
}

/// Single-service Mark Done, for presenters that hold a service and vehicle.
struct MarkServiceDoneSheet: View {
    let service: Service
    let vehicle: Vehicle
    var onSaved: (() -> Void)? = nil

    var body: some View {
        MarkServiceVisitDoneSheet(origin: .singleService(service, vehicle), onSaved: onSaved)
    }
}

/// A suggested cluster's "Mark all done".
struct MarkClusterDoneSheet: View {
    let cluster: ServiceCluster
    var onSaved: (() -> Void)? = nil

    var body: some View {
        MarkServiceVisitDoneSheet(origin: .cluster(cluster), onSaved: onSaved)
    }
}

#Preview("Single") {
    @Previewable @State var vehicle = Vehicle(
        name: "Test Car",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentMileage: 32500
    )
    @Previewable @State var service = Service(
        name: "Oil Change",
        dueDate: Calendar.current.date(byAdding: .day, value: 12, to: .now),
        dueMileage: 33000,
        intervalMonths: 6,
        intervalMiles: 5000
    )

    MarkServiceDoneSheet(service: service, vehicle: vehicle)
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceVisit.self, VisitLineItem.self, MileageSnapshot.self, ServiceAttachment.self], inMemory: true)
}

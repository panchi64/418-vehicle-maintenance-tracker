//
//  MarkServiceDoneSheet.swift
//  checkpoint
//
//  Thin wrapper around `MarkServiceVisitDoneSheet` for single-service
//  completion. Kept as a separate type so existing presentation sites
//  (e.g. `ServiceDetailView`) compile unchanged.
//

import SwiftUI

struct MarkServiceDoneSheet: View {
    let service: Service
    let vehicle: Vehicle
    var onSaved: (() -> Void)? = nil

    var body: some View {
        MarkServiceVisitDoneSheet(
            origin: .singleService(service, vehicle),
            onSaved: onSaved
        )
    }
}

#Preview {
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
        .preferredColorScheme(.dark)
}

//
//  MarkClusterDoneSheet.swift
//  checkpoint
//
//  Thin wrapper around `MarkServiceVisitDoneSheet` for cluster (Service Visit)
//  completion. The old implementation divided the entered total by the number
//  of services and stored the divided value on each child log — the bug this
//  whole feature exists to fix. The honest path now lives in
//  `MarkServiceVisitDoneSheet.saveCluster(...)`.
//

import SwiftData
import SwiftUI

struct MarkClusterDoneSheet: View {
    let cluster: ServiceCluster
    var onSaved: (() -> Void)? = nil

    var body: some View {
        MarkServiceVisitDoneSheet(
            origin: .cluster(cluster),
            onSaved: onSaved
        )
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)
    let cluster = ServiceCluster(
        services: Array(services.prefix(3)),
        anchorService: services[0],
        vehicle: vehicle,
        mileageWindow: 1000,
        daysWindow: 30
    )

    return MarkClusterDoneSheet(cluster: cluster)
        .environment(AppState())
        .modelContainer(for: [Vehicle.self, Service.self, ServiceLog.self, ServiceVisit.self, VisitLineItem.self, MileageSnapshot.self, ServiceAttachment.self], inMemory: true)
        .preferredColorScheme(.dark)
}

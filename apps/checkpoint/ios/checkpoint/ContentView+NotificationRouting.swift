//
//  ContentView+NotificationRouting.swift
//  checkpoint
//
//  View-side pieces of notification routing. The navigation itself is
//  `AppState.apply(_:vehicles:)`.
//

import SwiftUI

extension ContentView {

    /// One service completes on its own; several complete as one visit.
    func markDoneOrigin(for request: MarkDoneRequest) -> MarkServiceVisitDoneSheet.Origin {
        guard request.services.count > 1 else {
            return .singleService(request.services[0], request.vehicle)
        }
        let settings = ClusteringSettings.shared
        let ordered = request.services.sortedByUrgency(request.vehicle.mileageEstimate)
        return .cluster(ServiceCluster(
            services: ordered,
            anchorService: ordered[0],
            vehicle: request.vehicle,
            mileageWindow: settings.mileageWindow,
            daysWindow: settings.daysWindow
        ))
    }
}

import Foundation

extension Array where Element == ServiceLog {
    func forVehicle(_ vehicle: Vehicle) -> [ServiceLog] {
        filter { $0.vehicle?.id == vehicle.id }
    }

    func forVehicleNewestFirst(_ vehicle: Vehicle) -> [ServiceLog] {
        forVehicle(vehicle).sorted { $0.performedDate > $1.performedDate }
    }

    func matching(serviceName: String, vehicle: Vehicle) -> [ServiceLog] {
        let needle = serviceName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return [] }
        return forVehicleNewestFirst(vehicle).filter { ($0.service?.name ?? "").lowercased() == needle }
    }

    func mostRecent(serviceName: String, vehicle: Vehicle) -> ServiceLog? {
        matching(serviceName: serviceName, vehicle: vehicle).first
    }

    func medianCost(serviceName: String, vehicle: Vehicle) -> Decimal? {
        let costs = matching(serviceName: serviceName, vehicle: vehicle).compactMap { $0.cost }.sorted()
        guard !costs.isEmpty else { return nil }
        let mid = costs.count / 2
        return costs.count.isMultiple(of: 2) ? (costs[mid - 1] + costs[mid]) / 2 : costs[mid]
    }

    func maxMileage(vehicle: Vehicle) -> Int? {
        forVehicle(vehicle).map(\.mileageAtService).max()
    }
}

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

    /// Top quick-tap chips above the service-type picker. Ranks by this
    /// vehicle's frequency when 3+ prior logs exist; otherwise falls back
    /// to a curated starter set so first-time users still get a fast path.
    func topPresetChips(
        for vehicle: Vehicle,
        from presets: [PresetData],
        limit: Int = 4
    ) -> [PresetData] {
        let presetsByName = Dictionary(uniqueKeysWithValues: presets.map { ($0.name.lowercased(), $0) })
        let usedNames = forVehicle(vehicle).compactMap { $0.service?.name.lowercased() }
        var chips: [PresetData] = []
        var seen: Set<String> = []

        if usedNames.count >= 3 {
            var frequency: [String: Int] = [:]
            for name in usedNames { frequency[name, default: 0] += 1 }
            for name in frequency.sorted(by: { $0.value > $1.value }).map(\.key) {
                guard let preset = presetsByName[name], !seen.contains(name) else { continue }
                chips.append(preset)
                seen.insert(name)
                if chips.count >= limit { break }
            }
        }

        for starter in Self.defaultStarterChipNames where chips.count < limit {
            guard let preset = presetsByName[starter], !seen.contains(starter) else { continue }
            chips.append(preset)
            seen.insert(starter)
        }

        return chips
    }

    private static let defaultStarterChipNames: [String] = [
        "oil change", "tire rotation", "brake service", "inspection"
    ]
}

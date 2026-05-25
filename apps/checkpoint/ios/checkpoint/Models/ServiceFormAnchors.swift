import Foundation

/// Derived hints and sanity warnings shared by the Record Service and
/// Edit Service Log forms. Computed from a vehicle's log history; when
/// the form is editing an existing log, that log's ID can be excluded
/// so the entry never compares against itself.
struct ServiceFormAnchors {
    let priorCostHint: String?
    let mileageWarning: String?
    let costWarning: String?

    init(
        vehicle: Vehicle,
        logs: [ServiceLog],
        serviceName: String,
        performedDate: Date,
        enteredMileage: Int?,
        enteredCostString: String,
        excludingLogID: UUID? = nil
    ) {
        let pool = excludingLogID.map { id in logs.filter { $0.id != id } } ?? logs

        if let mostRecent = pool.mostRecent(serviceName: serviceName, vehicle: vehicle),
           let cost = mostRecent.cost {
            let amount = Formatters.currencyWhole(cost)
            let date = Formatters.shortDate.string(from: mostRecent.performedDate)
            self.priorCostHint = "LAST TIME: \(amount) · \(date.uppercased())"
        } else {
            self.priorCostHint = nil
        }

        self.mileageWarning = ServiceFormValidation.mileageWarning(
            entered: enteredMileage,
            vehicleCurrentMileage: vehicle.currentMileage,
            maxLoggedMileage: pool.maxMileage(vehicle: vehicle),
            performedDate: performedDate
        )

        self.costWarning = ServiceFormValidation.costWarning(
            enteredCost: Decimal(string: enteredCostString),
            medianHistoricalCost: pool.medianCost(serviceName: serviceName, vehicle: vehicle),
            serviceName: serviceName
        )
    }
}

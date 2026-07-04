import Foundation

/// Soft, non-blocking sanity checks for the Record Service flow. Warnings
/// never prevent saving — they just nudge users to double-check before
/// a fat-finger value poisons trend analysis.
enum ServiceFormValidation {
    /// Recency window inside which a mileage below the highest prior entry
    /// is treated as a likely typo. Outside this window we assume backfill.
    static let recencyWindow: TimeInterval = 60 * 24 * 60 * 60

    /// Cost multiplier above the historical median that trips the cost warning.
    static let costAnomalyFactor: Decimal = 5

    /// Above this many miles over the vehicle's current odometer, treat as a typo.
    static let implausibleMileageJump = 50_000

    static func mileageWarning(
        entered: Int?,
        vehicleCurrentMileage: Int,
        maxLoggedMileage: Int?,
        performedDate: Date,
        now: Date = Date()
    ) -> String? {
        guard let entered, entered >= 0 else { return nil }

        let isRecentEntry = abs(performedDate.timeIntervalSince(now)) < recencyWindow
        if isRecentEntry, let maxLogged = maxLoggedMileage, entered < maxLogged {
            return "Lower than your last logged mileage (\(maxLogged.formatted()) on this vehicle). Typo?"
        }

        // A zero current mileage means the odometer was never set — the first
        // real reading is not a typo, however large.
        let jump = entered - vehicleCurrentMileage
        if vehicleCurrentMileage > 0, jump > implausibleMileageJump {
            return "That's \(jump.formatted()) above this vehicle's current mileage — typo?"
        }

        return nil
    }

    static func costWarning(
        enteredCost: Decimal?,
        medianHistoricalCost: Decimal?,
        serviceName: String
    ) -> String? {
        guard let entered = enteredCost, let median = medianHistoricalCost, median > 0 else { return nil }
        if entered > median * costAnomalyFactor {
            return "Much higher than past \(serviceName.lowercased()) entries. Typo?"
        }
        return nil
    }
}

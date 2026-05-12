import Foundation

/// Carry-forward fields for "Use last entry". Date and attachments are
/// intentionally excluded — date stays today, attachments are per-event.
struct LoggedServiceTemplate: Equatable {
    let serviceName: String
    let cost: Decimal?
    let costCategory: CostCategory?
    let notes: String?
    let intervalMonths: Int?
    let intervalMiles: Int?

    var hasRecurringIntervals: Bool {
        Service.hasIntervalPolicy(intervalMonths: intervalMonths, intervalMiles: intervalMiles)
    }

    init(from log: ServiceLog) {
        self.serviceName = log.service?.name ?? ""
        self.cost = log.cost
        self.costCategory = log.costCategory
        self.notes = log.notes
        self.intervalMonths = log.service?.intervalMonths
        self.intervalMiles = log.service?.intervalMiles
    }

    var costString: String {
        guard let cost else { return "" }
        return Self.formatter.string(from: cost as NSDecimalNumber) ?? "\(cost)"
    }

    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = false
        return f
    }()
}

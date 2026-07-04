import Foundation

struct FuzzyDateChip: Hashable {
    let label: String
    let date: Date
}

struct MonthIntervalChip: Hashable {
    let months: Int
    let label: String
}

/// Used for both recurrence-cadence chips and one-shot offset-from-current
/// chips — the shape is identical; the meaning is set by the call site.
struct MileageChip: Hashable {
    let miles: Int
    let label: String
}

enum ServiceFormChips {
    /// Time-dependent — recomputed each access so dates anchor to "now."
    static var fuzzyDateChips: [FuzzyDateChip] {
        let cal = Calendar.current
        let now = Date.now
        return [
            FuzzyDateChip(label: "Next Week", date: cal.date(byAdding: .day, value: 7, to: now) ?? now),
            FuzzyDateChip(label: "~1 mo", date: cal.date(byAdding: .month, value: 1, to: now) ?? now),
            FuzzyDateChip(label: "~3 mo", date: cal.date(byAdding: .month, value: 3, to: now) ?? now),
            FuzzyDateChip(label: "~6 mo", date: cal.date(byAdding: .month, value: 6, to: now) ?? now)
        ]
    }

    static let monthIntervalChips: [MonthIntervalChip] = [
        MonthIntervalChip(months: 3, label: "3 mo"),
        MonthIntervalChip(months: 6, label: "6 mo"),
        MonthIntervalChip(months: 12, label: "1 yr"),
        MonthIntervalChip(months: 24, label: "2 yr")
    ]

    static let mileageIntervalChips: [MileageChip] = [
        MileageChip(miles: 3000, label: "+3k"),
        MileageChip(miles: 5000, label: "+5k"),
        MileageChip(miles: 7500, label: "+7.5k"),
        MileageChip(miles: 10000, label: "+10k")
    ]

    static let mileageOffsetChips: [MileageChip] = [
        MileageChip(miles: 1000, label: "+1k"),
        MileageChip(miles: 3000, label: "+3k"),
        MileageChip(miles: 5000, label: "+5k"),
        MileageChip(miles: 10000, label: "+10k")
    ]
}

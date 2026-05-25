import Foundation

/// Carries a just-recorded service's anchors into a fresh remind-mode form so
/// the "SCHEDULE NEXT" toast action can open a reminder pre-populated with
/// the completion's service type and mileage as a starting point.
struct PostRecordPrefill {
    let serviceName: String
    let performedDate: Date
    let performedMileage: Int
    let intervalMonths: Int?
    let intervalMiles: Int?
}

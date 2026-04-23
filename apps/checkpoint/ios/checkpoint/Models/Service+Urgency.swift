//
//  Service+Urgency.swift
//  checkpoint
//
//  Urgency scoring and due date prediction
//

import Foundation

extension Service {
    /// Returns urgency score for sorting (lower = more urgent)
    /// - Parameters:
    ///   - currentMileage: Current vehicle mileage
    ///   - currentDate: Current date (defaults to now)
    ///   - dailyPace: Optional daily driving pace in miles; falls back to 40 mi/day if not provided
    func urgencyScore(currentMileage: Int, currentDate: Date = .now, dailyPace: Double? = nil) -> Int {
        var score = Int.max

        // Date-based urgency
        if let dueDate = dueDate {
            let days = Calendar.current.dateComponents([.day], from: currentDate, to: dueDate).day ?? Int.max
            score = min(score, days)
        }

        // Mileage-based urgency (use actual pace or default 40 miles/day)
        if let dueMileage = dueMileage {
            let milesRemaining = dueMileage - currentMileage
            let effectivePace = dailyPace ?? 40.0
            let daysEquivalent = Int(Double(milesRemaining) / effectivePace)
            score = min(score, daysEquivalent)
        }

        return score
    }

    /// Predict when mileage threshold will be reached based on driving pace
    /// - Parameters:
    ///   - currentMileage: Current vehicle mileage
    ///   - dailyPace: Daily driving pace in miles
    /// - Returns: Predicted date when due mileage will be reached, or nil if not applicable
    func predictedDueDate(currentMileage: Int, dailyPace: Double?) -> Date? {
        guard let pace = dailyPace, pace > 0,
              let dueMileage = dueMileage else { return nil }

        let milesRemaining = dueMileage - currentMileage
        guard milesRemaining > 0 else { return nil }

        let daysUntilDue = Int(ceil(Double(milesRemaining) / pace))
        return Calendar.current.date(byAdding: .day, value: daysUntilDue, to: .now)
    }

    /// Returns the earlier of due date or predicted mileage date
    /// - Parameters:
    ///   - currentMileage: Current vehicle mileage
    ///   - dailyPace: Daily driving pace in miles
    /// - Returns: The effective due date (whichever comes first), or nil if neither is set
    func effectiveDueDate(currentMileage: Int, dailyPace: Double?) -> Date? {
        let calendarDate = dueDate
        let predictedDate = predictedDueDate(currentMileage: currentMileage, dailyPace: dailyPace)

        switch (calendarDate, predictedDate) {
        case (nil, nil): return nil
        case (let date?, nil): return date
        case (nil, let predicted?): return predicted
        case (let date?, let predicted?): return min(date, predicted)
        }
    }
}

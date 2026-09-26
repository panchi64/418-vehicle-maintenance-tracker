//
//  MileageReadingCheck.swift
//  checkpoint
//
//  Whether an odometer reading someone *said* — to Siri, with no form to
//  look at — is believable enough to save without asking.
//
//  A spoken reading is an authoritative statement about the present, like
//  typing it in the mileage sheet, so it is recorded directly
//  (`MileageUpdateAction`) rather than gated like a side-effect reading
//  (`MileageCommit`). But speech recognition drops and adds digits, and there
//  is no screen showing the number back. Two readings earn a confirmation:
//
//    - **Lower than the reading on file.** Usually a mishearing; sometimes a
//      real correction of an earlier over-entry, which is why it is asked
//      rather than refused.
//    - **An unusual jump.** More than the vehicle could plausibly have driven
//      since the last reading: twice its own pace (or a heavy-driving floor of
//      150 mi/day when that is higher, or when there is no pace yet) for every
//      day since, and never less than 1,000 mi. "45,200" heard as "452,000"
//      trips it; a month of commuting doesn't.
//
//  A vehicle with no reading yet has nothing to compare against, so its first
//  reading is always plausible.
//

import Foundation

enum MileageReadingCheck: Equatable {
    case plausible
    /// The reading is below `current`, the odometer on file.
    case lowerThanCurrent(current: Int)
    /// The reading is `increase` miles past `current`, more than `allowance`.
    case unusualJump(current: Int, increase: Int, allowance: Int)

    /// Miles per day a vehicle with no pace history is assumed able to cover.
    static let heavyDailyMiles = 150.0
    /// The smallest increase ever questioned, however recent the last reading.
    static let minimumAllowance = 1_000

    static func evaluate(reading: Int, for vehicle: Vehicle, now: Date = .now) -> MileageReadingCheck {
        evaluate(
            reading: reading,
            current: vehicle.currentMileage,
            lastRecordedAt: vehicle.mileageUpdatedAt,
            dailyPace: vehicle.dailyMilesPace,
            now: now
        )
    }

    /// Pure form, for tests and for callers that already hold the values.
    static func evaluate(
        reading: Int,
        current: Int,
        lastRecordedAt: Date?,
        dailyPace: Double?,
        now: Date = .now
    ) -> MileageReadingCheck {
        guard let lastRecordedAt, current > 0 else { return .plausible }
        if reading < current { return .lowerThanCurrent(current: current) }

        let allowed = allowance(since: lastRecordedAt, dailyPace: dailyPace, now: now)
        let increase = reading - current
        return increase > allowed
            ? .unusualJump(current: current, increase: increase, allowance: allowed)
            : .plausible
    }

    /// The most the odometer is expected to have moved since `lastRecordedAt`.
    static func allowance(since lastRecordedAt: Date, dailyPace: Double?, now: Date = .now) -> Int {
        let seconds = max(now.timeIntervalSince(lastRecordedAt), 0)
        // At least one day, so a second reading on the same day still gets a
        // day's driving.
        let days = max(seconds / 86_400, 1)
        let perDay = max((dailyPace ?? 0) * 2, heavyDailyMiles)
        return max(Int((days * perDay).rounded(.up)), minimumAllowance)
    }

    var needsConfirmation: Bool { self != .plausible }
}

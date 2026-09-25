//
//  TipPromptContent.swift
//  checkpoint
//
//  The rotating message shown in the tip modal.
//

import Foundation

/// Builds personalized messages grounded in genuinely useful insights.
///
/// Design: Each message teaches the user something about their vehicle
/// or spending they might not have thought about — the kind of thing
/// a friend who's good with cars would point out. The ask at the end
/// is human and grateful, never transactional.
struct TipPromptContent {
    let headline: String
    let body: String
    let closing: String?

    static func select(from stats: TipPromptStats) -> TipPromptContent {
        if stats.hasTippedBefore {
            return pickRandom(from: returningTipperCandidates(stats: stats))
        }
        return pickRandom(from: firstTimeCandidates(stats: stats))
    }

    private static func pickRandom(from candidates: [TipPromptContent]) -> TipPromptContent {
        candidates.randomElement() ?? fallback
    }

    // MARK: - First-Time Candidates

    private static func firstTimeCandidates(stats: TipPromptStats) -> [TipPromptContent] {
        // Short closing shown as tertiary caption below the body.
        let closing = L10n.tipPromptClosing
        var pool: [TipPromptContent] = []

        // Monthly spend
        if let monthly = stats.formattedMonthlySpend {
            pool.append(TipPromptContent(
                headline: L10n.tipPromptMonthlyHeadline(monthly),
                body: L10n.tipPromptMonthlyBody,
                closing: closing
            ))
        }

        // Average cost per service
        if let avg = stats.formattedAverageCost, stats.servicesLogged >= 3 {
            pool.append(TipPromptContent(
                headline: L10n.tipPromptAverageHeadline(avg),
                body: L10n.tipPromptAverageBody(stats.servicesLogged),
                closing: closing
            ))
        }

        // Upcoming due services
        if stats.dueSoonOrOverdueCount > 0, let next = stats.nextServiceName {
            pool.append(TipPromptContent(
                headline: L10n.tipPromptAttentionHeadline(stats.dueSoonOrOverdueCount),
                body: L10n.tipPromptAttentionBody(next),
                closing: closing
            ))
        }

        // Service tracking count
        if stats.servicesTracked >= 3 {
            pool.append(TipPromptContent(
                headline: L10n.tipPromptMonitoredHeadline(stats.servicesTracked),
                body: L10n.tipPromptMonitoredBody,
                closing: closing
            ))
        }

        // Deep history
        if let months = stats.monthsOfHistory, months >= 3, stats.servicesLogged >= 5 {
            pool.append(TipPromptContent(
                headline: L10n.tipPromptRecordsHeadline(months),
                body: L10n.tipPromptRecordsBody(stats.servicesLogged),
                closing: closing
            ))
        }

        // Total cost tracked
        if let total = stats.formattedTotalCost, stats.servicesLogged >= 3 {
            pool.append(TipPromptContent(
                headline: L10n.tipPromptTotalHeadline(total),
                body: L10n.tipPromptTotalBody,
                closing: closing
            ))
        }

        // Multi-vehicle
        if stats.vehicleCount > 1 {
            pool.append(TipPromptContent(
                headline: L10n.tipPromptVehiclesHeadline(stats.vehicleCount),
                body: L10n.tipPromptVehiclesBody,
                closing: closing
            ))
        }

        pool.append(fallback)
        return pool
    }

    // MARK: - Returning Tipper Candidates

    private static func returningTipperCandidates(stats: TipPromptStats) -> [TipPromptContent] {
        let closing = L10n.tipPromptClosingReturning
        var pool: [TipPromptContent] = []

        if let monthly = stats.formattedMonthlySpend {
            pool.append(TipPromptContent(
                headline: L10n.tipPromptMonthlyHeadline(monthly),
                body: L10n.tipPromptMonthlyBodyReturning,
                closing: closing
            ))
        }

        if stats.dueSoonOrOverdueCount > 0, let next = stats.nextServiceName {
            pool.append(TipPromptContent(
                headline: L10n.tipPromptComingUpHeadline(next.uppercased()),
                body: L10n.tipPromptComingUpBody,
                closing: closing
            ))
        }

        if let months = stats.monthsOfHistory, months >= 3 {
            pool.append(TipPromptContent(
                headline: L10n.tipPromptHistoryHeadline(months),
                body: L10n.tipPromptHistoryBody,
                closing: closing
            ))
        }

        pool.append(TipPromptContent(
            headline: L10n.tipPromptThanksHeadline,
            body: L10n.tipPromptThanksBody,
            closing: closing
        ))

        return pool
    }

    // MARK: - Fallback

    private static var fallback: TipPromptContent {
        TipPromptContent(
            headline: L10n.tipPromptFallbackHeadline,
            body: L10n.tipPromptFallbackBody,
            closing: L10n.tipPromptClosing
        )
    }
}

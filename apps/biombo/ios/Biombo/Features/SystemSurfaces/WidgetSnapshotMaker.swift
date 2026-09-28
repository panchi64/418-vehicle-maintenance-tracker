import Foundation

/// Puts the widgets' answers into words, in the app's language and unit
/// (PRODUCT.md §11): "Gasolina cerca" from `GasPick`, and each watched place
/// from the same news the watch list shows. Freshness moves onto the
/// device's clock: a glance stays current for as long as its answer had
/// left when the app wrote it.
struct WidgetSnapshotMaker {
    let unit: PriceUnit
    let locale: Locale

    /// Watched-place news are states the app refreshes on every change;
    /// without a refresh the widget stops vouching for them after this
    /// (*proposed*).
    nonisolated static let watchHold: TimeInterval = .hours(2)
    /// Lines a watched place shows at most, as a row's budget (§3).
    nonisolated static let lineCap = 3

    func make(digest: HomeDigest, overview: WatchOverview, gas: GasPick?, writtenAt: Date) -> WidgetSnapshot {
        WidgetSnapshot(
            writtenAt: writtenAt,
            isCrisis: digest.isCrisis,
            gas: gas.map { glance($0, now: digest.now, writtenAt: writtenAt) },
            watched: overview.statuses.map { status in
                glance(status, shared: overview.sharedWarnings, now: digest.now, writtenAt: writtenAt)
            }
        )
    }

    private func glance(_ pick: GasPick, now: Date, writtenAt: Date) -> GasGlance {
        let answer = pick.answer
        // In crisis a price only means "hay" (§6.5), so the word stands in for it.
        let value = (pick.isAvailability ? ReportKind.hasGas.word : answer.valueText(unit: unit, locale: locale)).string(in: locale)
        let distance = GlanceNumbers.distance(meters: pick.distance, locale: locale)
        let place = answer.place.barrio ?? answer.place.municipio
        let spoken = pick.isAvailability
            ? LocalizedStringResource("\(value) en \(answer.place.displayName), a \(distance).", comment: "Gas widget, VoiceOver in crisis: the status, the station, how far")
            : LocalizedStringResource("\(unit.perUnit(value)) en \(answer.place.displayName), a \(distance).", comment: "Gas widget, VoiceOver: the price per unit, the station, how far")
        return GasGlance(
            value: value,
            unit: pick.isAvailability ? nil : unit.suffix.string(in: locale),
            compact: pick.isAvailability ? value : unit.perUnit(value).string(in: locale),
            station: answer.place.displayName,
            whereLine: LocalizedStringResource("\(place) · \(distance)", comment: "Gas widget: the barrio or municipio, then the distance").string(in: locale),
            asOfClock: answer.asOf.islandClock(locale: locale),
            spoken: spoken.string(in: locale),
            freshUntil: Self.wallClock(pick.currentUntil, now: now, writtenAt: writtenAt, hold: Self.watchHold)
        )
    }

    private func glance(_ status: WatchStatus, shared: [OfficialNotice], now: Date, writtenAt: Date) -> WatchGlance {
        let news = shared.map(WatchNews.warning) + status.news
        return WatchGlance(
            id: status.place.id,
            name: status.place.name,
            whereLine: status.place.whereWords.string(in: locale),
            lines: news.prefix(Self.lineCap).map { item in
                GlanceLine(
                    symbol: item.symbol,
                    text: item.sentenceString(now: now, locale: locale),
                    source: item.trust(now: now).text(locale: locale).string(in: locale)
                )
            },
            normalLine: WatchSummary([status]).normalLabel.string(in: locale),
            freshUntil: writtenAt.addingTimeInterval(Self.watchHold)
        )
    }

    /// An expiry on the snapshot's clock, moved onto the device's: whatever
    /// time it had left then, counted from the write. No expiry (an official
    /// answer) holds for `hold`.
    nonisolated static func wallClock(_ until: Date?, now: Date, writtenAt: Date, hold: TimeInterval) -> Date {
        guard let until else { return writtenAt.addingTimeInterval(hold) }
        return writtenAt.addingTimeInterval(max(0, until.timeIntervalSince(now)))
    }
}

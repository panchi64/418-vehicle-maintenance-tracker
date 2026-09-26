//
//  ServiceLogging.swift
//  checkpoint
//
//  How a spoken "I did this" becomes history, by the same writers the app's
//  forms use:
//
//    - one service, no shop → `LoggedServiceWriter`, fed a `ServiceLogFormModel`
//      set up exactly as the [+] or Mark Done form would be. Matching a
//      tracked service, recurrence defaults from a preset or the service's
//      own cadence, and the odometer rule (F11) are the form's, not a copy.
//    - several services, or a shop or receipt line items → `ServiceVisitWriter`:
//      one visit, one total, a log per service, as "Mark all done" writes it.
//      A shop and line items only have somewhere to live on a visit.
//
//  Model mutation only. Intents commit through `IntentStore.commit`.
//

import Foundation
import SwiftData

@MainActor
enum ServiceLogging {

    /// What was said about the occasion. Everything is optional because
    /// nothing but the service is needed: the form's own defaults fill in
    /// the rest (today, the reading on file, no cost).
    struct Occasion {
        var date: Date?
        /// Stored miles. nil means the reading on file.
        var mileage: Int?
        var totalCost: Decimal?
        var shop: String?
        /// A receipt's printed lines: a breakdown of `totalCost`.
        var lineItems: [ReceiptLineItem] = []
        /// The receipt itself, attached to the entry.
        var attachments: [AttachmentPicker.AttachmentData] = []

        /// A blank shop name is no shop.
        var shopName: String? {
            let trimmed = shop?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return trimmed.isEmpty ? nil : trimmed
        }

        /// Whether the entry needs a visit to hold what was said: a shop, or
        /// a receipt's line items.
        var needsVisit: Bool {
            shopName != nil || !lineItems.isEmpty
        }
    }

    /// Mark a tracked service done.
    @discardableResult
    static func markDone(
        _ service: Service,
        on vehicle: Vehicle,
        occasion: Occasion,
        in context: ModelContext,
        now: Date = .now
    ) -> [ServiceLog] {
        if occasion.needsVisit {
            return visitLogs([.tracked(service)], on: vehicle, occasion: occasion, in: context, now: now)
        }
        let model = formModel(for: vehicle, mode: .complete(service), occasion: occasion, now: now)
        return [LoggedServiceWriter.save(model, completing: service, in: context).log]
    }

    /// Log performed services by name. A name matching a tracked service
    /// completes it; any other is recorded as new, recurring from here when
    /// it matches a preset with a cadence.
    @discardableResult
    static func log(
        _ names: [String],
        on vehicle: Vehicle,
        occasion: Occasion,
        in context: ModelContext,
        now: Date = .now
    ) -> [ServiceLog] {
        let names = distinct(names)
        guard !names.isEmpty else { return [] }
        let presets = PresetDataService.shared.loadPresets()

        if names.count == 1, !occasion.needsVisit {
            let model = formModel(for: vehicle, mode: .log, occasion: occasion, now: now)
            model.presets = presets
            model.choose(name: names[0])
            let target = trackedMatch(named: model.serviceName, on: vehicle, performedDate: model.performedDate)
            model.applyScheduleDefaults(preset: model.selectedPreset, match: target)
            return [LoggedServiceWriter.save(model, completing: target, in: context).log]
        }

        let timing = timing(for: occasion.date, now: now)
        let performedDate = timing.performedDate(explicit: occasion.date ?? now, now: now)
        let items: [ServiceVisitWriter.Item] = names.map { name in
            if let tracked = trackedMatch(named: name, on: vehicle, performedDate: performedDate) {
                return .tracked(tracked)
            }
            let preset = presets.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
            // Backfill never inherits a preset's cadence: it would spawn a
            // reminder for a service done long ago (see the form's
            // `applyScheduleDefaults`).
            let cadence = timing.isBackfill ? nil : preset
            return .new(
                name: preset?.name ?? name,
                intervalMonths: cadence?.defaultIntervalMonths,
                intervalMiles: cadence?.defaultIntervalMiles
            )
        }
        return visitLogs(items, on: vehicle, occasion: occasion, in: context, now: now)
    }

    // MARK: - Helpers

    /// Which form timing a spoken date means. A future date is not a log,
    /// so it counts as today.
    static func timing(for date: Date?, now: Date = .now, calendar: Calendar = .current) -> ServiceTiming {
        guard let date, date < now else { return .today }
        if calendar.isDate(date, inSameDayAs: now) { return .today }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return .yesterday
        }
        return .earlier
    }

    private static func formModel(
        for vehicle: Vehicle,
        mode: ServiceLogFormMode,
        occasion: Occasion,
        now: Date
    ) -> ServiceLogFormModel {
        let model = ServiceLogFormModel(vehicle: vehicle, mode: mode, timing: timing(for: occasion.date, now: now))
        if let date = occasion.date { model.customDate = date }
        if let mileage = occasion.mileage { model.mileageAtService = mileage }
        // `LoggedServiceWriter` parses the form's text field; `Decimal`'s
        // description is locale-independent, which `Decimal(string:)` reads.
        if let cost = occasion.totalCost { model.cost = "\(cost)" }
        model.pendingAttachments = occasion.attachments
        return model
    }

    private static func visitLogs(
        _ items: [ServiceVisitWriter.Item],
        on vehicle: Vehicle,
        occasion: Occasion,
        in context: ModelContext,
        now: Date
    ) -> [ServiceLog] {
        let timing = timing(for: occasion.date, now: now)
        let visit = ServiceVisitWriter.record(
            items,
            on: vehicle,
            details: ServiceVisitWriter.Details(
                performedDate: timing.performedDate(explicit: occasion.date ?? now, now: now),
                mileage: occasion.mileage ?? vehicle.currentMileage,
                totalCost: occasion.totalCost,
                shopName: occasion.shopName,
                lineItems: occasion.lineItems
            ),
            attachments: occasion.attachments,
            in: context
        )
        return visit.logs ?? []
    }

    private static func trackedMatch(named name: String, on vehicle: Vehicle, performedDate: Date) -> Service? {
        (vehicle.services ?? []).activeMatch(
            named: name,
            for: vehicle,
            performedDate: performedDate,
            logs: vehicle.serviceLogs ?? []
        )
    }

    /// The service names in what was said. Siri hands over "oil change and
    /// tire rotation" as one answer, so each entry is split on commas and
    /// on "and" / "y" / "&" / "+" — unless the whole entry is already the
    /// name of a service the vehicle has or a preset, which is kept intact.
    static func names(in spoken: [String], knownNames: Set<String>) -> [String] {
        let known = Set(knownNames.map { $0.lowercased() })
        let separators = #/\s*,\s*|\s+(?:and|y|&|\+)\s+/#.ignoresCase()
        let split = spoken.flatMap { entry -> [String] in
            let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !known.contains(trimmed.lowercased()) else { return [trimmed] }
            return trimmed.split(separator: separators).map(String.init)
        }
        return distinct(split)
    }

    /// Every name `names(in:knownNames:)` must not split: the vehicle's
    /// services and the preset catalog.
    static func knownNames(on vehicle: Vehicle) -> Set<String> {
        Set((vehicle.services ?? []).map(\.name) + PresetDataService.shared.loadPresets().map(\.name))
    }

    /// Trimmed, blank-free, first occurrence of each name (ignoring case).
    static func distinct(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return names.compactMap { raw in
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, seen.insert(name.lowercased()).inserted else { return nil }
            return name
        }
    }
}

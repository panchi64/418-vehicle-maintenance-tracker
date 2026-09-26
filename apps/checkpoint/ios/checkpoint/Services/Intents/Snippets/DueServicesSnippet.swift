//
//  DueServicesSnippet.swift
//  checkpoint
//
//  The interactive list under "what's due on my car?": the vehicle's most
//  urgent services, each due-soon or overdue one with a Done button that
//  logs it on the spot (today, the reading on file) — the snippet version of
//  the widget's Done button, except it writes directly instead of queueing.
//
//  A Readout (SURFACE_DOCTRINE): the most urgent service is the section's one
//  primary element — first in position and the only row set in the emphasis
//  weight. Status carries a word and a mark, never color alone (`StatusTag`).
//

import AppIntents
import SwiftData
import SwiftUI

/// Which services the list shows. Raw values are persisted by the system
/// while a snippet is on screen — never rename one.
nonisolated enum DueListScope: String, AppEnum {
    case upcoming
    case overdue

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Services Shown" }

    static var caseDisplayRepresentations: [DueListScope: DisplayRepresentation] {
        [.upcoming: "Upcoming", .overdue: "Overdue"]
    }
}

/// Renders the list. The system calls `perform` again after a Done button's
/// intent runs, so each pass re-reads the store and a completed service drops
/// out (or shows its next occurrence).
struct DueServicesSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Due Services"
    static let isDiscoverable = false

    /// How many services the snippet shows. The spoken answer covers the
    /// same ones, so the two never disagree.
    static let rowLimit = 3

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle")
    var vehicle: VehicleEntity

    @Parameter(title: "Services Shown")
    var scope: DueListScope

    init() {}

    init(vehicle: VehicleEntity, scope: DueListScope) {
        self.vehicle = vehicle
        self.scope = scope
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: container.mainContext)
        let rows = scope == .overdue ? DueServices.overdue(on: vehicle) : DueServices.upcoming(on: vehicle)
        return .result(view: DueServicesSnippetView(rows: Array(rows.prefix(Self.rowLimit))))
    }
}

/// The snippet's Done button: marks the service done with the defaults the
/// Mark Done form opens with. The tap is the confirmation.
struct MarkDoneFromSnippetIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Service Done"
    static let isDiscoverable = false

    @Dependency var container: ModelContainer

    @Parameter(title: "Service")
    var service: ServiceEntity

    init() {}

    init(service: ServiceEntity) {
        self.service = service
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let context = container.mainContext
        let service = try IntentStore.service(self.service, in: context)
        let vehicle = try IntentStore.vehicle(of: service)
        // Already closed from another tap or device: nothing left to do.
        guard service.hasDueTracking else { return .result() }
        ServiceLogging.markDone(service, on: vehicle, occasion: ServiceLogging.Occasion(), in: context)
        try IntentStore.commit(vehicle, in: context)
        return .result()
    }
}

struct DueServicesSnippetView: View {
    let rows: [DueServiceRow]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.listItem) {
            if rows.isEmpty {
                Text(L10n.siriSnippetNothingDue)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textSecondary)
            }
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Rectangle()
                        .fill(Theme.gridLine)
                        .frame(height: 1)
                }
                DueServiceSnippetRow(row: row, isPrimary: index == 0)
            }
        }
        .padding(Spacing.md)
    }
}

private struct DueServiceSnippetRow: View {
    let row: DueServiceRow
    let isPrimary: Bool

    private var offersDone: Bool {
        row.status == .overdue || row.status == .dueSoon
    }

    var body: some View {
        AdaptiveStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(row.name)
                    .font(isPrimary ? .brutalistBodyEmphasis : .brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                StatusTag(status: row.status)
                Text(row.due)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            }
            AdaptiveSpacer()
            if offersDone {
                Button(intent: MarkDoneFromSnippetIntent(service: row.service)) {
                    Label(L10n.siriSnippetDone, systemImage: "checkmark")
                        .font(.brutalistLabelBold)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(Theme.accent)
            }
        }
    }
}

//
//  CheckRecallsIntent.swift
//  checkpoint
//
//  "Any recalls on my car in Checkpoint?" Asks NHTSA (through the same
//  cached client Home uses) and answers with what Home would show — the
//  recalls not resolved or snoozed, park-it ones always (`RecallVisibility`)
//  — over a list of them. When some aren't planned yet, Siri offers to add
//  them as planned services, the recall sheet's "add as planned service":
//  one-off services named for the component, due in a week, and the recall
//  marked scheduled. "Not now" leaves everything as it was.
//

import AppIntents
import SwiftData
import SwiftUI

struct CheckRecallsIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Recalls"
    static let description = IntentDescription("Check a vehicle for open safety recalls from NHTSA, and add them as planned services")

    @Dependency var container: ModelContainer

    @Parameter(title: "Vehicle", description: "Leave empty for the vehicle Checkpoint is showing.")
    var vehicle: VehicleEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Check recalls on \(\.$vehicle)")
    }

    init() {}

    /// The client recalls are fetched through. Tests substitute a stub.
    @MainActor static var nhtsa: any NHTSAClient = NHTSAService.shared

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let context = container.mainContext
        let vehicle = try IntentStore.vehicle(for: self.vehicle, in: context)
        let recalls = try await Self.openRecalls(for: vehicle, in: context, using: Self.nhtsa)
        let name = vehicle.displayName
        let summary = Self.summary(recalls, vehicle: name)

        let unplanned = Self.unplanned(recalls, for: vehicle, in: context)
        guard !unplanned.isEmpty else {
            return .result(dialog: IntentDialog(stringLiteral: summary), view: Self.snippet(recalls, vehicle: vehicle, in: context))
        }

        let add = IntentChoiceOption(title: "Add as Planned")
        let choice = try await requestChoice(
            between: [add, IntentChoiceOption(title: "Not Now")],
            dialog: IntentDialog(stringLiteral: L10n.siriRecallsOfferPlan(summary: summary, count: unplanned.count))
        )
        guard choice == add else {
            return .result(dialog: IntentDialog(stringLiteral: L10n.siriRecallsNotPlanned), view: Self.snippet(recalls, vehicle: vehicle, in: context))
        }

        let added = try Self.plan(unplanned, on: vehicle, in: context)
        return .result(
            dialog: IntentDialog(stringLiteral: L10n.siriRecallsPlanned(count: added, vehicle: name)),
            view: Self.snippet(recalls, vehicle: vehicle, in: context)
        )
    }

    // MARK: - Steps (static, so tests can run them without Siri)

    /// The recalls Home would show for `vehicle`, newest first.
    @MainActor
    static func openRecalls(for vehicle: Vehicle, in context: ModelContext, using client: any NHTSAClient, now: Date = .now) async throws -> [RecallInfo] {
        guard !vehicle.make.isEmpty, !vehicle.model.isEmpty, vehicle.hasModelYear else {
            throw IntentError.recallsNeedIdentity
        }
        let all: [RecallInfo]
        do {
            all = try await client.fetchRecalls(make: vehicle.make, model: vehicle.model, year: vehicle.year)
        } catch {
            throw IntentError.recallsUnavailable
        }
        let acknowledgments = RecallAckStore(context: context).acknowledgments(for: vehicle.id)
        return RecallVisibility.visibleRecalls(from: all, acknowledgments: acknowledgments, now: now).sortedNewestFirst()
    }

    /// The open recalls not already marked scheduled.
    @MainActor
    static func unplanned(_ recalls: [RecallInfo], for vehicle: Vehicle, in context: ModelContext) -> [RecallInfo] {
        let acknowledgments = RecallAckStore(context: context).acknowledgments(for: vehicle.id)
        return recalls.filter { acknowledgments[$0.campaignNumber]?.status != .scheduled }
    }

    /// Add each recall as a planned service (skipping one the vehicle
    /// already tracks by that name) and mark it scheduled. Returns how many
    /// services were added.
    @MainActor
    @discardableResult
    static func plan(_ recalls: [RecallInfo], on vehicle: Vehicle, in context: ModelContext, now: Date = .now) throws -> Int {
        let store = RecallAckStore(context: context)
        var added = 0
        for recall in recalls {
            let request = ServiceScheduling.Request(dueDate: recall.plannedServiceDueDate(from: now))
            if case .added = ServiceScheduling.add(named: recall.plannedServiceName, to: vehicle, request: request, in: context, now: now) {
                added += 1
            }
            store.setStatus(.scheduled, vehicleID: vehicle.id, campaignNumber: recall.campaignNumber)
        }
        try IntentStore.commit(vehicle, in: context)
        return added
    }

    @MainActor
    static func summary(_ recalls: [RecallInfo], vehicle: String) -> String {
        let components = recalls.map { $0.component.localizedCapitalized }
        let sentence: String
        switch recalls.count {
        case 0: return L10n.siriRecallsNone(vehicle: vehicle)
        case 1: sentence = L10n.siriRecallsOne(vehicle: vehicle, component: components[0])
        default: sentence = L10n.siriRecallsMany(vehicle: vehicle, count: recalls.count, list: SpokenValue.list(components))
        }
        return recalls.contains(where: \.parkIt) ? L10n.siriRecallsParkIt(sentence) : sentence
    }

    @MainActor
    static func snippet(_ recalls: [RecallInfo], vehicle: Vehicle, in context: ModelContext) -> some View {
        let acknowledgments = RecallAckStore(context: context).acknowledgments(for: vehicle.id)
        return RecallsSnippetView(
            vehicleName: vehicle.displayName,
            rows: recalls.map {
                RecallsSnippetView.Row(
                    id: $0.campaignNumber,
                    component: $0.component.localizedCapitalized,
                    parkIt: $0.parkIt,
                    isPlanned: acknowledgments[$0.campaignNumber]?.status == .scheduled
                )
            }
        )
    }
}

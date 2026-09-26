//
//  VisualIntelligenceIntents.swift
//  checkpoint
//
//  Visual Intelligence (camera or screenshot) → "Log in Checkpoint".
//  Per Apple's "Integrating your app with visual intelligence":
//
//    - ONE `IntentValueQuery` over `SemanticContentDescriptor` (an app may
//      have only one) returns results as app entities —
//      `CheckpointVisualSearchQuery` → `VisualCaptureEntity`.
//    - Tapping a result runs the entity's `OpenIntent`
//      (`OpenVisualCaptureIntent`), which opens the app on the action.
//    - "More results" runs the `.visualIntelligence.semanticContentSearch`
//      schema intent (`ShowVisualSearchResultsIntent`). Xcode's snippet types
//      its parameter `VisualIntelligence.SceneDescriptor`, which does not
//      exist in the SDK; it is `SemanticContentDescriptor`.
//
//  Availability: `SemanticContentDescriptor` and the schema are iOS 26, and
//  Visual Intelligence only runs on Apple Intelligence hardware. The
//  Simulator SDK has no VisualIntelligence module at all, so the two types
//  that name it compile only where it exists (`canImport`); the entity, its
//  open intent and `VisualSearch` build everywhere and are unit-tested.
//

import AppIntents
import SwiftData
#if canImport(VisualIntelligence)
import VisualIntelligence
#endif

struct VisualCaptureEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Checkpoint Action")
    }

    static var defaultQuery: VisualCaptureEntityQuery { VisualCaptureEntityQuery() }

    let id: UUID
    let kind: VisualCaptureKind
    let title: String
    let subtitle: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(subtitle)",
            image: .init(systemName: kind.symbolName)
        )
    }

    @MainActor
    init(capture: VisualCapture, vehicleName: String) {
        id = capture.id
        kind = capture.kind
        switch capture.kind {
        case .receipt:
            title = L10n.visualLogReceipt
        case .odometer:
            title = L10n.visualUpdateMileage(SpokenValue.mileage(capture.reading ?? 0))
        case .vin:
            title = L10n.visualAddVehicle(capture.vin ?? "")
        }
        subtitle = capture.kind == .vin ? L10n.visualInCheckpoint : L10n.visualOnVehicle(vehicleName)
    }
}

extension VisualCaptureKind {
    var symbolName: String {
        switch self {
        case .receipt: return "doc.text.viewfinder"
        case .odometer: return "gauge.with.dots.needle.67percent"
        case .vin: return "car.badge.gearshape"
        }
    }
}

struct VisualCaptureEntityQuery: EntityQuery {
    @Dependency var container: ModelContainer

    func entities(for identifiers: [UUID]) async throws -> [VisualCaptureEntity] {
        try await VisualSearch.entities(ids: identifiers, in: container)
    }
}

/// Tapping a Visual Intelligence result.
struct OpenVisualCaptureIntent: OpenIntent {
    static let title: LocalizedStringResource = "Log in Checkpoint"
    static let isDiscoverable = false

    @Parameter(title: "Capture")
    var target: VisualCaptureEntity

    init() {}

    init(target: VisualCaptureEntity) {
        self.target = target
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try VisualSearch.open(target.id)
        return .result()
    }
}

#if canImport(VisualIntelligence)
/// The one value query Visual Intelligence calls.
struct CheckpointVisualSearchQuery: IntentValueQuery {
    @Dependency var container: ModelContainer

    func values(for input: SemanticContentDescriptor) async throws -> [VisualCaptureEntity] {
        try await VisualSearch.results(labels: input.labels, pixelBuffer: input.pixelBuffer, in: container)
    }
}

/// Visual Intelligence's "More results": open the most likely action.
@AppIntent(schema: .visualIntelligence.semanticContentSearch)
struct ShowVisualSearchResultsIntent {
    @Dependency var container: ModelContainer

    var semanticContent: SemanticContentDescriptor

    @MainActor
    func perform() async throws -> some IntentResult {
        let results = try await VisualSearch.results(
            labels: semanticContent.labels,
            pixelBuffer: semanticContent.pixelBuffer,
            in: container
        )
        if let first = results.first {
            try VisualSearch.open(first.id)
        }
        return .result()
    }
}
#endif

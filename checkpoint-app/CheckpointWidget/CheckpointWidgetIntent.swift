//
//  CheckpointWidgetIntent.swift
//  CheckpointWidget
//
//  Widget configuration intent for user-configurable display options
//

import AppIntents
import WidgetKit

// MARK: - Mileage Display Mode Enum

enum MileageDisplayMode: String, CaseIterable, AppEnum {
    case absolute = "absolute"
    case relative = "relative"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Mileage Display"
    }

    static var caseDisplayRepresentations: [MileageDisplayMode: DisplayRepresentation] {
        [
            .absolute: DisplayRepresentation(
                title: "Due Mileage",
                subtitle: "Show when service is due (e.g., 35,000 MI)"
            ),
            .relative: DisplayRepresentation(
                title: "Miles Remaining",
                subtitle: "Show miles until due (e.g., 500 MI)"
            )
        ]
    }
}

// MARK: - Widget Configuration Intent

struct CheckpointWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Checkpoint Widget"
    static var description = IntentDescription("Configure how mileage is displayed")

    @Parameter(title: "Mileage Display", default: .absolute)
    var mileageDisplayMode: MileageDisplayMode

    init() {
        self.mileageDisplayMode = .absolute
    }

    init(mileageDisplayMode: MileageDisplayMode) {
        self.mileageDisplayMode = mileageDisplayMode
    }
}

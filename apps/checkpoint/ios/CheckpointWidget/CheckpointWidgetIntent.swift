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

// MARK: - Distance Unit Option Enum

enum WidgetDistanceUnitOption: String, CaseIterable, AppEnum {
    case matchApp = "matchApp"
    case miles = "miles"
    case kilometers = "kilometers"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Distance Unit"
    }

    static var caseDisplayRepresentations: [WidgetDistanceUnitOption: DisplayRepresentation] {
        [
            .matchApp: DisplayRepresentation(
                title: "Match App",
                subtitle: "Use the distance unit from the app"
            ),
            .miles: DisplayRepresentation(
                title: "Miles",
                subtitle: "Always show miles (MI)"
            ),
            .kilometers: DisplayRepresentation(
                title: "Kilometers",
                subtitle: "Always show kilometers (KM)"
            )
        ]
    }

    /// Resolve to a concrete WidgetDistanceUnit
    func resolve() -> WidgetDistanceUnit {
        switch self {
        case .matchApp: return WidgetDistanceUnit.current()
        case .miles: return .miles
        case .kilometers: return .kilometers
        }
    }
}

// MARK: - Widget Configuration Intent

struct CheckpointWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Checkpoint Widget"
    static var description = IntentDescription("Configure which vehicle to display, how mileage is shown, and distance units")

    @Parameter(title: "Vehicle")
    var vehicle: VehicleEntity?

    @Parameter(title: "Mileage Display", default: .absolute)
    var mileageDisplayMode: MileageDisplayMode

    @Parameter(title: "Distance Unit", default: .matchApp)
    var distanceUnit: WidgetDistanceUnitOption

    init() {
        self.vehicle = nil
        self.mileageDisplayMode = .absolute
        self.distanceUnit = .matchApp
    }

    init(vehicle: VehicleEntity?, mileageDisplayMode: MileageDisplayMode, distanceUnit: WidgetDistanceUnitOption = .matchApp) {
        self.vehicle = vehicle
        self.mileageDisplayMode = mileageDisplayMode
        self.distanceUnit = distanceUnit
    }
}

//
//  CheckpointControls.swift
//  CheckpointWidget
//
//  Controls (iOS 18) for Control Center, the Lock Screen and the Action
//  button: Update Mileage, Scan Receipt and Log Service. Each is a button
//  that opens the app on that screen for the vehicle it's showing — an
//  `OpenIntent` (`OpenCheckpointScreenIntent`, Shared/PendingWidgetRoute.swift),
//  which is how Apple has a control open its app. Any control can be
//  assigned to the Action button; there is nothing extra to declare.
//
//  Buttons, not toggles: each opens a task that asks for input, and there is
//  no state to show.
//

import AppIntents
import SwiftUI
import WidgetKit

struct UpdateMileageControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        ScreenControl.configuration(
            kind: "com.418-studio.checkpoint.control.updateMileage",
            screen: .updateMileage,
            title: "Update Mileage",
            systemImage: "gauge.with.dots.needle.67percent",
            description: "Open Checkpoint to record the odometer on the vehicle it's showing."
        )
    }
}

struct ScanReceiptControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        ScreenControl.configuration(
            kind: "com.418-studio.checkpoint.control.scanReceipt",
            screen: .scanReceipt,
            title: "Scan Receipt",
            systemImage: "doc.text.viewfinder",
            description: "Open Checkpoint's receipt scanner to log a shop visit."
        )
    }
}

struct LogServiceControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        ScreenControl.configuration(
            kind: "com.418-studio.checkpoint.control.logService",
            screen: .logService,
            title: "Log Service",
            systemImage: "square.and.pencil",
            description: "Open Checkpoint to log a service on the vehicle it's showing."
        )
    }
}

/// The one shape all three controls share; each differs only in its screen,
/// words and symbol.
private enum ScreenControl {
    static func configuration(
        kind: String,
        screen: CheckpointScreen,
        title: LocalizedStringResource,
        systemImage: String,
        description: LocalizedStringResource
    ) -> some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind) {
            ControlWidgetButton(action: OpenCheckpointScreenIntent(target: screen)) {
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: systemImage)
                }
            }
        }
        .displayName(title)
        .description(description)
    }
}

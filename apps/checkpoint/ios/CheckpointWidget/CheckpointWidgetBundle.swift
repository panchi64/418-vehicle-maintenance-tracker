//
//  CheckpointWidgetBundle.swift
//  CheckpointWidget
//
//  Widget bundle entry point for Checkpoint: the widget, then the Controls
//  (their order here is their order in the controls gallery).
//

import WidgetKit
import SwiftUI

@main
struct CheckpointWidgetBundle: WidgetBundle {
    var body: some Widget {
        CheckpointWidget()
        UpdateMileageControl()
        ScanReceiptControl()
        LogServiceControl()
    }
}

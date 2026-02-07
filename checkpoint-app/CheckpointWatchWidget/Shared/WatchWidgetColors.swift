//
//  WatchWidgetColors.swift
//  CheckpointWatchWidget
//
//  Color tokens for Watch complications
//  Matches iOS widget and Watch app status colors
//

import SwiftUI

enum WatchWidgetColors {
    // Status (system colors for accessory tinting)
    static let statusOverdue = Color.red
    static let statusDueSoon = Color.yellow
    static let statusGood = Color.green
    static let statusNeutral = Color.gray

    // Accent
    static let accent = Color(red: 0.91, green: 0.608, blue: 0.235)

    // Borders
    static let borderWidth: CGFloat = 2
}

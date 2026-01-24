//
//  WidgetColors.swift
//  CheckpointWidget
//
//  Color definitions for the widget extension
//

import SwiftUI

enum WidgetColors {
    // MARK: - Backgrounds
    static let backgroundPrimary = Color(red: 0.071, green: 0.071, blue: 0.071)
    static let backgroundElevated = Color(red: 0.11, green: 0.11, blue: 0.11)

    // MARK: - Text
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let textTertiary = Color(white: 0.5)

    // MARK: - Accent
    static let accent = Color(red: 0.91, green: 0.608, blue: 0.235) // #E89B3C

    // MARK: - Status
    static let statusOverdue = Color(red: 0.92, green: 0.34, blue: 0.34)
    static let statusDueSoon = Color(red: 0.95, green: 0.77, blue: 0.25)
    static let statusGood = Color(red: 0.34, green: 0.78, blue: 0.47)
    static let statusNeutral = Color(white: 0.5)
}

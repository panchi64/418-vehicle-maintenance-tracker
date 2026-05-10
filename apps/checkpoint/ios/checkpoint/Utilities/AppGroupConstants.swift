//
//  AppGroupConstants.swift
//  checkpoint
//
//  Centralized App Group identifiers to avoid hardcoded strings
//

import Foundation

enum AppGroupConstants {
    /// App Group shared between the main iPhone app and its widget extension
    nonisolated static let iPhoneWidget = "group.com.418-studio.checkpoint.shared"

    /// App Group shared between the Watch app and its widget extension
    nonisolated static let watchApp = "group.com.418-studio.checkpoint.watch"

    /// Filesystem container URL for the iPhone↔widget App Group, or nil if entitlements
    /// don't grant access (e.g. test bundles).
    nonisolated static var iPhoneWidgetContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: iPhoneWidget)
    }
}

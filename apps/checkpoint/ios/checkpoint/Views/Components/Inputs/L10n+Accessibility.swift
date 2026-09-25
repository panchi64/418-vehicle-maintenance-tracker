//
//  L10n+Accessibility.swift
//  checkpoint
//
//  VoiceOver strings for form controls, attachments, and camera flows, plus
//  the camera-permission screen. Kept apart from `L10n.swift` so the
//  accessibility sweep doesn't collide with other edits to that file; keys are
//  prefixed `a11y.` / `camera.` in Localizable.xcstrings.
//

import Foundation

extension L10n {
    private static func a11y(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // MARK: - Generic

    static var a11yDate: String { a11y("a11y.date") }
    static var a11yExpanded: String { a11y("a11y.expanded") }
    static var a11yCollapsed: String { a11y("a11y.collapsed") }
    static var a11yScanWithCamera: String { a11y("a11y.scanWithCamera") }
    static var a11yDistanceUnit: String { a11y("a11y.distanceUnit") }

    /// "Error: <message>"
    static func a11yError(_ message: String) -> String {
        String(format: a11y("a11y.error"), message)
    }

    // MARK: - Dim Save (F2)

    static var a11ySaveUnavailable: String { a11y("a11y.saveUnavailable") }
    static var a11ySaveUnavailableHint: String { a11y("a11y.saveUnavailableHint") }

    // MARK: - Notes editor

    static var a11yFormatBold: String { a11y("a11y.format.bold") }
    static var a11yFormatBulletedList: String { a11y("a11y.format.bulletedList") }
    static var a11yFormatNumberedList: String { a11y("a11y.format.numberedList") }

    // MARK: - Attachments

    static var a11yPhotoAttachment: String { a11y("a11y.attachment.photo") }
    static var a11yPDFAttachment: String { a11y("a11y.attachment.pdf") }
    static var a11yFileAttachment: String { a11y("a11y.attachment.file") }
    static var a11yRemoveAttachment: String { a11y("a11y.attachment.remove") }

    /// "3 attachments". Also shown on screen, not only spoken.
    static func attachmentCount(_ count: Int) -> String {
        let template = count == 1
            ? a11y("a11y.attachment.count_singular")
            : a11y("a11y.attachment.count_plural")
        return String(format: template, count)
    }

    // MARK: - Vehicles

    /// "Options for <vehicle>"
    static func a11yVehicleOptions(_ vehicleName: String) -> String {
        String(format: a11y("a11y.vehicleOptions"), vehicleName)
    }

    // MARK: - Camera / OCR

    static var a11yCaptureOdometer: String { a11y("a11y.captureOdometer") }
    static var a11yDetectedMileage: String { a11y("a11y.detectedMileage") }
    static var a11yConfidenceHigh: String { a11y("a11y.confidence.high") }
    static var a11yConfidenceMedium: String { a11y("a11y.confidence.medium") }
    static var a11yConfidenceLow: String { a11y("a11y.confidence.low") }

    static var cameraCapture: String { a11y("camera.capture") }
    static var cameraAccessDeniedTitle: String { a11y("camera.accessDenied.title") }
    static var cameraAccessDeniedMessage: String { a11y("camera.accessDenied.message") }
    static var cameraAccessOpenSettings: String { a11y("camera.accessDenied.openSettings") }
}

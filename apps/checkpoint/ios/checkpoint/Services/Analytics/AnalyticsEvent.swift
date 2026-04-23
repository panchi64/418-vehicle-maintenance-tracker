//
//  AnalyticsEvent.swift
//  checkpoint
//
//  Type-safe analytics event definitions with associated properties
//

import Foundation

/// All trackable analytics events in Checkpoint.
/// Properties are categorical/boolean only — never raw values like costs, VINs, or vehicle names.
enum AnalyticsEvent {

    // MARK: - Screen Names

    enum ScreenName: String {
        case home
        case services
        case costs
        case settings
        case addVehicleBasics = "add_vehicle_basics"
        case addVehicleDetails = "add_vehicle_details"
        case addService = "add_service"
        case serviceDetail = "service_detail"
        case editService = "edit_service"
        case markServiceDone = "mark_service_done"
        case editVehicle = "edit_vehicle"
        case vehiclePicker = "vehicle_picker"
        case mileageUpdate = "mileage_update"
        case serviceLogDetail = "service_log_detail"
        case editServiceLog = "edit_service_log"
    }

    // MARK: - Tab Names

    enum TabName: String {
        case home
        case services
        case costs
    }

    // MARK: - Mileage Source

    enum MileageSource: String {
        case manual
        case ocr
        case quickUpdate = "quick_update"
    }

    // MARK: - OCR Type

    enum OCRType: String {
        case odometer
        case vin
    }

    // MARK: - App Lifecycle

    case appOpened
    case appBackgrounded
    case appSessionStart(vehicleCount: Int, serviceCount: Int)

    // MARK: - Navigation

    case tabSwitched(tab: TabName)
    case vehicleSwitched
    case settingsOpened

    // MARK: - Screen Views

    case screenViewed(screen: ScreenName)

    // MARK: - Vehicle

    case vehicleAdded(usedOCR: Bool, usedVINLookup: Bool, hasNickname: Bool)
    case vehicleEdited
    case vehicleDeleted

    // MARK: - Service Management

    case serviceScheduled(isPreset: Bool, category: String?, hasInterval: Bool)
    case serviceLogged(isPreset: Bool, category: String?, hasInterval: Bool)
    case serviceMarkedDone(hasCost: Bool, hasNotes: Bool, hasAttachments: Bool, attachmentCount: Int)
    case serviceEdited
    case serviceLogEdited(notesChanged: Bool, attachmentsAdded: Int)
    case serviceDeleted

    // MARK: - Mileage

    case mileageUpdated(source: MileageSource)
    case mileagePromptShown

    // MARK: - OCR

    case ocrAttempted(ocrType: OCRType)
    case ocrSucceeded(ocrType: OCRType)
    case ocrFailed(ocrType: OCRType)
    case ocrConfirmed(ocrType: OCRType, valueEdited: Bool)

    // MARK: - Costs Tab

    case costsPeriodChanged(period: String)
    case costsCategoryChanged(category: String)

    // MARK: - Services Tab

    case servicesFilterChanged(filter: String)
    case servicesViewModeChanged(mode: String)
    case servicesSearchUsed
    case serviceHistoryExported

    // MARK: - Settings

    case settingChanged(setting: String, enabled: Bool)
    case analyticsOptedOut
    case analyticsOptedIn

    // MARK: - Features

    case recallAlertShown(recallCount: Int)
    case serviceClusterTapped
    case serviceClusterMarkAllDone
    case notificationPermissionGranted
    case notificationPermissionDenied

    // MARK: - Monetization

    case paywallShown(trigger: String)
    case purchaseAttempted(product: String)
    case purchaseSucceeded(product: String)
    case purchaseFailed(product: String, error: String)
    case purchaseRestored(product: String)
    case tipModalShown(actionCount: Int, dismissCount: Int)
    case tipModalDismissed(dismissCount: Int)
    case themeUnlocked(themeID: String, tier: String)
    case themeActivated(themeID: String)
    case vehicleLimitReached(vehicleCount: Int)

    // MARK: - Onboarding

    case onboardingStarted
    case onboardingIntroSkipped
    case onboardingTourStarted
    case onboardingTourSkipped(atStep: Int)
    case onboardingTourCompleted
    case onboardingVINLookupUsed
    case onboardingManualEntry
    case onboardingSkippedGetStarted
    case onboardingICloudSync
    case onboardingCompleted

    // MARK: - Event Properties

    /// The PostHog event name string
    var name: String {
        switch self {
        case .appOpened: return "app_opened"
        case .appBackgrounded: return "app_backgrounded"
        case .appSessionStart: return "app_session_start"
        case .tabSwitched: return "tab_switched"
        case .vehicleSwitched: return "vehicle_switched"
        case .settingsOpened: return "settings_opened"
        case .screenViewed: return "$screen"
        case .vehicleAdded: return "vehicle_added"
        case .vehicleEdited: return "vehicle_edited"
        case .vehicleDeleted: return "vehicle_deleted"
        case .serviceScheduled: return "service_scheduled"
        case .serviceLogged: return "service_logged"
        case .serviceMarkedDone: return "service_marked_done"
        case .serviceEdited: return "service_edited"
        case .serviceLogEdited: return "service_log_edited"
        case .serviceDeleted: return "service_deleted"
        case .mileageUpdated: return "mileage_updated"
        case .mileagePromptShown: return "mileage_prompt_shown"
        case .ocrAttempted: return "ocr_attempted"
        case .ocrSucceeded: return "ocr_succeeded"
        case .ocrFailed: return "ocr_failed"
        case .ocrConfirmed: return "ocr_confirmed"
        case .costsPeriodChanged: return "costs_period_changed"
        case .costsCategoryChanged: return "costs_category_changed"
        case .servicesFilterChanged: return "services_filter_changed"
        case .servicesViewModeChanged: return "services_view_mode_changed"
        case .servicesSearchUsed: return "services_search_used"
        case .serviceHistoryExported: return "service_history_exported"
        case .settingChanged: return "setting_changed"
        case .analyticsOptedOut: return "analytics_opted_out"
        case .analyticsOptedIn: return "analytics_opted_in"
        case .recallAlertShown: return "recall_alert_shown"
        case .serviceClusterTapped: return "service_cluster_tapped"
        case .serviceClusterMarkAllDone: return "service_cluster_mark_all_done"
        case .notificationPermissionGranted: return "notification_permission_granted"
        case .notificationPermissionDenied: return "notification_permission_denied"
        case .paywallShown: return "paywall_shown"
        case .purchaseAttempted: return "purchase_attempted"
        case .purchaseSucceeded: return "purchase_succeeded"
        case .purchaseFailed: return "purchase_failed"
        case .purchaseRestored: return "purchase_restored"
        case .tipModalShown: return "tip_modal_shown"
        case .tipModalDismissed: return "tip_modal_dismissed"
        case .themeUnlocked: return "theme_unlocked"
        case .themeActivated: return "theme_activated"
        case .vehicleLimitReached: return "vehicle_limit_reached"
        case .onboardingStarted: return "onboarding_started"
        case .onboardingIntroSkipped: return "onboarding_intro_skipped"
        case .onboardingTourStarted: return "onboarding_tour_started"
        case .onboardingTourSkipped: return "onboarding_tour_skipped"
        case .onboardingTourCompleted: return "onboarding_tour_completed"
        case .onboardingVINLookupUsed: return "onboarding_vin_lookup_used"
        case .onboardingManualEntry: return "onboarding_manual_entry"
        case .onboardingSkippedGetStarted: return "onboarding_skipped_get_started"
        case .onboardingICloudSync: return "onboarding_icloud_sync"
        case .onboardingCompleted: return "onboarding_completed"
        }
    }

    /// Associated properties for the event (categorical/boolean only)
    var properties: [String: Any] {
        switch self {
        case .appSessionStart(let vehicleCount, let serviceCount):
            return ["vehicle_count": vehicleCount, "service_count": serviceCount]
        case .tabSwitched(let tab):
            return ["tab": tab.rawValue]
        case .screenViewed(let screen):
            return ["$screen_name": screen.rawValue]
        case .vehicleAdded(let usedOCR, let usedVINLookup, let hasNickname):
            return ["used_ocr": usedOCR, "used_vin_lookup": usedVINLookup, "has_nickname": hasNickname]
        case .serviceScheduled(let isPreset, let category, let hasInterval):
            var props: [String: Any] = ["is_preset": isPreset, "has_interval": hasInterval]
            if let category { props["category"] = category }
            return props
        case .serviceLogged(let isPreset, let category, let hasInterval):
            var props: [String: Any] = ["is_preset": isPreset, "has_interval": hasInterval]
            if let category { props["category"] = category }
            return props
        case .serviceMarkedDone(let hasCost, let hasNotes, let hasAttachments, let attachmentCount):
            return [
                "has_cost": hasCost,
                "has_notes": hasNotes,
                "has_attachments": hasAttachments,
                "attachment_count": attachmentCount
            ]
        case .serviceLogEdited(let notesChanged, let attachmentsAdded):
            return ["notes_changed": notesChanged, "attachments_added": attachmentsAdded]
        case .mileageUpdated(let source):
            return ["source": source.rawValue]
        case .ocrAttempted(let ocrType):
            return ["ocr_type": ocrType.rawValue]
        case .ocrSucceeded(let ocrType):
            return ["ocr_type": ocrType.rawValue]
        case .ocrFailed(let ocrType):
            return ["ocr_type": ocrType.rawValue]
        case .ocrConfirmed(let ocrType, let valueEdited):
            return ["ocr_type": ocrType.rawValue, "value_edited": valueEdited]
        case .costsPeriodChanged(let period):
            return ["period": period]
        case .costsCategoryChanged(let category):
            return ["category": category]
        case .servicesFilterChanged(let filter):
            return ["filter": filter]
        case .servicesViewModeChanged(let mode):
            return ["mode": mode]
        case .settingChanged(let setting, let enabled):
            return ["setting": setting, "enabled": enabled]
        case .recallAlertShown(let recallCount):
            return ["recall_count": recallCount]
        case .onboardingTourSkipped(let atStep):
            return ["at_step": atStep]
        case .paywallShown(let trigger):
            return ["trigger": trigger]
        case .purchaseAttempted(let product):
            return ["product": product]
        case .purchaseSucceeded(let product):
            return ["product": product]
        case .purchaseFailed(let product, let error):
            return ["product": product, "error": error]
        case .purchaseRestored(let product):
            return ["product": product]
        case .themeUnlocked(let themeID, let tier):
            return ["theme_id": themeID, "tier": tier]
        case .themeActivated(let themeID):
            return ["theme_id": themeID]
        case .tipModalShown(let actionCount, let dismissCount):
            return ["action_count": actionCount, "dismiss_count": dismissCount]
        case .tipModalDismissed(let dismissCount):
            return ["dismiss_count": dismissCount]
        case .vehicleLimitReached(let vehicleCount):
            return ["vehicle_count": vehicleCount]
        default:
            return [:]
        }
    }
}

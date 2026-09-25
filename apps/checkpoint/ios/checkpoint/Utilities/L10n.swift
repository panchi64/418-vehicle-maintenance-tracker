//
//  L10n.swift
//  checkpoint
//
//  Typed localization keys for accessing localized strings.
//  This file provides a type-safe way to access strings from Localizable.strings.
//

import Foundation

enum L10n {
    // MARK: - Common

    static var commonCancel: String { localized("common.cancel") }
    static var commonBack: String { localized("common.back") }
    static var commonNext: String { localized("common.next") }
    static var commonSave: String { localized("common.save") }
    static var commonUpdate: String { localized("common.update") }
    static var commonDone: String { localized("common.done") }
    static var commonDismiss: String { localized("common.dismiss") }
    static var commonDelete: String { localized("common.delete") }
    static var commonUndo: String { localized("common.undo") }
    static var commonViewAll: String { localized("common.viewAll") }

    // MARK: - Form Advisories
    //
    // VoiceOver prefixes for the FormAdvisory severity ladder. Sighted users
    // read severity from weight, enclosure, and color; these carry the same
    // distinction to screen readers, which would otherwise hear four
    // identical-sounding sentences.

    /// Stated before saving whenever a service reading will also advance the
    /// vehicle's odometer (F11). Two positional args: previous, then new.
    static func mileageAlsoUpdates(_ previous: String, _ updated: String) -> String {
        String(format: localized("mileage.alsoUpdates"), previous, updated)
    }

    // MARK: - List rows
    //
    // Rule 11: no display string built by concatenation. These replaced
    // hand-assembled strings like "\(days)D OVERDUE" and "LAST: \(time)",
    // which could not be translated and forced English word order.

    static func rowDistanceLeft(_ distance: String) -> String {
        String(format: localized("row.distanceLeft"), distance)
    }
    static func rowDistanceOverdue(_ distance: String) -> String {
        String(format: localized("row.distanceOverdue"), distance)
    }
    static var rowDueNow: String { localized("row.dueNow") }
    static var rowDueToday: String { localized("row.dueToday") }
    static var rowDueTomorrow: String { localized("row.dueTomorrow") }
    static func rowDaysLeft(_ days: Int) -> String {
        String(format: localized("row.daysLeft"), days)
    }
    static func rowDaysOverdue(_ days: Int) -> String {
        String(format: localized("row.daysOverdue"), days)
    }
    static var rowNoDueDate: String { localized("row.noDueDate") }
    static var rowViewDetailsHint: String { localized("row.viewDetailsHint") }
    static var rowServiceFallback: String { localized("row.serviceFallback") }
    static var headerOdometer: String { localized("header.odometer") }
    static var headerSpecs: String { localized("header.specs") }
    /// Navigation title when no vehicle is selected.
    static var headerSelectVehicleAccessibility: String { localized("header.selectVehicleAccessibility") }
    static var rowNoCostRecorded: String { localized("row.noCostRecorded") }
    static var rowNoTotalRecorded: String { localized("row.noTotalRecorded") }
    static var rowVisitTitle: String { localized("row.visitTitle") }
    static var rowVisitTag: String { localized("row.visitTag") }
    static func rowVisitTitleCount(_ count: Int) -> String {
        String(format: localized("row.visitTitleCount"), count)
    }
    static func rowCompletedAccessibility(_ name: String, _ date: String) -> String {
        String(format: localized("row.completedAccessibility"), name, date)
    }
    static func rowVisitAccessibility(_ date: String, _ count: Int) -> String {
        String(format: localized("row.visitAccessibility"), date, count)
    }

    // MARK: - Relative time

    /// Sentence-cased — stands alone as a value.
    static var timeSinceTodaySentence: String { localized("timeSince.todaySentence") }
    static var timeSinceYesterdaySentence: String { localized("timeSince.yesterdaySentence") }
    static var timeSinceOneMonthAgo: String { localized("timeSince.oneMonthAgo") }
    static func timeSinceDaysAgo(_ days: Int) -> String {
        String(format: localized("timeSince.daysAgo"), days)
    }
    static func timeSinceMonthsAgo(_ months: Int) -> String {
        String(format: localized("timeSince.monthsAgo"), months)
    }

    // MARK: - Filters and view modes
    //
    // Rule 10: enums that reach the UI expose `displayName`; `rawValue` stays
    // storage. These previously rendered their raw values directly, so the tab
    // chrome was unlocalizable and presentation was welded to persistence.

    static var costsExpenses: String { localized("costs.expenses") }
    static var homeUpcoming: String { localized("home.upcoming") }
    static var homeRecentActivity: String { localized("home.recentActivity") }
    static var servicesExport: String { localized("servicesTab.export") }
    static var servicesReference: String { localized("servicesTab.reference") }
    static var servicesDocumentLibrary: String { localized("servicesTab.documentLibrary") }

    static var categoryMaintenance: String { localized("category.maintenance") }
    static var categoryRepair: String { localized("category.repair") }
    static var categoryUpgrade: String { localized("category.upgrade") }

    static var advisoryBlocking: String { localized("advisory.a11yBlocking") }
    static var advisoryCaution: String { localized("advisory.a11yCaution") }
    static var advisoryDecision: String { localized("advisory.a11yDecision") }
    static var advisoryInfo: String { localized("advisory.a11yInfo") }

    // MARK: - Vehicle

    static var vehicleAdd: String { localized("vehicle.add") }
    static var vehicleDetails: String { localized("vehicle.details") }
    static var vehicleNickname: String { localized("vehicle.nickname") }
    static var vehicleMake: String { localized("vehicle.make") }
    static var vehicleModel: String { localized("vehicle.model") }
    static var vehicleYear: String { localized("vehicle.year") }
    static var vehicleMakePlaceholder: String { localized("vehicle.make_placeholder") }
    static var vehicleModelPlaceholder: String { localized("vehicle.model_placeholder") }
    static var vehicleYearPlaceholder: String { localized("vehicle.year_placeholder") }
    static var vehicleNicknamePlaceholder: String { localized("vehicle.nickname_placeholder") }
    static var vehicleOdometer: String { localized("vehicle.odometer") }
    static var vehicleOdometerRequired: String { localized("vehicle.odometerRequired") }
    static var vehicleIdentityRequired: String { localized("vehicle.identityRequired") }
    static var vehicleYearOutOfRange: String { localized("vehicle.yearOutOfRange") }
    static var vehicleNicknameEffect: String { localized("vehicle.nicknameEffect") }
    static var vehicleMarbete: String { localized("vehicle.marbete") }
    static var addVehicleScanVIN: String { localized("addvehicle.scanVIN") }
    static var addVehicleVINForbiddenLetters: String { localized("addvehicle.vinForbiddenLetters") }
    static func addVehicleVINCharactersRemaining(_ count: Int) -> String {
        String(format: localized("addvehicle.vinCharactersRemaining"), count)
    }
    static func stepOfTotal(_ step: Int, _ total: Int) -> String {
        String(format: localized("common.stepOfTotal"), step, total)
    }
    static var vehicleCurrentMileage: String { localized("vehicle.current_mileage") }
    static var vehicleMileagePlaceholder: String { localized("vehicle.mileage_placeholder") }
    static var vehicleVIN: String { localized("vehicle.vin") }
    static var vehicleVINPlaceholder: String { localized("vehicle.vin_placeholder") }
    static var vehicleVINHelp: String { localized("vehicle.vin_help") }
    static var vehicleSpecifications: String { localized("vehicle.specifications") }
    static var vehicleTireSize: String { localized("vehicle.tire_size") }
    static var vehicleTireSizePlaceholder: String { localized("vehicle.tire_size_placeholder") }
    static var vehicleOilType: String { localized("vehicle.oil_type") }
    static var vehicleOilTypePlaceholder: String { localized("vehicle.oil_type_placeholder") }
    static var vehicleNotes: String { localized("vehicle.notes") }
    static var vehicleNotesPlaceholder: String { localized("vehicle.notes_placeholder") }
    static var vehicleSave: String { localized("vehicle.save") }
    static var vehicleLicensePlate: String { localized("vehicle.license_plate") }
    static var vehicleMarbeteHelp: String { localized("vehicle.marbete_help") }
    static var vehicleMarbeteHelpLong: String { localized("vehicle.marbete_help_long") }
    static var vehicleMarbeteEffect: String { localized("vehicle.marbete_effect") }
    static var vehicleEditTitle: String { localized("vehicle.edit.title") }
    static var vehicleDeleteAction: String { localized("vehicle.delete.action") }
    static var vehicleDeleteConfirmTitle: String { localized("vehicle.delete.confirm_title") }
    static var vehicleDeleteConfirmMessage: String { localized("vehicle.delete.confirm_message") }
    static var vehicleDeleteConfirmMessageLast: String { localized("vehicle.delete.confirm_message_last") }

    // MARK: - Add Vehicle Flow

    static var addVehicleBasics: String { localized("addvehicle.basics") }
    static var addVehicleScanningVIN: String { localized("addvehicle.scanning_vin") }
    static var addVehicleScanningOdometer: String { localized("addvehicle.scanning_odometer") }
    static var addVehicleVINAlignGuide: String { localized("addvehicle.vin_align_guide") }
    static var addVehicleVINLookup: String { localized("addvehicle.vin_lookup") }
    static var addVehicleVINLookupLoading: String { localized("addvehicle.vin_lookup_loading") }
    static var addVehicleVINDetailsFilled: String { localized("addvehicle.vin_details_filled") }

    // MARK: - Settings

    static var settingsTitle: String { localized("settings.title") }
    static var settingsDisplay: String { localized("settings.display") }
    static var settingsReminders: String { localized("settings.reminders") }
    static var settingsSmartFeatures: String { localized("settings.smart_features") }
    static var settingsSafety: String { localized("settings.safety") }
    static var settingsPrivacy: String { localized("settings.privacy") }
    static var settingsDistanceUnit: String { localized("settings.distance_unit") }
    static var settingsMileageEstimation: String { localized("settings.mileage_estimation") }
    static var settingsMileageEstimationDesc: String { localized("settings.mileage_estimation_desc") }
    static var settingsDueSoonMileage: String { localized("settings.due_soon_mileage") }
    static var settingsDueSoonDays: String { localized("settings.due_soon_days") }
    static var settingsAutomaticIcon: String { localized("settings.automatic_icon") }
    static var settingsAutomaticIconDesc: String { localized("settings.automatic_icon_desc") }
    static var settingsBundleSuggestions: String { localized("settings.bundle_suggestions") }
    static var settingsBundleSuggestionsDesc: String { localized("settings.bundle_suggestions_desc") }
    static var settingsMileageWindow: String { localized("settings.mileage_window") }
    static var settingsDaysWindow: String { localized("settings.days_window") }
    static var settingsDaysWindowDesc: String { localized("settings.days_window_desc") }
    static var settingsMileageWindowDesc: String { localized("settings.mileage_window_desc") }
    static var settingsTheme: String { localized("settings.theme") }
    static var settingsThemeRareHint: String { localized("settings.theme_rare_hint") }
    static var settingsThemeUnlockInTipJar: String { localized("settings.theme_unlock_in_tip_jar") }
    static var settingsThemeLocked: String { localized("settings.theme_locked") }
    static var settingsThemeTierFree: String { localized("settings.theme_tier_free") }
    static var settingsThemeTierPro: String { localized("settings.theme_tier_pro") }
    static var settingsThemeTierRare: String { localized("settings.theme_tier_rare") }
    static var settingsClimateZone: String { localized("settings.climate_zone") }
    static var settingsClimateZoneDesc: String { localized("settings.climate_zone_desc") }
    static var settingsNotSet: String { localized("settings.not_set") }
    static var settingsSeasonalAlerts: String { localized("settings.seasonal_alerts") }
    static var settingsSeasonalAlertsDesc: String { localized("settings.seasonal_alerts_desc") }
    static var settingsDataSync: String { localized("settings.data_sync") }
    static var settingsImportHistory: String { localized("settings.import_history") }
    static var settingsSupport: String { localized("settings.support") }
    static var settingsReplayTour: String { localized("settings.replay_tour") }
    static var settingsReplayTourDesc: String { localized("settings.replay_tour_desc") }
    static var settingsRestorePurchases: String { localized("settings.restore_purchases") }
    static var settingsFindGasPrices: String { localized("settings.find_gas_prices") }
    static var settingsFindGasPricesDesc: String { localized("settings.find_gas_prices_desc") }
    static var settingsUsageAnalytics: String { localized("settings.usage_analytics") }
    static var settingsUsageAnalyticsDesc: String { localized("settings.usage_analytics_desc") }
    /// "30 days" — a threshold or window measured in days.
    static func settingsDaysCount(_ days: Int) -> String {
        String(format: localized("settings.days_count"), days)
    }
    /// "1,000 mi" — a threshold or window in the user's distance unit.
    static func settingsDistanceValue(_ value: Int) -> String {
        String(
            format: localized("settings.distance_value"),
            Formatters.mileageNumber(value),
            DistanceSettings.shared.unit.abbreviation
        )
    }

    // MARK: - iCloud Sync (Settings)

    static var syncSectionTitle: String { localized("sync.section_title") }
    static var syncToggleTitle: String { localized("sync.toggle_title") }
    static var syncToggleSubtitle: String { localized("sync.toggle_subtitle") }
    static var syncFooter: String { localized("sync.footer") }
    static func syncLastSynced(_ relative: String) -> String {
        String(format: localized("sync.last_synced"), relative)
    }

    // MARK: - Accessibility (shared)

    static var commonClose: String { localized("common.close") }
    /// VoiceOver value for a disclosure control's state.
    static var disclosureExpanded: String { localized("disclosure.expanded") }
    static var disclosureCollapsed: String { localized("disclosure.collapsed") }

    // MARK: - Distance Unit Picker

    static var distanceMilesDefault: String { localized("distance.miles_default") }
    static var distanceKilometersAbbr: String { localized("distance.kilometers_abbr") }
    static var distanceUnitTitle: String { localized("distance.unit_title") }

    // MARK: - Due Soon Threshold Pickers

    static var dueSoonMileageTitle: String { localized("duesoon.mileage_title") }
    static var dueSoonMileageDesc: String { localized("duesoon.mileage_desc") }
    static var dueSoonDaysTitle: String { localized("duesoon.days_title") }
    static var dueSoonDaysDesc: String { localized("duesoon.days_desc") }
    static var dueSoonDefault: String { localized("duesoon.default") }

    // MARK: - Toast Messages

    static var toastServiceLogged: String { localized("toast.service_logged") }
    static var toastVehicleSaved: String { localized("toast.vehicle_saved") }
    static var toastVehicleUpdated: String { localized("toast.vehicle_updated") }
    static var toastServiceRecorded: String { localized("toast.service_recorded") }
    static var toastReminderSet: String { localized("toast.reminder_set") }
    static var toastMileageUpdated: String { localized("toast.mileage_updated") }
    static var toastPDFReady: String { localized("toast.pdf_ready") }
    static var toastSyncError: String { localized("toast.sync_error") }
    static var toastServiceLogUpdated: String { localized("toast.service_log_updated") }
    static var toastServiceLogDeleted: String { localized("toast.service_log_deleted") }
    static var toastServiceUpdated: String { localized("toast.service_updated") }
    static func toastCopied(_ fieldLabel: String) -> String {
        String(format: localized("toast.copied"), fieldLabel)
    }
    static var toastScheduleNext: String { localized("toast.schedule_next") }

    // MARK: - OCR Errors

    static var ocrErrorNoTextFound: String { localized("ocr.error.no_text_found") }
    static var ocrErrorImageProcessingFailed: String { localized("ocr.error.image_processing_failed") }
    static var ocrErrorNoValidMileage: String { localized("ocr.error.no_valid_mileage") }
    static var ocrErrorInvalidMileage: String { localized("ocr.error.invalid_mileage") }
    static var ocrErrorNoValidVIN: String { localized("ocr.error.no_valid_vin") }

    // MARK: - Recall Alerts

    static func recallLastChecked(_ timeAgo: String) -> String {
        String(format: localized("recall.last_checked"), timeAgo)
    }

    // Severity bucket labels (sheet section headers + compact card label).
    static var recallSeverityDoNotDrive: String { localized("recall.severity.do_not_drive") }
    static var recallSeverityParkOutside: String { localized("recall.severity.park_outside") }
    static var recallSeverityOpen: String { localized("recall.severity.open") }

    // Sheet chrome.
    static var recallSheetTitleSingular: String { localized("recall.sheet.title_singular") }
    static func recallSheetTitlePlural(_ count: Int) -> String {
        String(format: localized("recall.sheet.title_plural"), count)
    }
    static var recallSectionResolved: String { localized("recall.section.resolved") }
    static var recallToggleShowResolved: String { localized("recall.toggle.show_resolved") }
    static var recallEmptyAllClear: String { localized("recall.empty.all_clear") }
    static var recallEmptyToggleHint: String { localized("recall.empty.toggle_hint") }

    // Per-recall actions.
    static func recallActionFindDealer(_ make: String) -> String {
        String(format: localized("recall.action.find_dealer"), make)
    }
    static var recallActionAddPlannedService: String { localized("recall.action.add_planned_service") }
    static var recallActionViewNHTSA: String { localized("recall.action.view_nhtsa") }
    static var recallActionMarkScheduled: String { localized("recall.action.mark_scheduled") }
    static var recallActionMarkResolved: String { localized("recall.action.mark_resolved") }
    static var recallActionReopen: String { localized("recall.action.reopen") }

    // Snooze menu.
    static var recallSnoozeMenuTitle: String { localized("recall.snooze.menu_title") }
    static var recallSnooze7Days: String { localized("recall.snooze.7_days") }
    static var recallSnooze30Days: String { localized("recall.snooze.30_days") }
    static var recallSnoozeDisabledParkIt: String { localized("recall.snooze.disabled_park_it") }

    // Status badges.
    static var recallStatusScheduled: String { localized("recall.status.scheduled") }
    static var recallStatusResolved: String { localized("recall.status.resolved") }

    // Pre-fill copy when sending a recall to AddServiceView.
    static func recallPlannedServiceName(_ component: String) -> String {
        String(format: localized("recall.planned_service_name"), component)
    }

    // Settings entry for re-opening the recall sheet.
    static var recallSettingsRowTitle: String { localized("recall.settings.row_title") }
    static var recallSettingsNoneOnFile: String { localized("recall.settings.none_on_file") }
    static func recallSettingsCount(_ count: Int) -> String {
        let template = count == 1 ? localized("recall.settings.count_singular") : localized("recall.settings.count_plural")
        return String(format: template, count)
    }

    // MARK: - Costs Tab

    static var costsRowOutlier: String { localized("costs.row.outlier") }

    static var costsEmptyStartTitle: String { localized("costs.empty.start.title") }
    static var costsEmptyStartMessage: String { localized("costs.empty.start.message") }
    static var costsEmptyNoneTitle: String { localized("costs.empty.none.title") }
    static var costsEmptyNoneMessage: String { localized("costs.empty.none.message") }

    static var costsShareSubject: String { localized("costs.share.subject") }

    // MARK: - Empty States

    static var emptyNoVehicleTitle: String { localized("empty.noVehicleTitle") }
    static var emptyNoVehicleMessage: String { localized("empty.noVehicleMessage") }

    // MARK: - Onboarding

    static var onboardingWelcomeTitle: String { localized("onboarding.welcome.title") }
    static var onboardingWelcomeSubtitle: String { localized("onboarding.welcome.subtitle") }
    static var onboardingSkip: String { localized("onboarding.skip") }
    static var onboardingSkipTour: String { localized("onboarding.skip_tour") }
    static var onboardingLetsLook: String { localized("onboarding.lets_look") }

    static var onboardingFeature1Title: String { localized("onboarding.feature1.title") }
    static var onboardingFeature1Body: String { localized("onboarding.feature1.body") }
    static var onboardingFeature2Title: String { localized("onboarding.feature2.title") }
    static var onboardingFeature2Body: String { localized("onboarding.feature2.body") }
    static var onboardingFeature3Title: String { localized("onboarding.feature3.title") }
    static var onboardingFeature3Body: String { localized("onboarding.feature3.body") }

    static var onboardingDistanceUnit: String { localized("onboarding.distance_unit") }

    static var onboardingTourDashboardTitle: String { localized("onboarding.tour.dashboard.title") }
    static var onboardingTourDashboardBody: String { localized("onboarding.tour.dashboard.body") }
    static var onboardingTourServicesTitle: String { localized("onboarding.tour.services.title") }
    static var onboardingTourServicesBody: String { localized("onboarding.tour.services.body") }
    static var onboardingTourCostsTitle: String { localized("onboarding.tour.costs.title") }
    static var onboardingTourCostsBody: String { localized("onboarding.tour.costs.body") }

    static func onboardingTourNextTo(_ destination: String) -> String {
        String(format: localized("onboarding.tour.next_to"), destination)
    }
    static func onboardingTourProgress(tab: String, step: Int, total: Int) -> String {
        String(format: localized("onboarding.tour.progress"), tab, step, total)
    }

    static var onboardingGetStartedTitle: String { localized("onboarding.getstarted.title") }
    static var onboardingGetStartedAddVehicle: String { localized("onboarding.getstarted.add_vehicle") }
    static var onboardingGetStartedUseICloud: String { localized("onboarding.getstarted.use_icloud") }
    static var onboardingGetStartedICloudHelp: String { localized("onboarding.getstarted.icloud_help") }
    static var onboardingGetStartedSkip: String { localized("onboarding.getstarted.skip") }

    // MARK: - Documents

    static var documentsTitle: String { localized("documents.title") }
    static var documentsAdd: String { localized("documents.add") }
    static var documentsEmptyTitle: String { localized("documents.empty.title") }
    static var documentsEmptyMessage: String { localized("documents.empty.message") }
    static var documentsEmptyAction: String { localized("documents.empty.action") }
    static var documentsSearchPlaceholder: String { localized("documents.search.placeholder") }
    static var documentsRowQuickSpecs: String { localized("documents.row.quick_specs") }
    static var documentsNotesLabel: String { localized("documents.notes.label") }
    static var documentsNotesPlaceholder: String { localized("documents.notes.placeholder") }
    static var documentsTypeLabel: String { localized("documents.type.label") }
    static var documentsFileNameRequired: String { localized("documents.fileNameRequired") }
    static var documentsLinkedVehiclesLabel: String { localized("documents.linked_vehicles.label") }
    static var documentsLinkedVehiclesEdit: String { localized("documents.linked_vehicles.edit") }
    static var documentsFromServiceLog: String { localized("documents.from_service_log") }
    static var documentsLinkToOtherVehicles: String { localized("documents.link_to_other_vehicles") }
    static func documentsLinkedCount(_ count: Int) -> String {
        String(format: localized("documents.linked_count"), count)
    }
    static func documentsDeleteBulkConfirmTitle(_ count: Int) -> String {
        String(format: localized("documents.delete.bulk_confirm_title"), count)
    }
    static var documentsDeleteBulkConfirmMessage: String { localized("documents.delete.bulk_confirm_message") }
    static var documentsDeleteAction: String { localized("documents.delete.action") }
    static var documentsDeleteError: String { localized("documents.delete.error") }
    static var documentsShareAction: String { localized("documents.share.action") }
    static func documentsShareCount(_ count: Int) -> String {
        String(format: localized("documents.share.count"), count)
    }
    static var documentsSelectAction: String { localized("documents.select.action") }
    static var documentsSelectionDoneAction: String { localized("documents.selection.done_action") }
    static var documentsRemoveLastVehicleConfirmTitle: String { localized("documents.remove_last_vehicle.confirm_title") }
    static var documentsRemoveLastVehicleConfirmMessage: String { localized("documents.remove_last_vehicle.confirm_message") }
    static var documentsSourceCamera: String { localized("documents.source.camera") }
    static var documentsSourcePhotos: String { localized("documents.source.photos") }
    static var documentsSourceFiles: String { localized("documents.source.files") }
    static var documentsExtractedTextLabel: String { localized("documents.extracted_text.label") }
    static var documentsMoreActions: String { localized("documents.more_actions") }
    static var documentsNoLinkedVehicles: String { localized("documents.no_linked_vehicles") }
    static var documentsOpenBadge: String { localized("documents.open_badge") }
    static var documentsOpenFullLabel: String { localized("documents.open_full.label") }
    static var documentsOpenFullHint: String { localized("documents.open_full.hint") }
    static var documentsServiceFallback: String { localized("documents.service_fallback") }
    static func documentsServiceLogSummary(_ serviceName: String, _ date: String) -> String {
        String(format: localized("documents.service_log_summary"), serviceName, date)
    }
    static func documentsDeleteCount(_ count: Int) -> String {
        String(format: localized("documents.delete_count"), count)
    }

    // MARK: - Service

    static var serviceDeleteConfirmMessage: String { localized("service.delete.confirm_message") }
    static var serviceDeleteConfirmTitle: String { localized("service.delete.confirm_title") }
    static var serviceDeleteAction: String { localized("service.delete.action") }
    static var serviceEditTitle: String { localized("service.edit.title") }
    static var serviceDetailsTitle: String { localized("service.details") }
    static var serviceNameLabel: String { localized("service.name") }
    static var serviceNamePlaceholder: String { localized("service.name_placeholder") }
    static var serviceFallbackName: String { localized("service.fallback_name") }

    // MARK: - Document Types

    static var documentTypeRegistration: String { localized("document.type.registration") }
    static var documentTypeInsurance: String { localized("document.type.insurance") }
    static var documentTypeTitle: String { localized("document.type.title") }
    static var documentTypeInspection: String { localized("document.type.inspection") }
    static var documentTypeWarranty: String { localized("document.type.warranty") }
    static var documentTypeManual: String { localized("document.type.manual") }
    static var documentTypeReceipt: String { localized("document.type.receipt") }
    static var documentTypeOther: String { localized("document.type.other") }

    // MARK: - Forms (shared)

    static var formDetails: String { localized("form.details") }
    static func formDetailsCount(_ count: Int) -> String {
        String(format: localized("form.detailsCount"), count)
    }
    static var formOptionalTag: String { localized("form.optionalTag") }
    static var formServiceTypeRequired: String { localized("form.serviceTypeRequired") }
    static var formVehicleBasicsRequired: String { localized("form.vehicleBasicsRequired") }
    static var formDraftResumeTitle: String { localized("form.draftResumeTitle") }
    static func formDraftFrom(_ relativeDate: String) -> String {
        String(format: localized("form.draftFrom"), relativeDate)
    }
    static var formDraftResume: String { localized("form.draftResume") }
    static var formDraftDiscard: String { localized("form.draftDiscard") }
    static var formDatePerformed: String { localized("form.datePerformed") }
    static var formCost: String { localized("form.cost") }
    static var formCategory: String { localized("form.category") }
    static var formMileage: String { localized("form.mileage") }
    static var formRemindNextTime: String { localized("form.remindNextTime") }
    static var formNotes: String { localized("form.notes") }
    static var formNotesPlaceholder: String { localized("form.notesPlaceholder") }
    static var formAttachments: String { localized("form.attachments") }
    static var formAddAttachments: String { localized("form.addAttachments") }
    static var formNextDue: String { localized("form.nextDue") }
    static var formSetDueDate: String { localized("form.setDueDate") }
    static var formDueDate: String { localized("form.dueDate") }
    static var formDueMileage: String { localized("form.dueMileage") }
    static var formUse: String { localized("form.use") }
    static var formRepeats: String { localized("form.repeats") }
    static var formRequiredTag: String { localized("form.requiredTag") }
    static var formRequiredAccessibility: String { localized("form.requiredAccessibility") }
    static var formRepeatAfterCompletion: String { localized("form.repeatAfterCompletion") }
    static var formEvery: String { localized("form.every") }
    static var formOrEvery: String { localized("form.orEvery") }
    static var formMonthsSuffix: String { localized("form.monthsSuffix") }

    // MARK: - Unified service form
    //
    // Titles and the rest of the form's newer strings: `L10n+Forms.swift`.

    static var timingToday: String { localized("timing.today") }
    static var timingYesterday: String { localized("timing.yesterday") }
    static var timingAtMileage: String { localized("timing.atMileage") }
    static var timingOnDate: String { localized("timing.onDate") }

    static var formWhen: String { localized("form.when") }
    static var formOdometerAtService: String { localized("form.odometerAtService") }
    static var formRemindMeAt: String { localized("form.remindMeAt") }
    static var formRemindMileageRequired: String { localized("form.remindMileageRequired") }
    static var formResolveOdometerConflict: String { localized("form.resolveOdometerConflict") }
    static func formOdometerContradiction(_ current: String) -> String {
        String(format: localized("form.odometerContradiction"), current)
    }
    static var formKeepMyOdometer: String { localized("form.keepMyOdometer") }
    static var formCorrectItUpward: String { localized("form.correctItUpward") }
    static func formOdometerStaysAt(_ current: String) -> String {
        String(format: localized("form.odometerStaysAt"), current)
    }

    // Logging a service already on the schedule completes it.
    static func formCompletesService(_ name: String) -> String {
        String(format: localized("form.completesService"), name)
    }
    static func formCompletesServiceWithStatus(_ name: String, _ status: String) -> String {
        String(format: localized("form.completesServiceWithStatus"), name, status)
    }

    // The estimate is a hint, never the prefilled reading.
    static func markDoneEstimateHint(_ mileage: String) -> String {
        String(format: localized("markDone.estimateHint"), mileage)
    }
    static var formFires: String { localized("form.fires") }
    static var formFiresOnceYouEnterMileage: String { localized("form.firesOnceYouEnterMileage") }
    static var formFiresOnceYouPickDate: String { localized("form.firesOnceYouPickDate") }
    static func formFiresAtMileage(_ mileage: String) -> String {
        String(format: localized("form.firesAtMileage"), mileage)
    }
    static func formFiresAtMileageInDays(_ mileage: String, _ days: Int) -> String {
        String(format: localized("form.firesAtMileageInDays"), mileage, days)
    }
    static var formMoreDetails: String { localized("form.moreDetails") }
    static var formFewerDetails: String { localized("form.fewerDetails") }
    static var tabBarAddService: String { localized("tabBar.addService") }
    static var tabHome: String { localized("tab.home") }
    static var tabServices: String { localized("tab.services") }
    static var tabCosts: String { localized("tab.costs") }
    static var navManageVehicles: String { localized("nav.manageVehicles") }
    static var servicesSearchPrompt: String { localized("servicesTab.searchPrompt") }
    static func toastReminderSetFor(_ date: String) -> String {
        String(format: localized("toast.reminderSetFor"), date)
    }
    static func toastReminderSetAt(_ mileage: String) -> String {
        String(format: localized("toast.reminderSetAt"), mileage)
    }

    // MARK: - Mileage Update Sheet

    static var mileageUpdateTitle: String { localized("mileage.update_title") }
    static var mileageCurrentEstimate: String { localized("mileage.current_estimate") }
    static var mileageLastConfirmed: String { localized("mileage.last_confirmed") }
    static var mileageNoEstimate: String { localized("mileage.no_estimate") }
    static var mileageNoEstimateHint: String { localized("mileage.no_estimate_hint") }
    static var mileageEnterLabel: String { localized("mileage.enter_label") }
    static var mileageEnterPlaceholder: String { localized("mileage.enter_placeholder") }

    static func editWas(_ value: String) -> String {
        String(format: localized("edit.was"), value)
    }
    static var editVisitTotal: String { localized("edit.visitTotal") }
    static func editVisitTotalHint(_ count: Int) -> String {
        String(format: localized("edit.visitTotalHint"), count)
    }
    static func editVisitOccasionHint(_ count: Int) -> String {
        String(format: localized("edit.visitOccasionHint"), count)
    }
    static var impactNextReminder: String { localized("impact.nextReminder") }
    static var impactNone: String { localized("impact.none") }
    static var editAlsoMoveReminder: String { localized("edit.alsoMoveReminder") }
    static func editBetweenLogs(_ first: String, _ second: String) -> String {
        String(format: localized("edit.betweenLogs"), first, second)
    }
    static func editSinceLog(_ value: String) -> String {
        String(format: localized("edit.sinceLog"), value)
    }
    static func editBeforeLog(_ value: String) -> String {
        String(format: localized("edit.beforeLog"), value)
    }
    static var editLogMileageRequired: String { localized("edit.logMileageRequired") }

    // MARK: - Deleting a service log

    static var logDeleteAction: String { localized("log.delete.action") }

    // MARK: - Tip jar

    static var tipPurchaseFailed: String { localized("tip.purchase_failed") }
    static var tipSupportCheckpoint: String { localized("tip.support_checkpoint") }
    static var tipEveryTipUnlocks: String { localized("tip.every_tip_unlocks") }
    static var tipJarTitle: String { localized("tip.jar_title") }
    static var tipJarBody: String { localized("tip.jar_body") }
    static var tipNotNow: String { localized("tip.not_now") }
    static var tipPurchasing: String { localized("tip.purchasing") }
    static var tipAllRareCollected: String { localized("tip.all_rare_collected") }
    static var tipTierSmall: String { localized("tip.tier.small") }
    static var tipTierMedium: String { localized("tip.tier.medium") }
    static var tipTierLarge: String { localized("tip.tier.large") }
    static func tipRareProgress(owned: Int, total: Int) -> String {
        String(format: localized("tip.rare_progress"), owned, total)
    }
    /// VoiceOver label for a tip button: tier name, then price.
    static func tipPurchaseLabel(name: String, price: String) -> String {
        String(format: localized("tip.purchase_label"), name, price)
    }

    // MARK: - Service reminder notifications
    //
    // One family per lead time rather than one string with an interpolated
    // interval: "due tomorrow" and "due in 30 days" are different sentences in
    // most languages, not one sentence with a number in it.

    static func notificationServiceDueTitleToday(_ serviceName: String) -> String {
        String(format: localized("notification.serviceDue.title.today"), serviceName)
    }
    static func notificationServiceDueTitleTomorrow(_ serviceName: String) -> String {
        String(format: localized("notification.serviceDue.title.tomorrow"), serviceName)
    }
    static func notificationServiceDueTitleWeek(_ serviceName: String) -> String {
        String(format: localized("notification.serviceDue.title.week"), serviceName)
    }
    static func notificationServiceDueTitleMonth(_ serviceName: String) -> String {
        String(format: localized("notification.serviceDue.title.month"), serviceName)
    }
    static func notificationServiceDueTitleGeneric(_ serviceName: String) -> String {
        String(format: localized("notification.serviceDue.title.generic"), serviceName)
    }

    static func notificationServiceDueBodyToday(_ vehicleName: String, _ serviceName: String) -> String {
        String(format: localized("notification.serviceDue.body.today"), vehicleName, serviceName)
    }
    static func notificationServiceDueBodyTomorrow(_ vehicleName: String, _ serviceName: String) -> String {
        String(format: localized("notification.serviceDue.body.tomorrow"), vehicleName, serviceName)
    }
    static func notificationServiceDueBodyWeek(_ vehicleName: String, _ serviceName: String) -> String {
        String(format: localized("notification.serviceDue.body.week"), vehicleName, serviceName)
    }
    static func notificationServiceDueBodyMonth(_ vehicleName: String, _ serviceName: String) -> String {
        String(format: localized("notification.serviceDue.body.month"), vehicleName, serviceName)
    }
    static func notificationServiceDueBodyGeneric(_ vehicleName: String, _ serviceName: String, _ days: Int) -> String {
        String(format: localized("notification.serviceDue.body.generic"), vehicleName, serviceName, days)
    }

    static func notificationBundleTitleToday(_ count: Int) -> String {
        String(format: localized("notification.bundle.title.today"), count)
    }
    static func notificationBundleTitleTomorrow(_ count: Int) -> String {
        String(format: localized("notification.bundle.title.tomorrow"), count)
    }
    static func notificationBundleTitleWeek(_ count: Int) -> String {
        String(format: localized("notification.bundle.title.week"), count)
    }
    static func notificationBundleTitleMonth(_ count: Int) -> String {
        String(format: localized("notification.bundle.title.month"), count)
    }
    static func notificationBundleTitleGeneric(_ count: Int, _ days: Int) -> String {
        String(format: localized("notification.bundle.title.generic"), count, days)
    }

    static func notificationBundleBody(_ vehicleName: String, _ serviceList: String) -> String {
        String(format: localized("notification.bundle.body"), vehicleName, serviceList)
    }
    static func notificationBundleBodyOverflow(_ vehicleName: String, _ serviceList: String, _ remaining: Int) -> String {
        String(format: localized("notification.bundle.body.overflow"), vehicleName, serviceList, remaining)
    }

    static func notificationSnoozeTitle(_ serviceName: String) -> String {
        String(format: localized("notification.snooze.title"), serviceName)
    }
    static func notificationSnoozeBody(_ vehicleName: String, _ serviceName: String) -> String {
        String(format: localized("notification.snooze.body"), vehicleName, serviceName)
    }
    static var notificationMileageTitle: String { localized("notification.mileage.title") }
    static func notificationMileageBody(_ vehicleName: String, _ days: Int) -> String {
        String(format: localized("notification.mileage.body"), vehicleName, days)
    }

    static func notificationMarbeteTitleDays(_ days: Int) -> String {
        String(format: localized("notification.marbete.title.days"), days)
    }
    static var notificationMarbeteTitleUrgent: String { localized("notification.marbete.title.urgent") }
    static var notificationMarbeteTitleFinal: String { localized("notification.marbete.title.final") }
    static func notificationMarbeteBody60(_ vehicleName: String) -> String {
        String(format: localized("notification.marbete.body.60"), vehicleName)
    }
    static func notificationMarbeteBody30(_ vehicleName: String) -> String {
        String(format: localized("notification.marbete.body.30"), vehicleName)
    }
    static func notificationMarbeteBody7(_ vehicleName: String) -> String {
        String(format: localized("notification.marbete.body.7"), vehicleName)
    }
    static func notificationMarbeteBody1(_ vehicleName: String) -> String {
        String(format: localized("notification.marbete.body.1"), vehicleName)
    }
    static func notificationMarbeteBodyFinal(_ vehicleName: String) -> String {
        String(format: localized("notification.marbete.body.final"), vehicleName)
    }
    static func notificationMarbeteBodyGeneric(_ vehicleName: String, _ days: Int) -> String {
        String(format: localized("notification.marbete.body.generic"), vehicleName, days)
    }

    static func notificationRoundupTitle(_ year: Int) -> String {
        String(format: localized("notification.roundup.title"), year)
    }
    static func notificationRoundupBody(_ vehicleName: String, _ formattedCost: String) -> String {
        String(format: localized("notification.roundup.body"), vehicleName, formattedCost)
    }

    static var notificationActionMarkDone: String { localized("notification.action.markDone") }
    static var notificationActionRemindTomorrow: String { localized("notification.action.remindTomorrow") }
    static var notificationActionUpdateNow: String { localized("notification.action.updateNow") }
    static var notificationActionViewCosts: String { localized("notification.action.viewCosts") }
    static func notificationSnoozeBundleTitle(_ count: Int) -> String {
        String(format: localized("notification.snooze.bundleTitle"), count)
    }

    // MARK: - Helper

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}

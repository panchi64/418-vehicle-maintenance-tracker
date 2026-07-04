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
    static var commonDays: String { localized("common.days") }
    static var commonDelete: String { localized("common.delete") }
    static var commonUndo: String { localized("common.undo") }

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
    static var vehicleOptional: String { localized("vehicle.optional") }
    static var vehicleOdometer: String { localized("vehicle.odometer") }
    static var vehicleCurrentMileage: String { localized("vehicle.current_mileage") }
    static var vehicleMileagePlaceholder: String { localized("vehicle.mileage_placeholder") }
    static var vehicleIdentification: String { localized("vehicle.identification") }
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
    static var vehicleSkipDetails: String { localized("vehicle.skip_details") }
    static var vehicleFirstVehicle: String { localized("vehicle.first_vehicle") }
    static var vehicleLicensePlate: String { localized("vehicle.license_plate") }
    static var vehicleMarbeteHelp: String { localized("vehicle.marbete_help") }
    static var vehicleMarbeteHelpLong: String { localized("vehicle.marbete_help_long") }
    static var vehicleTireSizePlaceholderOptional: String { localized("vehicle.tire_size_placeholder_optional") }
    static var vehicleOilTypePlaceholderOptional: String { localized("vehicle.oil_type_placeholder_optional") }
    static var vehicleEditTitle: String { localized("vehicle.edit.title") }
    static var vehicleDeleteAction: String { localized("vehicle.delete.action") }
    static var vehicleDeleteConfirmTitle: String { localized("vehicle.delete.confirm_title") }
    static var vehicleDeleteConfirmMessage: String { localized("vehicle.delete.confirm_message") }
    static func vehicleVINCharacterCount(_ count: Int) -> String {
        String(format: localized("vehicle.vin_character_count"), count)
    }

    // MARK: - Add Vehicle Flow

    static func addVehicleStep(_ current: Int, _ total: Int) -> String {
        String(format: localized("addvehicle.step"), current, total)
    }

    static var addVehicleBasics: String { localized("addvehicle.basics") }
    static var addVehicleScanningVIN: String { localized("addvehicle.scanning_vin") }
    static var addVehicleScanningOdometer: String { localized("addvehicle.scanning_odometer") }
    static var addVehicleVINAlignGuide: String { localized("addvehicle.vin_align_guide") }
    static var addVehicleVINLookup: String { localized("addvehicle.vin_lookup") }
    static var addVehicleVINLookupLoading: String { localized("addvehicle.vin_lookup_loading") }
    static var addVehicleVINValueProp: String { localized("addvehicle.vin_value_prop") }
    static var addVehicleVINDetailsFilled: String { localized("addvehicle.vin_details_filled") }
    static var addVehicleVINValidLookup: String { localized("addvehicle.vin_valid_lookup") }

    // MARK: - Settings

    static var settingsTitle: String { localized("settings.title") }
    static var settingsDisplay: String { localized("settings.display") }
    static var settingsAlerts: String { localized("settings.alerts") }
    static var settingsReminders: String { localized("settings.reminders") }
    static var settingsWidgets: String { localized("settings.widgets") }
    static var settingsServiceBundling: String { localized("settings.service_bundling") }
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
    static var settingsDefaultVehicle: String { localized("settings.default_vehicle") }
    static var settingsMileageDisplay: String { localized("settings.mileage_display") }
    static var settingsMileageWindow: String { localized("settings.mileage_window") }
    static var settingsDaysWindow: String { localized("settings.days_window") }

    // MARK: - Distance Unit Picker

    static var distanceMiles: String { localized("distance.miles") }
    static var distanceKilometers: String { localized("distance.kilometers") }
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
    static var toastVehicleDeleted: String { localized("toast.vehicle_deleted") }
    static var toastServiceAdded: String { localized("toast.service_added") }
    static var toastServiceScheduled: String { localized("toast.service_scheduled") }
    static var toastServiceRecorded: String { localized("toast.service_recorded") }
    static var toastReminderSet: String { localized("toast.reminder_set") }
    static var reminderHelperText: String { localized("reminder.helper_text") }
    static var toastMileageUpdated: String { localized("toast.mileage_updated") }
    static var toastPDFReady: String { localized("toast.pdf_ready") }
    static var toastSyncError: String { localized("toast.sync_error") }
    static var toastReadingCaptured: String { localized("toast.reading_captured") }
    static var toastServiceLogUpdated: String { localized("toast.service_log_updated") }
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

    static var recallErrorTitle: String { localized("recall.error_title") }
    static var recallRetry: String { localized("recall.retry") }
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

    static var costsHeadlineTotal: String { localized("costs.headline.total") }
    static func costsHeadlineDeltaUp(_ amount: String, _ priorLabel: String) -> String {
        String(format: localized("costs.headline.delta_up"), amount, priorLabel)
    }
    static func costsHeadlineDeltaDown(_ amount: String, _ priorLabel: String) -> String {
        String(format: localized("costs.headline.delta_down"), amount, priorLabel)
    }
    static func costsHeadlineDeltaFlat(_ priorLabel: String) -> String {
        String(format: localized("costs.headline.delta_flat"), priorLabel)
    }
    static var costsHeadlinePriorMonth: String { localized("costs.headline.prior_month") }
    static func costsHeadlinePriorYTD(_ year: Int) -> String {
        String(format: localized("costs.headline.prior_ytd"), year)
    }
    static var costsHeadlinePriorYear: String { localized("costs.headline.prior_year") }
    static func costsHeadlineSplit(_ reactive: Int, _ preventive: Int, _ discretionary: Int) -> String {
        String(format: localized("costs.headline.split"), reactive, preventive, discretionary)
    }
    static func costsHeadlineProjection(_ amount: String) -> String {
        String(format: localized("costs.headline.projection"), amount)
    }
    static var costsHeadlineShare: String { localized("costs.headline.share") }

    static var costsClusterTitle: String { localized("costs.cluster.title") }
    static func costsClusterBody(_ count: Int, _ total: String) -> String {
        String(format: localized("costs.cluster.body"), count, total)
    }

    static var costsTopTitle: String { localized("costs.top.title") }
    static var costsRowOutlier: String { localized("costs.row.outlier") }

    static func costsCPMDeltaUp(_ amount: String) -> String {
        String(format: localized("costs.cpm.delta_up"), amount)
    }
    static func costsCPMDeltaDown(_ amount: String) -> String {
        String(format: localized("costs.cpm.delta_down"), amount)
    }
    static var costsCPMDeltaFlat: String { localized("costs.cpm.delta_flat") }

    static var costsEmptyStartTitle: String { localized("costs.empty.start.title") }
    static var costsEmptyStartMessage: String { localized("costs.empty.start.message") }
    static var costsEmptyNoneTitle: String { localized("costs.empty.none.title") }
    static var costsEmptyNoneMessage: String { localized("costs.empty.none.message") }

    static var costsUpcomingTitle: String { localized("costs.upcoming.title") }
    static func costsUpcomingBodySingular(_ name: String) -> String {
        String(format: localized("costs.upcoming.body_singular"), name)
    }
    static func costsUpcomingBodyPlural(_ name: String, _ more: Int) -> String {
        String(format: localized("costs.upcoming.body_plural"), name, more)
    }

    static var costsShareSubject: String { localized("costs.share.subject") }

    // MARK: - Empty States

    static var emptyCostPerMileHint: String { localized("empty.cost_per_mile_hint") }
    static var emptyPaceHint: String { localized("empty.pace_hint") }
    static var emptyChartPlaceholder: String { localized("empty.chart_placeholder") }
    static var emptyTimelineTitle: String { localized("empty.timeline_title") }
    static var emptyTimelineMessage: String { localized("empty.timeline_message") }
    static func emptyFilterShowing(_ shown: Int, _ total: Int) -> String {
        String(format: localized("empty.filter_showing"), shown, total)
    }
    static var emptyFilterClear: String { localized("empty.filter_clear") }

    // MARK: - Errors

    static var errorRequiredField: String { localized("error.required_field") }
    static var errorInvalidVINFormat: String { localized("error.invalid_vin_format") }
    static var errorCouldNotReadOdometer: String { localized("error.could_not_read_odometer") }
    static var errorNetworkConnectionFailed: String { localized("error.network_connection_failed") }

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
    static var onboardingDistanceUnitExplanation: String { localized("onboarding.distance_unit_explanation") }
    static var onboardingClimateZone: String { localized("onboarding.climate_zone") }
    static var onboardingClimateZoneExplanation: String { localized("onboarding.climate_zone_explanation") }
    static var onboardingSwipeNext: String { localized("onboarding.swipe_next") }

    static var onboardingTourDashboardTitle: String { localized("onboarding.tour.dashboard.title") }
    static var onboardingTourDashboardBody: String { localized("onboarding.tour.dashboard.body") }
    static var onboardingTourVehicleTitle: String { localized("onboarding.tour.vehicle.title") }
    static var onboardingTourVehicleBody: String { localized("onboarding.tour.vehicle.body") }
    static var onboardingTourServicesTitle: String { localized("onboarding.tour.services.title") }
    static var onboardingTourServicesBody: String { localized("onboarding.tour.services.body") }
    static var onboardingTourCostsTitle: String { localized("onboarding.tour.costs.title") }
    static var onboardingTourCostsBody: String { localized("onboarding.tour.costs.body") }

    static var onboardingTransitionServices: String { localized("onboarding.transition.services") }
    static var onboardingTransitionCosts: String { localized("onboarding.transition.costs") }
    static var onboardingTransitionTapToContinue: String { localized("onboarding.transition.tap_to_continue") }

    static func onboardingTourNextTo(_ destination: String) -> String {
        String(format: localized("onboarding.tour.next_to"), destination)
    }
    static func onboardingTourProgress(tab: String, step: Int, total: Int) -> String {
        String(format: localized("onboarding.tour.progress"), tab, step, total)
    }

    static var onboardingTourRecapTitle: String { localized("onboarding.tour.recap.title") }
    static var onboardingTourRecapBody: String { localized("onboarding.tour.recap.body") }
    static var onboardingTourRecapDone: String { localized("onboarding.tour.recap.done") }

    static var onboardingTourSkipConfirmTitle: String { localized("onboarding.tour.skip_confirm_title") }
    static var onboardingTourSkipConfirmMessage: String { localized("onboarding.tour.skip_confirm_message") }
    static var onboardingTourSkipConfirmCancel: String { localized("onboarding.tour.skip_confirm_cancel") }

    static var onboardingGetStartedTitle: String { localized("onboarding.getstarted.title") }
    static var onboardingGetStartedVINLabel: String { localized("onboarding.getstarted.vin_label") }
    static var onboardingGetStartedVINHelp: String { localized("onboarding.getstarted.vin_help") }
    static var onboardingGetStartedVINPlaceholder: String { localized("onboarding.getstarted.vin_placeholder") }
    static func onboardingGetStartedCharacters(_ count: Int) -> String {
        String(format: localized("onboarding.getstarted.characters"), count)
    }
    static var onboardingGetStartedLookup: String { localized("onboarding.getstarted.lookup") }
    static var onboardingGetStartedLookingUp: String { localized("onboarding.getstarted.looking_up") }
    static var onboardingGetStartedAddVehicle: String { localized("onboarding.getstarted.add_vehicle") }
    static var onboardingGetStartedManual: String { localized("onboarding.getstarted.manual") }
    static var onboardingGetStartedOr: String { localized("onboarding.getstarted.or") }
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
    static var documentsSegmentTimeline: String { localized("documents.segment.timeline") }
    static var documentsSegmentDocuments: String { localized("documents.segment.documents") }
    static var documentsRowQuickSpecs: String { localized("documents.row.quick_specs") }
    static var documentsNotesLabel: String { localized("documents.notes.label") }
    static var documentsNotesPlaceholder: String { localized("documents.notes.placeholder") }
    static var documentsTypeLabel: String { localized("documents.type.label") }
    static var documentsLinkedVehiclesLabel: String { localized("documents.linked_vehicles.label") }
    static var documentsLinkedVehiclesEdit: String { localized("documents.linked_vehicles.edit") }
    static var documentsFromServiceLog: String { localized("documents.from_service_log") }
    static var documentsLinkToOtherVehicles: String { localized("documents.link_to_other_vehicles") }
    static func documentsLinkedCount(_ count: Int) -> String {
        String(format: localized("documents.linked_count"), count)
    }
    static var documentsDeleteConfirmTitle: String { localized("documents.delete.confirm_title") }
    static var documentsDeleteConfirmMessage: String { localized("documents.delete.confirm_message") }
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
    static var formSaveAndAddAnother: String { localized("form.saveAndAddAnother") }
    static var formSavedAddNext: String { localized("form.savedAddNext") }
    static var formServiceTypeRequired: String { localized("form.serviceTypeRequired") }
    static var formVehicleBasicsRequired: String { localized("form.vehicleBasicsRequired") }
    static var formDraftResumeTitle: String { localized("form.draftResumeTitle") }
    static func formDraftFrom(_ relativeDate: String) -> String {
        String(format: localized("form.draftFrom"), relativeDate)
    }
    static var formDraftResume: String { localized("form.draftResume") }
    static var formDraftDiscard: String { localized("form.draftDiscard") }
    static var formServiceType: String { localized("form.serviceType") }
    static var formDatePerformed: String { localized("form.datePerformed") }
    static var formCost: String { localized("form.cost") }
    static var formAmount: String { localized("form.amount") }
    static var formCategory: String { localized("form.category") }
    static var formMileage: String { localized("form.mileage") }
    static var formMileageBlankHint: String { localized("form.mileageBlankHint") }
    static var formReminder: String { localized("form.reminder") }
    static var formRemindNextTime: String { localized("form.remindNextTime") }
    static var formNotes: String { localized("form.notes") }
    static var formNotesPlaceholder: String { localized("form.notesPlaceholder") }
    static var formAttachments: String { localized("form.attachments") }
    static var formAddAttachments: String { localized("form.addAttachments") }
    static var formNextDue: String { localized("form.nextDue") }
    static func formNextDuePreview(_ schedule: String) -> String {
        String(format: localized("form.nextDuePreview"), schedule)
    }
    static func formAtMileage(_ mileage: String) -> String {
        String(format: localized("form.atMileage"), mileage)
    }
    static var formOr: String { localized("form.or") }
    static var formSetDueDate: String { localized("form.setDueDate") }
    static var formDueDate: String { localized("form.dueDate") }
    static var formDueMileage: String { localized("form.dueMileage") }
    static func formSuggestValue(_ value: String) -> String {
        String(format: localized("form.suggestValue"), value)
    }
    static func formSuggestMonths(_ months: Int) -> String {
        String(format: localized("form.suggestMonths"), months)
    }
    static var formUse: String { localized("form.use") }
    static func formUseSuggestedValue(_ value: String) -> String {
        String(format: localized("form.useSuggestedValue"), value)
    }
    static var formDatePastWarning: String { localized("form.datePastWarning") }
    static var formRepeats: String { localized("form.repeats") }
    static var formRepeatAfterCompletion: String { localized("form.repeatAfterCompletion") }
    static var formEvery: String { localized("form.every") }
    static var formOrEvery: String { localized("form.orEvery") }
    static var formMonthsSuffix: String { localized("form.monthsSuffix") }
    static var formMilesSuffix: String { localized("form.milesSuffix") }
    static var formWhicheverFirst: String { localized("form.whicheverFirst") }
    static func formDaysOverdue(_ days: Int) -> String {
        String(format: localized("form.daysOverdue"), days)
    }
    static func formDaysAhead(_ days: Int) -> String {
        String(format: localized("form.daysAhead"), days)
    }
    static func formMileagePast(_ mileage: String) -> String {
        String(format: localized("form.mileagePast"), mileage)
    }
    static func formMileageAhead(_ mileage: String) -> String {
        String(format: localized("form.mileageAhead"), mileage)
    }
    static var formEveryMonth: String { localized("form.everyMonth") }
    static func formEveryNMonths(_ months: Int) -> String {
        String(format: localized("form.everyNMonths"), months)
    }
    static func formEveryMileage(_ mileage: String) -> String {
        String(format: localized("form.everyMileage"), mileage)
    }
    static var formEditingTag: String { localized("form.editingTag") }

    static var addServiceTitleRecord: String { localized("addservice.titleRecord") }
    static var addServiceTitleRemind: String { localized("addservice.titleRemind") }

    // MARK: - Service Form Chips

    static var chipNextWeek: String { localized("chip.nextWeek") }
    static var chipMonths1Approx: String { localized("chip.months1Approx") }
    static var chipMonths3Approx: String { localized("chip.months3Approx") }
    static var chipMonths6Approx: String { localized("chip.months6Approx") }
    static var chipMonths3: String { localized("chip.months3") }
    static var chipMonths6: String { localized("chip.months6") }
    static var chipYears1: String { localized("chip.years1") }
    static var chipYears2: String { localized("chip.years2") }

    // MARK: - Mileage Update Sheet

    static var mileageUpdateTitle: String { localized("mileage.update_title") }
    static var mileageCurrentEstimate: String { localized("mileage.current_estimate") }
    static var mileageLastConfirmed: String { localized("mileage.last_confirmed") }
    static var mileageNoEstimate: String { localized("mileage.no_estimate") }
    static var mileageNoEstimateHint: String { localized("mileage.no_estimate_hint") }
    static var mileageEnterLabel: String { localized("mileage.enter_label") }
    static var mileageEnterPlaceholder: String { localized("mileage.enter_placeholder") }
    static var mileageDismissError: String { localized("mileage.dismiss_error") }

    static var serviceModeRecord: String { localized("serviceMode.record") }
    static var serviceModeRemind: String { localized("serviceMode.remind") }
    static var serviceModeRecordCaption: String { localized("serviceMode.recordCaption") }
    static var serviceModeRemindCaption: String { localized("serviceMode.remindCaption") }

    static func refCardLast(_ serviceName: String) -> String {
        String(format: localized("refCard.last"), serviceName)
    }
    static var refCardUseValues: String { localized("refCard.useValues") }

    static func editWas(_ value: String) -> String {
        String(format: localized("edit.was"), value)
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
    static var remindNoScheduleWarning: String { localized("remind.noScheduleWarning") }
    static var recordSetIntervalHint: String { localized("record.setIntervalHint") }

    // MARK: - Helper

    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}

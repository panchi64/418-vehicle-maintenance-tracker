//
//  L10n+Forms.swift
//  checkpoint
//
//  Strings for the form toolbar model and the unified service form. Kept apart
//  from `L10n.swift` so parallel work doesn't collide in one file; keys are
//  prefixed `form.` in Localizable.xcstrings.
//

import Foundation

extension L10n {
    private static func form(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    private static func form(_ key: String, _ args: CVarArg...) -> String {
        String(format: NSLocalizedString(key, comment: ""), arguments: args)
    }

    // MARK: - Toolbar and dismiss protection

    static var formSaving: String { form("form.saving") }
    static var formDiscardTitle: String { form("form.discardTitle") }
    static var formDiscard: String { form("form.discard") }
    static var formKeepEditing: String { form("form.keepEditing") }

    // MARK: - Titles

    static var formTitleLog: String { form("form.titleLog") }
    static var formTitleComplete: String { form("form.titleComplete") }
    static var formTitleSchedule: String { form("form.titleSchedule") }
    static var formTitleEdit: String { form("form.titleEdit") }
    static var formTitleCompleteVisit: String { form("form.titleCompleteVisit") }

    // MARK: - Service picker

    static var formSectionService: String { form("form.sectionService") }
    static var formServiceSearchPlaceholder: String { form("form.serviceSearchPlaceholder") }
    static var formDueNow: String { form("form.dueNow") }
    static var formRecent: String { form("form.recent") }
    static var formBrowseAll: String { form("form.browseAll") }
    static var formChange: String { form("form.change") }
    /// VoiceOver: "Change service, Oil Change".
    static func formChangeService(_ name: String) -> String { form("form.changeService", name) }
    /// Edit's neighbour summary: "32,000 mi (Mar 3)".
    static func formLogSummary(_ mileage: String, _ date: String) -> String {
        form("form.logSummary", mileage, date)
    }
    static func formServicesCount(_ count: Int) -> String { form("form.servicesCount", count) }

    static var formCategoryEngine: String { form("form.categoryEngine") }
    static var formCategoryTires: String { form("form.categoryTires") }
    static var formCategoryBrakes: String { form("form.categoryBrakes") }
    static var formCategoryTransmission: String { form("form.categoryTransmission") }
    static var formCategoryFluids: String { form("form.categoryFluids") }
    static var formCategoryElectrical: String { form("form.categoryElectrical") }
    static var formCategoryBody: String { form("form.categoryBody") }
    static var formCategoryOther: String { form("form.categoryOther") }

    // MARK: - When / Due

    static var timingNotYet: String { form("form.timingNotYet") }
    static var formSectionDue: String { form("form.sectionDue") }
    /// The interval chip: "In 6 mo / 5,000 mi".
    static func formDueInInterval(_ interval: String) -> String { form("form.dueInInterval", interval) }
    static func formEveryInterval(_ interval: String) -> String { form("form.everyInterval", interval) }
    static var formSetIntervalInDetails: String { form("form.setIntervalInDetails") }
    static func formDateOrMileage(_ date: String, _ mileage: String) -> String {
        form("form.dateOrMileage", date, mileage)
    }

    // MARK: - Details

    static var formEnterReading: String { form("form.enterReading") }
    static func formUseEstimate(_ mileage: String) -> String { form("form.useEstimate", mileage) }
    static var formTotalCost: String { form("form.totalCost") }

    // MARK: - Next reminder

    static var formNextReminderTitle: String { form("form.nextReminderTitle") }
    static var formNoReminder: String { form("form.noReminder") }
    static func formEveryIntervalWhicheverFirst(_ interval: String) -> String {
        form("form.everyIntervalWhicheverFirst", interval)
    }
    static func formWontComeBack(_ name: String) -> String { form("form.wontComeBack", name) }

    // MARK: - More details

    /// Names the collapsed drawer's contents, category value first.
    static func formDepthSummary(_ category: String) -> String { form("form.depthSummary", category) }
    static var formDepthSummarySchedule: String { form("form.depthSummarySchedule") }

    // MARK: - Scanned odometer

    static var formOCRTitle: String { form("form.ocrTitle") }
    static var formOCRDetectedValue: String { form("form.ocrDetectedValue") }
    static var formOCRTapToEdit: String { form("form.ocrTapToEdit") }
    static var formOCRLowConfidence: String { form("form.ocrLowConfidence") }
    static func formOCRBelowPrevious(_ mileage: String) -> String { form("form.ocrBelowPrevious", mileage) }
}

import SwiftUI

@Observable
@MainActor
final class AddServiceFormModel {
    let vehicle: Vehicle

    var mode: ServiceMode
    var selectedPreset: PresetData?
    var customServiceName: String = ""

    var performedDate: Date = Date()
    var mileageAtService: Int?
    var cost: String = ""
    var costError: String?
    var costCategory: CostCategory = .maintenance
    /// Separate per-mode buffers — switching the segmented control must never
    /// destroy what the user typed in the other mode.
    var recordNotes: String = ""
    var remindNotes: String = ""
    /// Shared "this should repeat after completion" toggle. In record mode it
    /// also schedules the next occurrence inline; in remind mode it gates
    /// whether `isRecurring` is persisted on the Service.
    var isRecurring: Bool = false
    var pendingAttachments: [AttachmentPicker.AttachmentData] = []

    var hasCustomDate: Bool = false
    var dueDate: Date = Date()
    var nextDueMileage: Int?
    var intervalMonths: Int?
    var intervalMiles: Int?

    var presets: [PresetData] = []

    /// Blank-form snapshot captured once at creation, used to tell whether
    /// the user has made any real change (R9's cancel-without-nagging rule).
    private(set) var baselineDraft: ServiceFormDraft = ServiceFormDraft(
        mode: ServiceMode.record.rawValue,
        serviceName: "",
        presetName: nil,
        performedDate: .now,
        costText: "",
        costCategoryRaw: nil,
        mileageText: "",
        recordNotes: "",
        remindNotes: "",
        dueDate: nil,
        hasCustomDate: false,
        dueMileage: nil,
        intervalMonths: nil,
        intervalMiles: nil,
        isRecurring: false,
        savedAt: .now
    )

    init(vehicle: Vehicle, initialMode: ServiceMode) {
        self.vehicle = vehicle
        self.mode = initialMode
        self.baselineDraft = toDraft()
    }

    /// Drives `Service.dueDate` directly at save time — no derivation from
    /// intervals. Intervals are recurrence policy only.
    var nextDueDate: Date? {
        hasCustomDate ? dueDate : nil
    }

    var hasIntervalPolicy: Bool {
        Service.hasIntervalPolicy(intervalMonths: intervalMonths, intervalMiles: intervalMiles)
    }

    /// Whether the scheduled occurrence should chain forward on completion.
    /// Only meaningful when intervals are also set — explicit user intent
    /// (the toggle) plus a non-zero policy.
    var isRecurringSchedule: Bool {
        isRecurring && hasIntervalPolicy
    }

    var serviceName: String {
        selectedPreset?.name ?? customServiceName
    }

    var isFormValid: Bool {
        !serviceName.isEmpty
    }

    /// `true` once anything differs from the blank form this model started
    /// as — used to decide whether a Cancel should keep or clear the draft.
    var isDirty: Bool {
        var current = toDraft()
        current.savedAt = baselineDraft.savedAt
        return current != baselineDraft
    }

    func useLastEntry(from log: ServiceLog) {
        let template = LoggedServiceTemplate(from: log)
        selectedPreset = nil
        customServiceName = template.serviceName
        cost = template.costString
        if let category = template.costCategory {
            costCategory = category
        }
        recordNotes = template.notes ?? ""
        intervalMonths = template.intervalMonths
        intervalMiles = template.intervalMiles
        isRecurring = template.hasRecurringIntervals
        HapticService.shared.selectionChanged()
    }

    func applySeasonalPrefill(_ prefill: SeasonalPrefill) {
        mode = .remind
        customServiceName = prefill.serviceName
        hasCustomDate = true
        dueDate = prefill.dueDate
        intervalMonths = prefill.intervalMonths
        isRecurring = true
    }

    func applyPostRecordPrefill(_ prefill: PostRecordPrefill) {
        mode = .remind
        customServiceName = prefill.serviceName
        intervalMonths = prefill.intervalMonths
        intervalMiles = prefill.intervalMiles
        isRecurring = Service.hasIntervalPolicy(
            intervalMonths: prefill.intervalMonths,
            intervalMiles: prefill.intervalMiles
        )
        if let months = prefill.intervalMonths, months > 0,
           let projected = Calendar.current.date(byAdding: .month, value: months, to: prefill.performedDate) {
            hasCustomDate = true
            dueDate = projected
        }
        if let miles = prefill.intervalMiles, miles > 0 {
            nextDueMileage = prefill.performedMileage + miles
        }
    }

    /// Clears everything a "Save & add another" round should not carry into
    /// the next entry, while preserving visit context (date + mileage), the
    /// active mode, and the Details disclosure state (owned by the view).
    func resetLogModeFields() {
        selectedPreset = nil
        customServiceName = ""
        cost = ""
        costError = nil
        costCategory = .maintenance
        recordNotes = ""
        pendingAttachments = []
        isRecurring = false
        intervalMonths = nil
        intervalMiles = nil
    }

    // MARK: - Draft (R9)

    func toDraft() -> ServiceFormDraft {
        ServiceFormDraft(
            mode: mode.rawValue,
            serviceName: customServiceName,
            presetName: selectedPreset?.name,
            performedDate: performedDate,
            costText: cost,
            costCategoryRaw: costCategory.rawValue,
            mileageText: mileageAtService.map(String.init) ?? "",
            recordNotes: recordNotes,
            remindNotes: remindNotes,
            dueDate: hasCustomDate ? dueDate : nil,
            hasCustomDate: hasCustomDate,
            dueMileage: nextDueMileage,
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles,
            isRecurring: isRecurring,
            savedAt: .now
        )
    }

    /// Silently drops `presetName` when it no longer matches a known preset,
    /// falling back to the free-typed service name instead.
    func apply(_ draft: ServiceFormDraft) {
        mode = ServiceMode(rawValue: draft.mode) ?? mode
        if let presetName = draft.presetName, let preset = presets.first(where: { $0.name == presetName }) {
            selectedPreset = preset
            customServiceName = ""
        } else {
            selectedPreset = nil
            customServiceName = draft.serviceName
        }
        performedDate = draft.performedDate
        cost = draft.costText
        if let categoryRaw = draft.costCategoryRaw, let category = CostCategory(rawValue: categoryRaw) {
            costCategory = category
        }
        mileageAtService = Int(draft.mileageText)
        recordNotes = draft.recordNotes
        remindNotes = draft.remindNotes
        hasCustomDate = draft.hasCustomDate
        if let dueDate = draft.dueDate {
            self.dueDate = dueDate
        }
        nextDueMileage = draft.dueMileage
        intervalMonths = draft.intervalMonths
        intervalMiles = draft.intervalMiles
        isRecurring = draft.isRecurring
    }
}

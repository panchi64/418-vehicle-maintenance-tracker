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
    var notes: String = ""
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

    init(vehicle: Vehicle, initialMode: ServiceMode) {
        self.vehicle = vehicle
        self.mode = initialMode
    }

    /// Drives `Service.dueDate` directly at save time — no derivation from
    /// intervals. Intervals are recurrence policy only.
    var nextDueDate: Date? {
        hasCustomDate ? dueDate : nil
    }

    /// Whether the scheduled occurrence should chain forward on completion.
    /// Only meaningful when intervals are also set — explicit user intent
    /// (the toggle) plus a non-zero policy.
    var isRecurringSchedule: Bool {
        isRecurring && Service.hasIntervalPolicy(intervalMonths: intervalMonths, intervalMiles: intervalMiles)
    }

    var serviceName: String {
        selectedPreset?.name ?? customServiceName
    }

    var isFormValid: Bool {
        !serviceName.isEmpty
    }

    func useLastEntry(from log: ServiceLog) {
        let template = LoggedServiceTemplate(from: log)
        selectedPreset = nil
        customServiceName = template.serviceName
        cost = template.costString
        if let category = template.costCategory {
            costCategory = category
        }
        notes = template.notes ?? ""
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

    /// Remind-mode counterpart to `useLastEntry(from:)`. Diverges by projecting a
    /// next-due date/mileage from the historic anchor + interval policy, and
    /// by skipping cost/notes (which only matter when recording a completion).
    /// The service name is preserved if the user already has one in flight.
    func useLastEntryForRemind(from log: ServiceLog) {
        let template = LoggedServiceTemplate(from: log)
        if selectedPreset == nil && customServiceName.isEmpty {
            customServiceName = template.serviceName
        }
        intervalMonths = template.intervalMonths
        intervalMiles = template.intervalMiles
        isRecurring = template.hasRecurringIntervals
        if let interval = template.intervalMiles, interval > 0 {
            nextDueMileage = log.mileageAtService + interval
        }
        if let months = template.intervalMonths, months > 0,
           let suggested = Calendar.current.date(byAdding: .month, value: months, to: log.performedDate) {
            hasCustomDate = true
            dueDate = suggested
        }
        HapticService.shared.selectionChanged()
    }

    func resetLogModeFields() {
        selectedPreset = nil
        customServiceName = ""
        performedDate = Date()
        mileageAtService = vehicle.currentMileage
        cost = ""
        costCategory = .maintenance
        notes = ""
        isRecurring = false
        pendingAttachments = []
        intervalMonths = nil
        intervalMiles = nil
        hasCustomDate = false
        dueDate = Date()
        nextDueMileage = nil
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
            recordNotes: mode == .record ? notes : "",
            remindNotes: mode == .remind ? notes : "",
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
        notes = mode == .record ? draft.recordNotes : draft.remindNotes
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

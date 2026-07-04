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

    /// Pristine-form snapshot captured at creation (after the mileage
    /// prefill), used to tell whether the user has made any real change
    /// (R9's cancel-without-nagging rule).
    private var baselineSnapshot: ServiceFormDraft?

    init(vehicle: Vehicle, initialMode: ServiceMode) {
        self.vehicle = vehicle
        self.mode = initialMode
        // Prefill before capturing the baseline — a prefilled-but-untouched
        // form must not count as dirty, or Cancel would keep phantom drafts.
        self.mileageAtService = vehicle.currentMileage
        self.baselineSnapshot = contentSnapshot
    }

    /// Content-only snapshot (fixed timestamp). Drives both `isDirty` and the
    /// view's autosave debounce so the two can never disagree about what
    /// counts as an edit.
    var contentSnapshot: ServiceFormDraft {
        var snapshot = toDraft()
        snapshot.savedAt = .distantPast
        return snapshot
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

    /// `true` once anything differs from the pristine form this model started
    /// as — used to decide whether a Cancel should keep or clear the draft.
    var isDirty: Bool {
        contentSnapshot != baselineSnapshot
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
        let projected = ReminderImpactCalculator.projected(
            intervalMonths: prefill.intervalMonths,
            intervalMiles: prefill.intervalMiles,
            anchorDate: prefill.performedDate,
            anchorMileage: prefill.performedMileage,
            explicitDueDate: nil,
            explicitDueMileage: nil
        )
        if let projectedDate = projected.dueDate {
            hasCustomDate = true
            dueDate = projectedDate
        }
        if let projectedMileage = projected.dueMileage {
            nextDueMileage = projectedMileage
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
        // Remind-side schedule state must not leak into the next entry —
        // a due date/mileage set (then abandoned) in Remind mode would
        // otherwise silently attach to the next saved service.
        hasCustomDate = false
        dueDate = Date()
        nextDueMileage = nil
        // The reset form is the new pristine state: without re-baselining,
        // the autosave would immediately persist a phantom draft of it.
        baselineSnapshot = contentSnapshot
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

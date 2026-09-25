import SwiftUI

@Observable
@MainActor
final class AddServiceFormModel {
    let vehicle: Vehicle

    /// The one control that derives intent. Nil until the user answers "when",
    /// which is why the save button reads "Save" rather than claiming an intent
    /// the user has not expressed.
    var timing: ServiceTiming?

    /// Supplies the date for the two timings that need one — `.earlier` and
    /// `.onDate`. A single field replaces the old `hasCustomDate` + `dueDate` +
    /// `performedDate` trio, which could disagree with each other.
    var customDate: Date = Date()

    var selectedPreset: PresetData?
    var customServiceName: String = ""

    var mileageAtService: Int?
    var cost: String = ""
    var costError: String?
    var costCategory: CostCategory = .maintenance

    /// One notes buffer. There were two — `recordNotes` and `remindNotes` —
    /// because the mode switch could destroy what the user typed in the other
    /// mode. With no mode there is nothing to switch between.
    var notes: String = ""

    /// Whether the item should chain forward after completion.
    var isRecurring: Bool = false
    var pendingAttachments: [AttachmentPicker.AttachmentData] = []

    var nextDueMileage: Int?
    var intervalMonths: Int?
    var intervalMiles: Int?

    var presets: [PresetData] = []

    /// How the user resolved an odometer contradiction the app cannot settle
    /// on its own. Nil until they answer; cleared whenever the inputs change.
    enum MileageResolution: Equatable {
        case keepCurrent
        case correctUpward
    }
    var mileageResolution: MileageResolution?

    /// Pristine-form snapshot captured at creation (after the mileage
    /// prefill), used to tell whether the user has made any real change
    /// (R9's cancel-without-nagging rule).
    private var baselineSnapshot: ServiceFormDraft?

    init(vehicle: Vehicle, initialTiming: ServiceTiming? = nil) {
        self.vehicle = vehicle
        self.timing = initialTiming
        // Prefill before capturing the baseline — a prefilled-but-untouched
        // form must not count as dirty, or Cancel would keep phantom drafts.
        self.mileageAtService = vehicle.currentMileage
        self.baselineSnapshot = contentSnapshot
    }

    // MARK: - Derived intent

    /// Nil until a timing is chosen. Nothing in the UI names these values.
    var intent: ServiceIntent? { timing?.intent }

    var isLogging: Bool { intent == .log }
    var isScheduling: Bool { intent == .schedule }

    /// Content-only snapshot (fixed timestamp). Drives both `isDirty` and the
    /// view's autosave debounce so the two can never disagree about what
    /// counts as an edit.
    var contentSnapshot: ServiceFormDraft {
        var snapshot = toDraft()
        snapshot.savedAt = .distantPast
        return snapshot
    }

    var performedDate: Date {
        timing?.performedDate(explicit: customDate) ?? customDate
    }

    /// Drives `Service.dueDate` directly at save time — no derivation from
    /// intervals. Intervals are recurrence policy only.
    var nextDueDate: Date? {
        guard let timing, timing.intent == .schedule else { return nil }
        return timing.dueDate(explicit: customDate)
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

    // MARK: - Logged recurrence (F4)

    /// The odometer a logged entry is anchored to. A blank field means "at
    /// the reading on file".
    var logAnchorMileage: Int {
        mileageAtService ?? vehicle.currentMileage
    }

    /// The reminder a log will leave behind, or nil when it leaves none.
    ///
    /// Picking a preset turns recurrence on, but the repeat controls live on
    /// the scheduling branch — so logging an oil change silently created a
    /// 6-month / 5,000-mile reminder. This is what the log path shows instead.
    /// Uses `ReminderImpactCalculator.projected`, the calculation the save
    /// path's `deriveDueFromIntervals` runs, with the same anchors — whether
    /// the save creates a service or completes a matched one, the successor
    /// is derived from `performedDate` and `logAnchorMileage`.
    var nextReminderAfterLog: ReminderImpactCalculator.Schedule? {
        guard isLogging, isRecurringSchedule else { return nil }
        let schedule = ReminderImpactCalculator.projected(
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles,
            anchorDate: performedDate,
            anchorMileage: logAnchorMileage,
            explicitDueDate: nil,
            explicitDueMileage: nil
        )
        guard schedule.dueDate != nil || schedule.dueMileage != nil else { return nil }
        return schedule
    }

    /// Seed the recurrence policy when the service type, or the tracked
    /// service a log would complete, changes.
    ///
    /// A matched service carries the user's own cadence, which wins over a
    /// preset's generic one — otherwise completing a 3-month oil change from
    /// [+] would quietly re-cadence it to the preset's 6. A backfilled entry
    /// with no match must not inherit a preset's recurrence and spawn
    /// reminders for a service done years ago.
    func applyScheduleDefaults(preset: PresetData?, match: Service?) {
        if let match, match.hasIntervalPolicy {
            intervalMonths = match.intervalMonths
            intervalMiles = match.intervalMiles
            isRecurring = match.isRecurring
            return
        }
        if let preset {
            if let months = preset.defaultIntervalMonths { intervalMonths = months }
            if let miles = preset.defaultIntervalMiles { intervalMiles = miles }
        }
        if timing?.isBackfill == true {
            isRecurring = false
            return
        }
        if let preset, Service.hasIntervalPolicy(
            intervalMonths: preset.defaultIntervalMonths,
            intervalMiles: preset.defaultIntervalMiles
        ) {
            isRecurring = true
        }
    }

    // MARK: - Mileage reasoning (F11)

    /// Whether saving would also advance the vehicle's odometer. Mirrors
    /// `MileageCommit.wouldAdopt` rather than re-deriving it, so the advisory
    /// shown before save cannot disagree with what the save does.
    var wouldAdoptMileage: Bool {
        guard isLogging, let reading = mileageAtService else { return false }
        guard mileageResolution != .keepCurrent else { return false }
        return MileageCommit.wouldAdopt(
            reading: reading,
            observedAt: performedDate,
            for: vehicle
        )
    }

    /// The one case the app genuinely cannot resolve: a backfilled entry
    /// carrying a reading above the current odometer. Either the odometer is
    /// wrong or the date is, and only the user knows which.
    var hasUnresolvedMileageContradiction: Bool {
        guard isLogging, let timing, timing.isBackfill else { return false }
        guard let reading = mileageAtService, reading > vehicle.currentMileage else { return false }
        return mileageResolution == nil
    }

    // MARK: - Validity

    /// Why this cannot be saved yet, phrased as the next thing to do. Nil means
    /// it can be saved. The action bar surfaces this on a disabled tap (F2), so
    /// the user is never left guessing which field is at fault.
    var blockingReason: String? {
        if serviceName.trimmingCharacters(in: .whitespaces).isEmpty {
            return L10n.formServiceTypeRequired
        }
        if timing == nil {
            return L10n.formTimingRequired
        }
        if hasUnresolvedMileageContradiction {
            return L10n.formResolveOdometerConflict
        }
        // A mileage-triggered reminder with no mileage has no trigger and would
        // never fire. This is the only case that genuinely blocks a save.
        if timing?.isMileageTriggered == true, nextDueMileage == nil {
            return L10n.formRemindMileageRequired
        }
        return nil
    }

    var isFormValid: Bool { blockingReason == nil }

    /// `true` once anything differs from the pristine form this model started
    /// as — used to decide whether a Cancel should keep or clear the draft.
    var isDirty: Bool {
        contentSnapshot != baselineSnapshot
    }

    // MARK: - Prefills

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
    }

    /// Seasonal prefills carry a concrete due date, so they land on `.onDate`
    /// rather than on a mode.
    func applySeasonalPrefill(_ prefill: SeasonalPrefill) {
        timing = .onDate
        customServiceName = prefill.serviceName
        customDate = prefill.dueDate
        intervalMonths = prefill.intervalMonths
        isRecurring = true
    }

    func applyPostRecordPrefill(_ prefill: PostRecordPrefill) {
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
            timing = .onDate
            customDate = projectedDate
        } else {
            timing = .atMileage
        }
        if let projectedMileage = projected.dueMileage {
            nextDueMileage = projectedMileage
        }
    }

    /// Clears everything a "Save & add another" round should not carry into
    /// the next entry, while preserving the chosen timing (the user is logging
    /// one visit's worth of work) and the Details disclosure state.
    func resetLogModeFields() {
        selectedPreset = nil
        customServiceName = ""
        cost = ""
        costError = nil
        costCategory = .maintenance
        notes = ""
        pendingAttachments = []
        isRecurring = false
        intervalMonths = nil
        intervalMiles = nil
        nextDueMileage = nil
        mileageResolution = nil
        // The reset form is the new pristine state: without re-baselining,
        // the autosave would immediately persist a phantom draft of it.
        baselineSnapshot = contentSnapshot
    }

    // MARK: - Draft (F10)

    func toDraft() -> ServiceFormDraft {
        ServiceFormDraft(
            version: ServiceFormDraft.currentVersion,
            timing: timing,
            customDate: customDate,
            serviceName: customServiceName,
            presetName: selectedPreset?.name,
            costText: cost,
            costCategoryRaw: costCategory.rawValue,
            mileageText: mileageAtService.map(String.init) ?? "",
            notes: notes,
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
        timing = draft.timing
        customDate = draft.customDate
        if let presetName = draft.presetName, let preset = presets.first(where: { $0.name == presetName }) {
            selectedPreset = preset
            customServiceName = ""
        } else {
            selectedPreset = nil
            customServiceName = draft.serviceName
        }
        cost = draft.costText
        if let categoryRaw = draft.costCategoryRaw, let category = CostCategory(rawValue: categoryRaw) {
            costCategory = category
        }
        mileageAtService = Int(draft.mileageText)
        notes = draft.notes
        nextDueMileage = draft.dueMileage
        intervalMonths = draft.intervalMonths
        intervalMiles = draft.intervalMiles
        isRecurring = draft.isRecurring
    }
}

//
//  ServiceLogFormModel.swift
//  checkpoint
//
//  State for the unified service form (`ServiceLogForm`). One model for all
//  three doors — [+], Mark Done, and editing a history entry — so the three
//  can't drift into three differently-shaped forms again.
//
//  Drafts and prefills live in `+Draft`, edit-mode loading and change
//  tracking in `+Edit`, odometer reasoning and save blockers in `+Validity`.
//

import SwiftUI

@Observable
@MainActor
final class ServiceLogFormModel {
    let vehicle: Vehicle
    let mode: ServiceLogFormMode

    /// The one control that derives intent. Defaults to Today.
    var timing: ServiceTiming

    /// The performed date for `.earlier`.
    var customDate: Date = Date()

    /// When a "Not done yet" reminder fires, and the date for `.date`.
    var dueKind: ServiceDueKind = .interval
    var dueDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now

    var selectedPreset: PresetData?
    var customServiceName: String = ""
    /// Whether the service picker is showing its options, or collapsed to the
    /// chosen service.
    var isPickerOpen: Bool

    var mileageAtService: Int?
    var cost: String = ""
    var costError: String?
    var costCategory: CostCategory = .maintenance
    var notes: String = ""

    /// "Remind me" on a log, "Repeat" on a schedule: whether the service
    /// chains forward after completion.
    var isRecurring: Bool = false
    var pendingAttachments: [AttachmentPicker.AttachmentData] = []

    /// The typed target for a mileage-triggered reminder.
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

    // MARK: Edit-mode state (see `+Edit`)

    var alsoMoveNextReminder = false
    var editBaseline: ServiceLogEditValues?
    /// Logs on this occasion (this one, or its whole visit) that anchor their
    /// service's next reminder. This log first when it is one of them.
    var reminderAnchorLogs: [ServiceLog] = []
    var occasionServiceCount = 1

    /// Pristine-form snapshot, used to tell whether the user has made any real
    /// change (F10: only real edits produce a draft).
    var baselineSnapshot: ServiceFormDraft?

    init(vehicle: Vehicle, mode: ServiceLogFormMode = .log, timing: ServiceTiming = .today) {
        self.vehicle = vehicle
        self.mode = mode
        self.timing = timing
        // The last *confirmed* reading, never the estimate: an untouched Save
        // must not commit a guess as an odometer reading.
        self.mileageAtService = vehicle.currentMileage
        self.isPickerOpen = !mode.isServiceLocked

        switch mode {
        case .log:
            break
        case .complete(let service):
            customServiceName = service.name
            applyScheduleDefaults(preset: nil, match: service)
        case .edit(let log):
            loadForEdit(log)
        }
        // Prefill before capturing the baseline — a prefilled-but-untouched
        // form must not count as dirty.
        rebaseline()
    }

    func rebaseline() {
        baselineSnapshot = contentSnapshot
    }

    // MARK: - Derived intent

    var intent: ServiceIntent { timing.intent }
    var isLogging: Bool { intent == .log }
    var isScheduling: Bool { intent == .schedule }

    var serviceName: String {
        selectedPreset?.name ?? customServiceName
    }

    var performedDate: Date {
        timing.performedDate(explicit: customDate)
    }

    var hasIntervalPolicy: Bool {
        Service.hasIntervalPolicy(intervalMonths: intervalMonths, intervalMiles: intervalMiles)
    }

    /// Whether the entry should chain forward: the toggle plus a real policy.
    var isRecurringSchedule: Bool {
        isRecurring && hasIntervalPolicy
    }

    // MARK: - Choosing a service

    /// Pick a service by name — from Due now, Recent, or typing. A name that
    /// matches a preset takes the preset, so its interval seeds the reminder.
    func choose(name: String) {
        if let preset = presets.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            selectedPreset = preset
            customServiceName = ""
        } else {
            selectedPreset = nil
            customServiceName = name
        }
        isPickerOpen = false
    }

    func choose(preset: PresetData) {
        selectedPreset = preset
        customServiceName = ""
        isPickerOpen = false
    }

    /// Typing in the picker's field replaces any chosen preset.
    func type(name: String) {
        selectedPreset = nil
        customServiceName = name
    }

    // MARK: - Schedule ("Not done yet")

    /// `.interval` without a cadence has nothing to count from, so it falls
    /// back to a date — the chip for it isn't even offered.
    var resolvedDueKind: ServiceDueKind {
        dueKind == .interval && !hasIntervalPolicy ? .date : dueKind
    }

    /// The service's cadence counted from today and the current reading.
    private var intervalProjection: ReminderImpactCalculator.Schedule {
        ReminderImpactCalculator.projected(
            intervalMonths: intervalMonths,
            intervalMiles: intervalMiles,
            anchorDate: .now,
            anchorMileage: vehicle.currentMileage,
            explicitDueDate: nil,
            explicitDueMileage: nil
        )
    }

    /// Drives `Service.dueDate` at save time. Nil while logging.
    var nextDueDate: Date? {
        guard isScheduling else { return nil }
        switch resolvedDueKind {
        case .interval: return intervalProjection.dueDate
        case .date: return dueDate
        case .mileage: return nil
        }
    }

    /// Drives `Service.dueMileage` at save time. Nil while logging.
    var scheduledDueMileage: Int? {
        guard isScheduling else { return nil }
        switch resolvedDueKind {
        case .interval: return intervalProjection.dueMileage
        case .date: return nil
        case .mileage: return nextDueMileage
        }
    }

    // MARK: - Logged recurrence (F4)

    /// The odometer a logged entry is anchored to. A blank field means "at
    /// the reading on file".
    var logAnchorMileage: Int {
        mileageAtService ?? vehicle.currentMileage
    }

    /// The reminder a log will leave behind, or nil when it leaves none. Uses
    /// `ReminderImpactCalculator.projected`, the calculation the save path's
    /// `deriveDueFromIntervals` runs, with the same anchors (F4).
    var nextReminderAfterLog: ReminderImpactCalculator.Schedule? {
        guard isLogging, !mode.isEdit, isRecurringSchedule else { return nil }
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
    /// preset's generic one. A backfilled entry with no match must not inherit
    /// a preset's recurrence and spawn reminders for a service done years ago.
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
        if timing.isBackfill {
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

    /// Remind me is ON by default: a cadence the user just typed under More
    /// details turns it on, unless the entry is backfill.
    func intervalPolicyAppeared() {
        guard !timing.isBackfill else { return }
        isRecurring = true
    }
}

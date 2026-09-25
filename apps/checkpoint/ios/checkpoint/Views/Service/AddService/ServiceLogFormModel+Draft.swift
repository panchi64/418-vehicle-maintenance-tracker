//
//  ServiceLogFormModel+Draft.swift
//  checkpoint
//
//  Drafts (F10) and the prefills that open the form with values already in it.
//

import Foundation

extension ServiceLogFormModel {

    // MARK: - Draft (F10)

    /// Content-only snapshot (fixed timestamp). Drives both `isDirty` and the
    /// view's autosave debounce so the two can never disagree about what
    /// counts as an edit.
    var contentSnapshot: ServiceFormDraft {
        var snapshot = toDraft()
        snapshot.savedAt = .distantPast
        return snapshot
    }

    /// Which stored draft this form reads and writes.
    var draftScope: ServiceFormDraftStore.Scope {
        switch mode {
        case .log: return .newEntry(vehicleID: vehicle.id)
        case .complete(let service): return .completion(serviceID: service.id)
        case .edit(let log): return .edit(logID: log.id)
        }
    }

    func toDraft() -> ServiceFormDraft {
        ServiceFormDraft(
            version: ServiceFormDraft.currentVersion,
            timing: timing,
            customDate: customDate,
            dueKind: dueKind,
            dueDate: dueDate,
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
    /// falling back to the free-typed service name instead. A locked service
    /// (Mark Done, edit) keeps its own name whatever the draft says.
    func apply(_ draft: ServiceFormDraft) {
        timing = draft.timing ?? .today
        if !mode.offersNotYet, timing == .notYet { timing = .today }
        customDate = draft.customDate
        if let kind = draft.dueKind { dueKind = kind }
        if let date = draft.dueDate { dueDate = date }
        if !mode.isServiceLocked {
            if let presetName = draft.presetName, let preset = presets.first(where: { $0.name == presetName }) {
                selectedPreset = preset
                customServiceName = ""
            } else {
                selectedPreset = nil
                customServiceName = draft.serviceName
            }
            isPickerOpen = serviceName.isEmpty
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

    // MARK: - Prefills

    /// Duplicate: the same service, cost, category, notes, and cadence as a
    /// past entry — logged today.
    func applyTemplate(from log: ServiceLog) {
        let template = LoggedServiceTemplate(from: log)
        choose(name: template.serviceName)
        cost = template.costString
        if let category = template.costCategory {
            costCategory = category
        }
        notes = template.notes ?? ""
        intervalMonths = template.intervalMonths
        intervalMiles = template.intervalMiles
        isRecurring = template.hasRecurringIntervals
    }

    /// Seasonal prefills carry a concrete due date, so they land on a dated
    /// reminder.
    func applySeasonalPrefill(_ prefill: SeasonalPrefill) {
        timing = .notYet
        dueKind = .date
        choose(name: prefill.serviceName)
        dueDate = prefill.dueDate
        intervalMonths = prefill.intervalMonths
        isRecurring = true
    }

    /// "Schedule next" from the logged toast: the next occurrence of what was
    /// just done. With a cadence it lands on the interval (the completion was
    /// just now, at the current reading, so "in 6 mo / 5,000 mi" counts from
    /// the same anchors); without one, on a date to pick.
    func applyPostRecordPrefill(_ prefill: PostRecordPrefill) {
        choose(name: prefill.serviceName)
        intervalMonths = prefill.intervalMonths
        intervalMiles = prefill.intervalMiles
        isRecurring = hasIntervalPolicy
        timing = .notYet
        dueKind = hasIntervalPolicy ? .interval : .date
    }
}

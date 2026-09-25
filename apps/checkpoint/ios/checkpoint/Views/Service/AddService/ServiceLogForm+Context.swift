//
//  ServiceLogForm+Context.swift
//  checkpoint
//
//  What the form derives (the service it completes, its title) and loads when
//  it opens — presets, a prefill or a draft, an edited entry's neighbors.
//

import SwiftUI

extension ServiceLogForm {

    /// Opened with values already in it (seasonal, "Schedule next", Duplicate).
    var hasExplicitPrefill: Bool {
        seasonalPrefill != nil || postRecordPrefill != nil || duplicating != nil
    }

    /// The stored draft this form reads and writes (F10), or nil when it has
    /// none. A prefilled form never drafts, so it must not clear one either:
    /// that draft belongs to an unfinished [+] entry — on a Duplicate moved to
    /// another vehicle, to that vehicle's.
    var draftScope: ServiceFormDraftStore.Scope? {
        hasExplicitPrefill ? nil : model.draftScope
    }

    func clearDraft() {
        if let draftScope { ServiceFormDraftStore.clear(draftScope) }
    }

    /// The tracked service this entry completes instead of duplicating.
    var logTarget: Service? {
        if let service = model.mode.completing { return service }
        guard model.isLogging, !model.mode.isEdit else { return nil }
        return services.activeMatch(
            named: model.serviceName,
            for: vehicle,
            performedDate: model.performedDate,
            logs: serviceLogs
        )
    }

    var title: String {
        if model.mode.isEdit { return L10n.formTitleEdit }
        if model.isScheduling { return L10n.formTitleSchedule }
        if model.mode.completing != nil || logTarget != nil { return L10n.formTitleComplete }
        return L10n.formTitleLog
    }

    var screen: AnalyticsEvent.ScreenName {
        switch model.mode {
        case .log: return .addService
        case .complete: return .markServiceDone
        case .edit: return .editServiceLog
        }
    }

    func prepare() {
        guard model.presets.isEmpty else { return }
        model.presets = PresetDataService.shared.loadPresets()
        if let seasonalPrefill { model.applySeasonalPrefill(seasonalPrefill) }
        if let postRecordPrefill { model.applyPostRecordPrefill(postRecordPrefill) }
        if let duplicating { model.applyTemplate(from: duplicating) }
        if let draftScope {
            draftResumeBanner = ServiceFormDraftStore.load(draftScope)
        } else {
            // The prefill is the starting point, not an edit to protect.
            model.rebaseline()
        }
        // After the baseline: what the user entered before switching vehicles
        // is still their edit, and the form stays dirty for it.
        if let carryover {
            model.apply(carryover.draft)
            model.pendingAttachments = carryover.attachments
        }
        if let log = model.mode.editing {
            let chronological = Array(serviceLogs.reversed())
            if let index = chronological.firstIndex(where: { $0.id == log.id }) {
                adjacentLogs = (
                    index > 0 ? chronological[index - 1] : nil,
                    index < chronological.count - 1 ? chronological[index + 1] : nil
                )
            }
        }
    }

    /// Duplicate only: rebuild the form on `target`, keeping what's entered.
    func retarget(to target: Vehicle, via choice: ServiceLogVehicleChoice) {
        choice.select(target, ServiceLogCarryover(
            draft: model.carryover(to: target),
            attachments: model.pendingAttachments
        ))
    }

    // MARK: - Edit context (F8)

    var anchors: ServiceFormAnchors {
        ServiceFormAnchors(
            vehicle: vehicle,
            logs: serviceLogs,
            serviceName: model.serviceName,
            performedDate: model.performedDate,
            enteredMileage: model.mileageAtService,
            enteredCostString: model.cost,
            excludingLogID: model.mode.editing?.id
        )
    }

    /// Omits whichever half doesn't exist — the earliest/latest log for a
    /// vehicle only has one neighbor (F8).
    var editContextLine: String? {
        func summary(_ log: ServiceLog) -> String {
            L10n.formLogSummary(
                Formatters.mileage(log.mileageAtService),
                Formatters.shortDate.string(from: log.performedDate)
            )
        }
        switch adjacentLogs {
        case let (before?, after?): return L10n.editBetweenLogs(summary(before), summary(after))
        case let (before?, nil): return L10n.editSinceLog(summary(before))
        case let (nil, after?): return L10n.editBeforeLog(summary(after))
        case (nil, nil): return nil
        }
    }
}

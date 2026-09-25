//
//  ServicePickerSection.swift
//  checkpoint
//
//  The form's first answer: which service.
//
//  ORDERED BY LIKELIHOOD. Due-now services first, with their status, because
//  "which one is overdue" is usually why the form was opened; then services
//  logged recently; then Browse all. Typing a name is always available and
//  narrows both lists. Both lists are ROWS, not chips: as chips the recent
//  names were a second option vocabulary in one picker, shouted in caps.
//
//  Once chosen, the picker collapses to one row with Change — the list has done
//  its job and would otherwise push every other field below the fold. Change is
//  the one way to undo a choice. Mark Done and edit lock the service: there is
//  nothing to change.
//

import SwiftUI

struct ServicePickerSection: View {
    @Bindable var model: ServiceLogFormModel
    /// Vehicle-scoped, from the form's query.
    let services: [Service]
    /// Vehicle-scoped, newest first.
    let logs: [ServiceLog]
    /// The tracked service saving will complete, if any.
    let completing: Service?
    /// Edit: where this entry sits among its neighbours (F8).
    let contextLine: String?
    /// F2: shown after a tap on the dim Save.
    let blocker: String?

    @State private var isBrowsing = false

    private var query: String {
        model.serviceName.trimmingCharacters(in: .whitespaces)
    }

    private func matchesQuery(_ name: String) -> Bool {
        query.isEmpty || name.localizedCaseInsensitiveContains(query)
    }

    /// Overdue and due-soon services, most urgent first.
    private var dueNow: [(service: Service, status: ServiceStatus, remaining: String?)] {
        let estimate = model.vehicle.mileageEstimate
        return services.sortedByUrgency(estimate).compactMap { service in
            let status = service.status(currentMileage: estimate.effective)
            guard status == .overdue || status == .dueSoon, matchesQuery(service.name) else { return nil }
            return (service, status, service.urgencyText(currentMileage: estimate.effective))
        }
    }

    /// Distinct recently logged names not already offered under Due now.
    private func recent(excluding dueNames: Set<String>) -> [(name: String, date: Date)] {
        var seen = dueNames
        var result: [(name: String, date: Date)] = []
        for log in logs {
            guard let name = log.service?.name else { continue }
            let key = name.lowercased()
            guard !seen.contains(key), matchesQuery(name) else { continue }
            seen.insert(key)
            result.append((name, log.performedDate))
            if result.count == 3 { break }
        }
        return result
    }

    var body: some View {
        FormSection(title: L10n.formSectionService) {
            if let blocker {
                FormAdvisory.blocking(blocker)
            }

            if model.isPickerOpen {
                picker
            } else {
                selectedRow
            }

            if let contextLine {
                Text(contextLine)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Stated, not asked: logging a service that is on the schedule
            // completes it, exactly as Mark Done would.
            if let completing, !model.isPickerOpen, model.isLogging, !model.mode.isEdit {
                FormAdvisory.info(Self.completesAdvisory(for: completing, vehicle: model.vehicle))
            }
        }
        .sheet(isPresented: $isBrowsing) {
            ServicePresetPickerSheet(selectedName: model.serviceName) { preset in
                model.choose(preset: preset)
            }
        }
    }

    /// "Completes Oil Change — 400 mi overdue". Urgency is judged against the
    /// same effective mileage the Services list uses, so the two agree.
    static func completesAdvisory(for service: Service, vehicle: Vehicle) -> String {
        guard let urgency = service.urgencyText(currentMileage: vehicle.mileageEstimate.effective) else {
            return L10n.formCompletesService(service.name)
        }
        return L10n.formCompletesServiceWithStatus(service.name, urgency)
    }

    // MARK: - Open

    @ViewBuilder
    private var picker: some View {
        InstrumentTextField(
            label: nil,
            text: Binding(get: { model.serviceName }, set: { model.type(name: $0) }),
            placeholder: L10n.formServiceSearchPlaceholder,
            autocapitalization: .words
        )

        let due = dueNow
        if !due.isEmpty {
            FormSubgroup(title: L10n.formDueNow) {
                VStack(spacing: 0) {
                    ForEach(due, id: \.service.id) { item in
                        PickRow(name: item.service.name) {
                            model.choose(name: item.service.name)
                        } trailing: {
                            HStack(spacing: Spacing.sm) {
                                StatusTag(status: item.status)
                                if let remaining = item.remaining {
                                    Text(remaining)
                                        .font(.brutalistSecondary)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }

        let recentItems = recent(excluding: Set(due.map { $0.service.name.lowercased() }))
        if !recentItems.isEmpty {
            FormSubgroup(title: L10n.formRecent) {
                VStack(spacing: 0) {
                    ForEach(recentItems, id: \.name) { item in
                        PickRow(name: item.name) {
                            model.choose(name: item.name)
                        } trailing: {
                            Text(Formatters.shortDate.string(from: item.date))
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
            }
        }

        Button {
            isBrowsing = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(L10n.formBrowseAll)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.accent)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: TouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Collapsed

    /// No status tag here: the `.info` line beneath already says it, and saying
    /// it twice was the first thing the eye hit.
    private var selectedRow: some View {
        HStack(spacing: Spacing.sm) {
            Text(model.serviceName)
                .font(.brutalistBodyEmphasis)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !model.mode.isServiceLocked {
                Button {
                    model.isPickerOpen = true
                    HapticService.shared.selectionChanged()
                } label: {
                    Text(L10n.formChange)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.accent)
                        .frame(minHeight: TouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.formChangeService(model.serviceName))
            }
        }
        .frame(minHeight: TouchTarget.minimum)
    }
}

/// One option in the service picker: name leading, context trailing.
private struct PickRow<Trailing: View>: View {
    let name: String
    let action: () -> Void
    @ViewBuilder let trailing: Trailing

    var body: some View {
        Button {
            HapticService.shared.selectionChanged()
            action()
        } label: {
            AdaptiveStack(horizontalSpacing: Spacing.sm, verticalSpacing: Spacing.xs) {
                Text(name)
                    .font(.brutalistBodyEmphasis)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                AdaptiveSpacer()
                trailing
            }
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum, alignment: .leading)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

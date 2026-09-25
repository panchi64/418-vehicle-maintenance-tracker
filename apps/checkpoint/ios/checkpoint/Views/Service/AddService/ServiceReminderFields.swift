//
//  ServiceReminderFields.swift
//  checkpoint
//
//  "Due" — the "Not done yet" branch: when the reminder fires, and whether it
//  comes back.
//
//  The service's own interval is the default ("In 6 mo / 5,000 mi"), so
//  scheduling is saveable the moment "Not done yet" is tapped. A date or a
//  mileage are one chip away. The Fires line is the proof the reminder will
//  actually fire — the point of the surface — so it is a readout, not an
//  advisory.
//

import SwiftUI

struct ServiceReminderFields: View {
    @Bindable var model: ServiceLogFormModel
    /// F2: shown after a tap on the dim Save.
    let blocker: String?

    private var intervalText: String? {
        Formatters.serviceInterval(months: model.intervalMonths, miles: model.intervalMiles)
    }

    private var repeatDetail: String {
        guard let intervalText else { return L10n.formSetIntervalInDetails }
        return L10n.formEveryInterval(intervalText)
    }

    private var kinds: [ServiceDueKind] {
        model.hasIntervalPolicy ? [.interval, .date, .mileage] : [.date, .mileage]
    }

    private func label(for kind: ServiceDueKind) -> String {
        switch kind {
        case .interval: return L10n.formDueInInterval(intervalText ?? "")
        case .date: return L10n.timingOnDate
        case .mileage: return L10n.timingAtMileage
        }
    }

    var body: some View {
        FormSection(title: L10n.formSectionDue) {
            if let blocker {
                FormAdvisory.blocking(blocker)
            }

            WrappingChipRow(
                items: kinds,
                label: label(for:),
                isSelected: { model.resolvedDueKind == $0 },
                onTap: { kind in
                    model.dueKind = kind
                    HapticService.shared.selectionChanged()
                }
            )

            switch model.resolvedDueKind {
            case .interval:
                EmptyView()
            case .date:
                InstrumentDatePicker(label: L10n.formDueDate, date: $model.dueDate)
            case .mileage:
                InstrumentNumberField(
                    label: L10n.formRemindMeAt,
                    value: $model.nextDueMileage,
                    placeholder: Formatters.mileageNumber(model.vehicle.currentMileage + 5000),
                    suffix: DistanceSettings.shared.unit.abbreviation,
                    requirement: .required(reason: L10n.formRemindMileageRequired)
                )
            }

            fireTimeReadout

            VStack(alignment: .leading, spacing: 2) {
                LabeledInstrumentToggle(
                    label: L10n.formRepeatAfterCompletion,
                    accessibilityLabel: L10n.formRepeatAfterCompletion,
                    isOn: $model.isRecurring
                )
                Text(repeatDetail)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Fire time

    private var fireTime: (text: String, isKnown: Bool) {
        switch model.resolvedDueKind {
        case .interval:
            let schedule = ReminderImpactCalculator.Schedule(
                dueDate: model.nextDueDate,
                dueMileage: model.scheduledDueMileage
            )
            if let text = LoggedReminderFields.dateOrMileage(schedule) { return (text, true) }
            return (L10n.formFiresOnceYouPickDate, false)
        case .date:
            return (Formatters.mediumDate.string(from: model.dueDate), true)
        case .mileage:
            guard let target = model.nextDueMileage else {
                return (L10n.formFiresOnceYouEnterMileage, false)
            }
            let remaining = max(target - model.vehicle.currentMileage, 0)
            guard let pace = model.vehicle.dailyMilesPace, pace > 0 else {
                return (L10n.formFiresAtMileage(Formatters.mileage(target)), true)
            }
            let days = Int(ceil(Double(remaining) / pace))
            return (L10n.formFiresAtMileageInDays(Formatters.mileage(target), days), true)
        }
    }

    private var fireTimeReadout: some View {
        let fire = fireTime
        return AdaptiveStack(
            verticalAlignment: .firstTextBaseline,
            horizontalSpacing: Spacing.md,
            verticalSpacing: Spacing.xs
        ) {
            Text(L10n.formFires.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)
                .fixedSize(horizontal: true, vertical: false)

            Text(fire.text)
                .font(.brutalistBodyEmphasis)
                .foregroundStyle(fire.isKnown ? Theme.textPrimary : Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

//
//  ServiceReminderFields.swift
//  checkpoint
//
//  The future branch of the unified form: what makes the reminder fire, and
//  whether it comes back.
//
//  THE REPEAT POLICY IS ON THE DEFAULT PATH. It used to live inside a
//  `CollapsibleDetailsSection` — hiding the thing that makes the feature work,
//  which is the inversion this refactor exists to fix. Notes and receipts make
//  an entry *complete* and stay in depth; an interval makes a reminder *recur*.
//

import SwiftUI

struct ServiceReminderFields: View {
    @Bindable var model: AddServiceFormModel
    /// Resolved once per render by the parent; downstream suggestions read
    /// from this captured log instead of re-running the lookup.
    let lastLog: ServiceLog?

    private var policyMonths: Int? {
        (lastLog?.service?.intervalMonths).flatMap { $0 > 0 ? $0 : nil }
    }

    private var policyMiles: Int? {
        (lastLog?.service?.intervalMiles).flatMap { $0 > 0 ? $0 : nil }
    }

    private var projectedDueMileage: Int? {
        lastLog.flatMap { log in policyMiles.map { log.mileageAtService + $0 } }
    }

    var body: some View {
        FormSection(title: L10n.formTheReminder) {
            if model.timing?.isMileageTriggered == true {
                mileageTrigger
            }

            repeatPolicy
            fireTimeReadout
        }
    }

    // MARK: - Mileage trigger

    @ViewBuilder
    private var mileageTrigger: some View {
        InstrumentNumberField(
            label: L10n.formRemindMeAt,
            value: $model.nextDueMileage,
            placeholder: Formatters.mileageNumber(model.vehicle.currentMileage + 5000),
            suffix: DistanceSettings.shared.unit.abbreviation,
            requirement: .required(reason: L10n.formRemindMileageRequired)
        )

        ScrollingChipRow(items: ServiceFormChips.mileageOffsetChips, label: \.label) { chip in
            model.nextDueMileage = model.vehicle.currentMileage + chip.miles
            HapticService.shared.selectionChanged()
        }

        if model.nextDueMileage == nil, let suggested = projectedDueMileage {
            SuggestedValueRow(label: L10n.formSuggestValue(Formatters.mileage(suggested))) {
                model.nextDueMileage = suggested
            }
        }
    }

    // MARK: - Repeat policy

    @ViewBuilder
    private var repeatPolicy: some View {
        LabeledInstrumentToggle(
            label: L10n.formRepeatAfterCompletion,
            accessibilityLabel: L10n.formRepeatAfterCompletion,
            isOn: $model.isRecurring
        )

        if model.isRecurring {
            // Wraps to two rows at large type: a fixed two-column split cannot
            // survive Dynamic Type on a 375pt screen — forcing it crushed one
            // label to 28px against a 46px word.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    intervalMonthsField
                    intervalMilesField
                }
                VStack(alignment: .leading, spacing: Spacing.md) {
                    intervalMonthsField
                    intervalMilesField
                }
            }

            Text(L10n.formWhicheverFirstFromCompletion)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !model.hasIntervalPolicy {
                SanityWarningRow(message: L10n.recordSetIntervalHint)
            }
        } else {
            Text(L10n.formRemindsOnceThenStops)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var intervalMonthsField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            InstrumentNumberField(
                label: L10n.formEvery,
                value: $model.intervalMonths,
                placeholder: "6",
                suffix: L10n.formMonthsSuffix
            )
            if model.intervalMonths == nil, let suggested = policyMonths {
                SuggestedValueRow(label: L10n.formSuggestMonths(suggested)) {
                    model.intervalMonths = suggested
                }
            }
        }
    }

    private var intervalMilesField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            InstrumentNumberField(
                label: L10n.formOrEvery,
                value: $model.intervalMiles,
                placeholder: "5000",
                suffix: L10n.formMilesSuffix
            )
            if model.intervalMiles == nil, let suggested = policyMiles {
                SuggestedValueRow(label: L10n.formSuggestValue(Formatters.mileage(suggested))) {
                    model.intervalMiles = suggested
                }
            }
        }
    }

    // MARK: - Fire time

    /// When the reminder will fire, and whether that is yet knowable.
    ///
    /// THIS IS A READOUT, NOT AN ADVISORY. It was an `.info` advisory, which
    /// made the most important line on the screen the quietest thing on it —
    /// this is the proof that the reminder will actually fire, which is the
    /// entire point of the surface. The severity ladder is for things needing
    /// attention or resolution; a projected outcome is a value, so it gets a
    /// label and emphasis weight instead.
    private var fireTime: (text: String, isKnown: Bool) {
        if model.timing?.isMileageTriggered == true {
            guard let target = model.nextDueMileage else {
                return (L10n.formFiresOnceYouEnterMileage, false)
            }
            let remaining = max(target - model.vehicle.currentMileage, 0)
            guard let pace = model.vehicle.dailyMilesPace, pace > 0 else {
                return (L10n.formFiresAtMileage(Formatters.mileage(target)), true)
            }
            let days = Int(ceil(Double(remaining) / pace))
            return (
                L10n.formFiresAtMileageInDays(Formatters.mileage(target), days),
                true
            )
        }

        guard let due = model.nextDueDate else {
            return (L10n.formFiresOnceYouPickDate, false)
        }
        return (Formatters.mediumDate.string(from: due), true)
    }

    private var fireTimeReadout: some View {
        let fire = fireTime
        return HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
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
        .padding(.top, Spacing.sm)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.gridLine)
                .frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

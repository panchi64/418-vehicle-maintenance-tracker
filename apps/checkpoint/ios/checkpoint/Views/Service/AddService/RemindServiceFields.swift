import SwiftUI

struct RemindServiceFields: View {
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

    /// G5: this is the only path that produces the Service's initial due
    /// tracking (unlike record mode, intervals here only govern the *next*
    /// occurrence after this reminder is completed).
    private var hasComputableSchedule: Bool {
        model.hasCustomDate || model.nextDueMileage != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: L10n.formNextDue)

            VStack(spacing: Spacing.md) {
                ChipRow(items: ServiceFormChips.fuzzyDateChips, label: \.label) { chip in
                    model.hasCustomDate = true
                    model.dueDate = chip.date
                    HapticService.shared.selectionChanged()
                }

                LabeledInstrumentToggle(
                    label: L10n.formSetDueDate.uppercased(),
                    accessibilityLabel: L10n.formSetDueDate,
                    isOn: $model.hasCustomDate
                )

                if model.hasCustomDate {
                    InstrumentDatePicker(label: L10n.formDueDate, date: $model.dueDate)
                }

                InstrumentNumberField(
                    label: L10n.formDueMileage,
                    value: $model.nextDueMileage,
                    placeholder: L10n.formOptionalTag,
                    suffix: DistanceSettings.shared.unit.abbreviation
                )

                ChipRow(items: ServiceFormChips.mileageOffsetChips, label: \.label) { chip in
                    model.nextDueMileage = model.vehicle.currentMileage + chip.miles
                    HapticService.shared.selectionChanged()
                }

                if model.nextDueMileage == nil, let suggested = projectedDueMileage {
                    SuggestedValueRow(label: L10n.formSuggestValue(Formatters.mileage(suggested))) {
                        model.nextDueMileage = suggested
                    }
                }

                if let nextDueDate = model.nextDueDate, nextDueDate < Date.now {
                    Text(L10n.formDatePastWarning)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let countdown = countdownText(date: model.nextDueDate, mileage: model.nextDueMileage) {
                    Text(countdown.text)
                        .font(.brutalistSecondary)
                        .foregroundStyle(countdown.isOverdue ? Theme.statusOverdue : Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let nextDueDate = model.nextDueDate, let nextDueMileage = model.nextDueMileage {
                    whicheverFirstSummary(date: nextDueDate, mileage: nextDueMileage, pace: model.vehicle.dailyMilesPace)
                }
            }
        }

        if !hasComputableSchedule {
            SanityWarningRow(message: L10n.remindNoScheduleWarning)
        }

        CollapsibleDetailsSection(
            storageKey: "formDetailsAddServiceRemind",
            filledCount: detailsFilledCount
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: L10n.formRepeats)

                    VStack(spacing: Spacing.md) {
                        LabeledInstrumentToggle(
                            label: L10n.formRepeatAfterCompletion.uppercased(),
                            accessibilityLabel: L10n.formRepeatAfterCompletion,
                            isOn: $model.isRecurring
                        )

                        if model.isRecurring {
                            ChipRow(items: ServiceFormChips.monthIntervalChips, label: \.label) { chip in
                                model.intervalMonths = chip.months
                                HapticService.shared.selectionChanged()
                            }

                            InstrumentNumberField(label: L10n.formEvery, value: $model.intervalMonths, placeholder: "6", suffix: L10n.formMonthsSuffix)
                            if model.intervalMonths == nil, let suggested = policyMonths {
                                SuggestedValueRow(label: L10n.formSuggestMonths(suggested)) {
                                    model.intervalMonths = suggested
                                }
                            }

                            ChipRow(items: ServiceFormChips.mileageIntervalChips, label: \.label) { chip in
                                model.intervalMiles = chip.miles
                                HapticService.shared.selectionChanged()
                            }

                            InstrumentNumberField(label: L10n.formOrEvery, value: $model.intervalMiles, placeholder: "5000", suffix: L10n.formMilesSuffix)
                            if model.intervalMiles == nil, let suggested = policyMiles {
                                SuggestedValueRow(label: L10n.formSuggestValue(Formatters.mileage(suggested))) {
                                    model.intervalMiles = suggested
                                }
                            }

                            if let preview = recurrencePolicyPreview {
                                Text(preview)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Theme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: L10n.formNotes)
                    RichNotesEditor(label: L10n.formNotes, text: $model.remindNotes, placeholder: L10n.formNotesPlaceholder, minHeight: 100)
                }
            }
        }
    }

    private var detailsFilledCount: Int {
        var count = 0
        if model.isRecurring { count += 1 }
        if !model.remindNotes.isEmpty { count += 1 }
        return count
    }

    private func whicheverFirstSummary(date: Date, mileage: Int, pace: Double?) -> some View {
        let dateLeads = dateTriggerLeads(date: date, mileage: mileage, pace: pace)
        let dateText = Formatters.mediumDate.string(from: date)
        let mileageText = Formatters.mileage(mileage)

        return VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(L10n.formWhicheverFirst)
                .textCase(.uppercase)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            HStack(spacing: Spacing.sm) {
                triggerCell(text: dateText, isLeading: dateLeads)
                Text(L10n.formOr)
                    .textCase(.uppercase)
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                triggerCell(text: mileageText, isLeading: !dateLeads)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceInstrument)
        .brutalistBorder()
    }

    private func triggerCell(text: String, isLeading: Bool) -> some View {
        HStack(spacing: Spacing.xs) {
            if isLeading {
                Text("◆")
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.accent)
            }
            Text(text)
                .font(.brutalistBody)
                .foregroundStyle(isLeading ? Theme.accent : Theme.textSecondary)
        }
    }

    /// Returns true if the date trigger fires before the mileage trigger.
    /// When pace is unavailable, the date is treated as leading — the user
    /// still sees both values side-by-side, so the visual emphasis simply
    /// defaults to the explicit calendar trigger.
    private func dateTriggerLeads(date: Date, mileage: Int, pace: Double?) -> Bool {
        guard let pace, pace > 0 else { return true }
        let milesRemaining = max(mileage - model.vehicle.currentMileage, 0)
        // ceil, matching Service.predictedDueDate — the urgency engine and
        // this preview must agree on which trigger fires first.
        let daysUntilMileage = Int(ceil(Double(milesRemaining) / pace))
        let daysUntilDate = Calendar.current.dateComponents([.day], from: Date.now, to: date).day ?? Int.max
        return daysUntilDate <= daysUntilMileage
    }

    private var recurrencePolicyPreview: String? {
        var parts: [String] = []
        if let months = model.intervalMonths, months > 0 {
            parts.append(months == 1 ? L10n.formEveryMonth : L10n.formEveryNMonths(months))
        }
        if let miles = model.intervalMiles, miles > 0 {
            parts.append(L10n.formEveryMileage(Formatters.mileage(miles)))
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " \(L10n.formOr) ")
    }

    /// Returns nil when neither trigger is set so the strip doesn't render.
    private func countdownText(date: Date?, mileage: Int?) -> (text: String, isOverdue: Bool)? {
        var parts: [String] = []
        var isOverdue = false

        if let date {
            let days = Calendar.current.dateComponents([.day], from: Date.now, to: date).day ?? 0
            if days < 0 {
                parts.append(L10n.formDaysOverdue(-days))
                isOverdue = true
            } else {
                parts.append(L10n.formDaysAhead(days))
            }
        }

        if let mileage {
            let delta = mileage - model.vehicle.currentMileage
            if delta < 0 {
                parts.append(L10n.formMileagePast(Formatters.mileage(-delta)))
                isOverdue = true
            } else {
                parts.append(L10n.formMileageAhead(Formatters.mileage(delta)))
            }
        }

        guard !parts.isEmpty else { return nil }
        return (parts.joined(separator: " · "), isOverdue)
    }
}

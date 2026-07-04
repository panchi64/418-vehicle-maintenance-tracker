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
            InstrumentSectionHeader(title: "Next Due")

            VStack(spacing: Spacing.md) {
                ChipRow(items: ServiceFormChips.fuzzyDateChips, label: \.label) { chip in
                    model.hasCustomDate = true
                    model.dueDate = chip.date
                    HapticService.shared.selectionChanged()
                }

                LabeledInstrumentToggle(
                    label: "SET DUE DATE",
                    accessibilityLabel: "Set due date",
                    isOn: $model.hasCustomDate
                )

                if model.hasCustomDate {
                    InstrumentDatePicker(label: "Due Date", date: $model.dueDate)
                }

                InstrumentNumberField(
                    label: "Due Mileage",
                    value: $model.nextDueMileage,
                    placeholder: "Optional",
                    suffix: DistanceSettings.shared.unit.abbreviation
                )

                ChipRow(items: ServiceFormChips.mileageOffsetChips, label: \.label) { chip in
                    model.nextDueMileage = model.vehicle.currentMileage + chip.miles
                    HapticService.shared.selectionChanged()
                }

                if model.nextDueMileage == nil, let suggested = projectedDueMileage {
                    SuggestedValueRow(label: "Suggest \(Formatters.mileage(suggested))") {
                        model.nextDueMileage = suggested
                    }
                }

                if let nextDueDate = model.nextDueDate, nextDueDate < Date.now {
                    Text("This date is in the past — will be marked overdue.")
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
                    InstrumentSectionHeader(title: "Repeats")

                    VStack(spacing: Spacing.md) {
                        LabeledInstrumentToggle(
                            label: "REPEAT AFTER COMPLETION",
                            accessibilityLabel: "Repeat after completion",
                            isOn: $model.isRecurring
                        )

                        if model.isRecurring {
                            ChipRow(items: ServiceFormChips.monthIntervalChips, label: \.label) { chip in
                                model.intervalMonths = chip.months
                                HapticService.shared.selectionChanged()
                            }

                            InstrumentNumberField(label: "Every", value: $model.intervalMonths, placeholder: "6", suffix: "months")
                            if model.intervalMonths == nil, let suggested = policyMonths {
                                SuggestedValueRow(label: "Suggest \(suggested) months") {
                                    model.intervalMonths = suggested
                                }
                            }

                            ChipRow(items: ServiceFormChips.mileageIntervalChips, label: \.label) { chip in
                                model.intervalMiles = chip.miles
                                HapticService.shared.selectionChanged()
                            }

                            InstrumentNumberField(label: "Or Every", value: $model.intervalMiles, placeholder: "5000", suffix: "miles")
                            if model.intervalMiles == nil, let suggested = policyMiles {
                                SuggestedValueRow(label: "Suggest \(Formatters.mileage(suggested))") {
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
                    InstrumentSectionHeader(title: "Notes")
                    RichNotesEditor(label: "Notes", text: $model.remindNotes, placeholder: "Add notes...", minHeight: 100)
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
            Text("WHICHEVER COMES FIRST")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            HStack(spacing: Spacing.sm) {
                triggerCell(text: dateText, isLeading: dateLeads)
                Text("OR")
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
        let daysUntilMileage = Int((Double(milesRemaining) / pace).rounded())
        let daysUntilDate = Calendar.current.dateComponents([.day], from: Date.now, to: date).day ?? Int.max
        return daysUntilDate <= daysUntilMileage
    }

    private var recurrencePolicyPreview: String? {
        var parts: [String] = []
        if let months = model.intervalMonths, months > 0 {
            parts.append(months == 1 ? "every month" : "every \(months) months")
        }
        if let miles = model.intervalMiles, miles > 0 {
            parts.append("every \(Formatters.mileage(miles))")
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " or ")
    }

    /// Returns nil when neither trigger is set so the strip doesn't render.
    private func countdownText(date: Date?, mileage: Int?) -> (text: String, isOverdue: Bool)? {
        var parts: [String] = []
        var isOverdue = false

        if let date {
            let days = Calendar.current.dateComponents([.day], from: Date.now, to: date).day ?? 0
            if days < 0 {
                parts.append("\(-days) days overdue")
                isOverdue = true
            } else {
                parts.append("~\(days) days")
            }
        }

        if let mileage {
            let delta = mileage - model.vehicle.currentMileage
            if delta < 0 {
                parts.append("\(Formatters.mileage(-delta)) past")
                isOverdue = true
            } else {
                parts.append("~\(Formatters.mileage(delta)) ahead")
            }
        }

        guard !parts.isEmpty else { return nil }
        return (parts.joined(separator: " · "), isOverdue)
    }
}

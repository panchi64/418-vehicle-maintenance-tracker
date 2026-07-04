import SwiftUI

struct RecordServiceFields: View {
    @Bindable var model: AddServiceFormModel
    let anchors: ServiceFormAnchors

    /// Never shown when there's nothing computable to project (G5). Uses the
    /// same projection as the save path, so the preview can't disagree with
    /// the reminder that actually gets scheduled.
    private var nextDuePreview: String? {
        guard model.isRecurring, model.hasIntervalPolicy else { return nil }
        let projected = ReminderImpactCalculator.projected(
            intervalMonths: model.intervalMonths,
            intervalMiles: model.intervalMiles,
            anchorDate: model.performedDate,
            anchorMileage: model.mileageAtService ?? model.vehicle.currentMileage,
            explicitDueDate: nil,
            explicitDueMileage: nil
        )

        var parts: [String] = []
        if let nextDate = projected.dueDate {
            parts.append(Formatters.shortDate.string(from: nextDate))
        }
        if let nextMileage = projected.dueMileage {
            parts.append(L10n.formAtMileage(Formatters.mileage(nextMileage)))
        }

        guard !parts.isEmpty else { return nil }
        return L10n.formNextDuePreview(parts.joined(separator: " \(L10n.formOr) "))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: L10n.formDatePerformed)
            InstrumentDatePicker(label: L10n.formDatePerformed, date: $model.performedDate)
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: L10n.formCost)

            VStack(spacing: Spacing.md) {
                InstrumentTextField(
                    label: L10n.formAmount,
                    text: $model.cost,
                    placeholder: "0.00",
                    keyboardType: .decimalPad
                )
                .onChange(of: model.cost) { _, newValue in
                    model.cost = CostValidation.filterCostInput(newValue)
                    model.costError = CostValidation.validate(model.cost)
                }

                if let hint = anchors.priorCostHint {
                    Text(hint)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(hint)
                }

                if let warning = anchors.costWarning {
                    SanityWarningRow(message: warning)
                }

                if let costError = model.costError {
                    ErrorMessageRow(message: costError) {
                        model.costError = nil
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(L10n.formCategory)
                        .textCase(.uppercase)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)

                    InstrumentSegmentedControl(
                        options: CostCategory.allCases,
                        selection: $model.costCategory
                    ) { $0.displayName }
                }
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: L10n.formMileage)

            InstrumentNumberField(
                label: L10n.formMileage,
                value: $model.mileageAtService,
                placeholder: L10n.formOptionalTag,
                suffix: DistanceSettings.shared.unit.abbreviation
            )

            if model.mileageAtService == nil {
                Text(L10n.formMileageBlankHint)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let warning = anchors.mileageWarning {
                SanityWarningRow(message: warning)
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: L10n.formReminder)

            VStack(spacing: Spacing.sm) {
                LabeledInstrumentToggle(
                    label: L10n.formRemindNextTime.uppercased(),
                    accessibilityLabel: L10n.formRemindNextTime,
                    isOn: $model.isRecurring
                )

                if model.isRecurring {
                    Text(L10n.reminderHelperText)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let preview = nextDuePreview {
                        Text(preview)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !model.hasIntervalPolicy {
                        Text(L10n.recordSetIntervalHint)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ChipRow(items: ServiceFormChips.monthIntervalChips, label: \.label) { chip in
                            model.intervalMonths = chip.months
                            HapticService.shared.selectionChanged()
                        }

                        ChipRow(items: ServiceFormChips.mileageIntervalChips, label: \.label) { chip in
                            model.intervalMiles = chip.miles
                            HapticService.shared.selectionChanged()
                        }

                        SanityWarningRow(message: L10n.remindNoScheduleWarning)
                    }
                }
            }
        }

        CollapsibleDetailsSection(
            storageKey: "formDetailsAddServiceRecord",
            filledCount: detailsFilledCount
        ) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: L10n.formNotes)
                    RichNotesEditor(label: L10n.formNotes, text: $model.recordNotes, placeholder: L10n.formNotesPlaceholder, minHeight: 100)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    InstrumentSectionHeader(title: L10n.formAttachments)
                    AttachmentPicker(attachments: $model.pendingAttachments)
                }
            }
        }
    }

    private var detailsFilledCount: Int {
        var count = 0
        if !model.recordNotes.isEmpty { count += 1 }
        if !model.pendingAttachments.isEmpty { count += 1 }
        return count
    }
}

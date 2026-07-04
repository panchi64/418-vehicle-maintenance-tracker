import SwiftUI

struct RecordServiceFields: View {
    @Bindable var model: AddServiceFormModel
    let anchors: ServiceFormAnchors
    let onSaveAndAddAnother: () -> Void

    private var nextDuePreview: String? {
        guard model.isRecurring else { return nil }
        var parts: [String] = []

        if let months = model.intervalMonths, months > 0,
           let nextDate = Calendar.current.date(byAdding: .month, value: months, to: model.performedDate) {
            parts.append(Formatters.shortDate.string(from: nextDate))
        }

        if let miles = model.intervalMiles, miles > 0, let currentMileage = model.mileageAtService {
            parts.append("at \(Formatters.mileage(currentMileage + miles))")
        }

        guard !parts.isEmpty else { return nil }
        return "Next due: \(parts.joined(separator: " or "))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Date Performed")
            InstrumentDatePicker(label: "Date Performed", date: $model.performedDate)
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Cost")

            VStack(spacing: Spacing.md) {
                InstrumentTextField(
                    label: "Amount",
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
                    Text("CATEGORY")
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
            InstrumentSectionHeader(title: "Mileage")

            InstrumentNumberField(
                label: "Mileage",
                value: $model.mileageAtService,
                placeholder: "Optional",
                suffix: DistanceSettings.shared.unit.abbreviation
            )

            if model.mileageAtService == nil {
                Text("If left blank, current vehicle mileage will be used.")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let warning = anchors.mileageWarning {
                SanityWarningRow(message: warning)
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Reminder")

            VStack(spacing: Spacing.sm) {
                LabeledInstrumentToggle(
                    label: "REMIND ME NEXT TIME",
                    accessibilityLabel: "Remind me next time",
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
                }
            }
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Notes")
            RichNotesEditor(label: "Notes", text: $model.notes, placeholder: "Add notes...", minHeight: 100)
        }

        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Attachments")
            AttachmentPicker(attachments: $model.pendingAttachments)
        }

        Button {
            onSaveAndAddAnother()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus.square.on.square")
                    .font(.system(size: 14, weight: .medium))
                Text("SAVE & ADD ANOTHER")
                    .font(.brutalistLabel)
                    .tracking(1)
            }
            .foregroundStyle(model.isFormValid ? Theme.accent : Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(
                        (model.isFormValid ? Theme.accent : Theme.gridLine).opacity(0.5),
                        lineWidth: Theme.borderWidth
                    )
            )
        }
        .disabled(!model.isFormValid)
        .padding(.top, Spacing.sm)
        .accessibilityLabel("Save and add another")
    }
}

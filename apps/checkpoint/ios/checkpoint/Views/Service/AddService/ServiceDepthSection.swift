//
//  ServiceDepthSection.swift
//  checkpoint
//
//  "More details" — what makes an entry *complete*, as opposed to what makes it
//  *work*: category, cadence, notes and receipts.
//
//  Each has a working default or is genuinely optional: category defaults to
//  Maintenance, and a preset or tracked service brings its own cadence (shown
//  on the default path as the Next Reminder / Repeat readout). The cadence
//  fields here are for services with none, or to change it.
//
//  The collapsed row NAMES its contents, including the category's current
//  value, so the user can tell whether it is worth opening. Category is one
//  control everywhere — this `InlinePicker`.
//

import SwiftUI

struct ServiceDepthSection: View {
    @Bindable var model: ServiceLogFormModel
    /// Edit: opens an existing receipt.
    var onSelectAttachment: (Document) -> Void = { _ in }

    @State private var isExpanded = false

    private var existingAttachments: [ServiceAttachment] {
        model.mode.editing?.attachments ?? []
    }

    private var summary: String {
        model.isLogging
            ? L10n.formDepthSummary(model.costCategory.displayName)
            : L10n.formDepthSummarySchedule
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            trigger

            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    if model.isLogging {
                        InlinePicker(
                            label: L10n.formCategory,
                            options: CostCategory.allCases.map { PickerOption(value: $0, label: $0.displayName) },
                            selection: $model.costCategory
                        )
                    }

                    if !model.mode.isEdit {
                        cadenceFields
                    }

                    RichNotesEditor(
                        label: L10n.formNotes,
                        text: $model.notes,
                        placeholder: L10n.formNotesPlaceholder,
                        minHeight: 100
                    )

                    // No receipt for something that hasn't happened.
                    if model.isLogging {
                        if !existingAttachments.isEmpty {
                            AttachmentSection(attachments: existingAttachments, onSelect: onSelectAttachment)
                        }

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text((existingAttachments.isEmpty ? L10n.formAttachments : L10n.formAddAttachments).uppercased())
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1.5)

                            AttachmentPicker(attachments: $model.pendingAttachments)
                        }
                    }
                }
                // Fade only, per AESTHETIC.md (Motion).
                .transition(.opacity)
            }
        }
    }

    /// Wraps to two rows at large type: a fixed two-column split cannot
    /// survive Dynamic Type on a 375pt screen.
    private var cadenceFields: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                monthsField
                milesField
            }
            VStack(alignment: .leading, spacing: Spacing.md) {
                monthsField
                milesField
            }
        }
    }

    private var monthsField: some View {
        InstrumentNumberField(
            label: L10n.formEvery,
            value: $model.intervalMonths,
            placeholder: "6",
            suffix: L10n.formMonthsSuffix
        )
    }

    private var milesField: some View {
        InstrumentNumberField(
            label: L10n.formOrEvery,
            value: $model.intervalMiles,
            placeholder: "5000",
            suffix: DistanceSettings.shared.unit.abbreviation
        )
    }

    private var trigger: some View {
        Button {
            withAnimation(.easeOut(duration: Theme.animationMedium)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isExpanded ? L10n.formFewerDetails : L10n.formMoreDetails)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.accent)

                    if !isExpanded {
                        Text(summary)
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 54)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.formMoreDetails)
        .accessibilityValue(isExpanded ? "" : summary)
        .accessibilityAddTraits(isExpanded ? [.isButton, .isSelected] : .isButton)
    }
}

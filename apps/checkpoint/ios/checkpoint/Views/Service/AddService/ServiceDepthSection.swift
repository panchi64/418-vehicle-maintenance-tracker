//
//  ServiceDepthSection.swift
//  checkpoint
//
//  What makes an entry *complete*, as opposed to what makes it *work*: notes
//  and receipts. The repeat interval is deliberately not here — it lives on the
//  default path in `ServiceReminderFields`, because a reminder that does not
//  recur is a different feature, not a less complete one.
//
//  THE TRIGGER GOT REAL PRESENCE. As an 11pt bracket label at the end of a long
//  form it was invisible — the cheapest control on screen guarding the only
//  content still hidden. It now gets the same treatment as the header's specs
//  strip: a full-width row with a rule, naming its contents so you can tell
//  whether it is worth opening.
//

import SwiftUI

struct ServiceDepthSection: View {
    @Bindable var model: AddServiceFormModel

    @State private var isExpanded = false

    private var filledCount: Int {
        var count = 0
        if !model.notes.isEmpty { count += 1 }
        if !model.pendingAttachments.isEmpty { count += 1 }
        return count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            trigger

            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    RichNotesEditor(
                        label: L10n.formNotes,
                        text: $model.notes,
                        placeholder: L10n.formNotesPlaceholder,
                        minHeight: 100
                    )

                    // Attachments only make sense for something that already
                    // happened — there is no receipt for a future service.
                    if model.isLogging {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(L10n.formAttachments.uppercased())
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

    private var trigger: some View {
        Button {
            withAnimation(.easeOut(duration: Theme.animationMedium)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text((isExpanded ? L10n.formFewerDetails : L10n.formMoreDetails).uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.accent)
                        .tracking(1.5)

                    if !isExpanded {
                        // Names what is inside, and how much of it is already
                        // filled, so the user can tell whether to bother.
                        Text(filledCount == 0
                             ? L10n.formDepthContents
                             : L10n.formDetailsCount(filledCount))
                            .font(.brutalistSecondary)
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .frame(minHeight: 54)
            // Bottom rule only. A top rule sat a few pixels under the field
            // above's own underline and read as a doubled line.
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.formMoreDetails)
        .accessibilityValue(filledCount == 0 ? "" : L10n.formDetailsCount(filledCount))
        .accessibilityAddTraits(isExpanded ? [.isButton, .isSelected] : .isButton)
    }
}

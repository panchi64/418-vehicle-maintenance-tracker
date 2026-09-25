//
//  FormToolbar.swift
//  checkpoint
//
//  Where Save lives on every data-entry form (F1): the sheet's own navigation
//  bar. Cancel is the `.cancellationAction`, a prominent Save the
//  `.confirmationAction`, and the title carries a subtitle naming what the form
//  writes to (the vehicle).
//
//  WHY THE BOTTOM BAR WENT. `FormActionBar` spent ~96pt of every form on one
//  button pinned above the home indicator, and had to hide itself behind the
//  keyboard (the old F3) because it would otherwise eat number-pad space. The
//  toolbar costs no content height, never collides with the keyboard, and is
//  where every iOS sheet puts its confirm action. Save is still in the same
//  place on every surface — F1's actual promise.
//
//  F2 STILL HOLDS. Save is never `.disabled()` — a disabled button swallows the
//  tap, which is the dead end F2 exists to prevent. It is drawn dim and stays
//  tappable: the tap fires the error haptic and calls `onBlocked`, and the form
//  scrolls to the field that blocks it and shows a `.blocking` `FormAdvisory`
//  there.
//
//  DISMISS PROTECTION. A form with unsaved edits can't be swiped away, and
//  Cancel asks "Discard changes?" first. A pristine form dismisses at once —
//  asking about nothing is its own kind of friction.
//

import SwiftUI

struct FormToolbar: ViewModifier {
    let title: String
    var subtitle: String?
    var saveTitle: String
    let canSave: Bool
    let isDirty: Bool
    let onSave: () -> Void
    /// F2: a tap on the dim Save. Scroll to the blocking field and show why.
    let onBlocked: () -> Void
    /// Runs when the user confirms discarding (e.g. to clear a stored draft).
    var onDiscard: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false
    @State private var isConfirmingDiscard = false

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationSubtitle(subtitle ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(isDirty)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.commonCancel, action: cancel)
                        .accessibilityIdentifier("form.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        Text(isSaving ? L10n.formSaving : saveTitle)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Theme.accent)
                    .opacity(canSave ? 1 : 0.4)
                    // Not `.disabled`: that would swallow the F2 tap. VoiceOver
                    // still hears that Save won't save yet, and where it goes.
                    .accessibilityValue(canSave ? "" : L10n.a11ySaveUnavailable)
                    .accessibilityHint(canSave ? "" : L10n.a11ySaveUnavailableHint)
                    .accessibilityIdentifier("form.save")
                }
            }
            .confirmationDialog(
                L10n.formDiscardTitle,
                isPresented: $isConfirmingDiscard,
                titleVisibility: .visible
            ) {
                Button(L10n.formDiscard, role: .destructive) {
                    onDiscard?()
                    dismiss()
                }
                Button(L10n.formKeepEditing, role: .cancel) {}
            }
    }

    private func cancel() {
        if isDirty {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    private func save() {
        guard !isSaving else { return }
        guard canSave else {
            HapticService.shared.error()
            onBlocked()
            return
        }
        // Show "Saving…" for the frame the write takes, and swallow a double
        // tap that would otherwise write the entry twice.
        isSaving = true
        Task { @MainActor in
            await Task.yield()
            onSave()
            isSaving = false
        }
    }
}

extension View {
    /// The toolbar model every data-entry form uses. See `FormToolbar`.
    func formToolbar(
        title: String,
        subtitle: String? = nil,
        saveTitle: String = L10n.commonSave,
        canSave: Bool,
        isDirty: Bool,
        onSave: @escaping () -> Void,
        onBlocked: @escaping () -> Void = {},
        onDiscard: (() -> Void)? = nil
    ) -> some View {
        modifier(FormToolbar(
            title: title,
            subtitle: subtitle,
            saveTitle: saveTitle,
            canSave: canSave,
            isDirty: isDirty,
            onSave: onSave,
            onBlocked: onBlocked,
            onDiscard: onDiscard
        ))
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            Text("Form content")
                .foregroundStyle(Theme.textPrimary)
                .padding()
        }
        .background(Theme.backgroundPrimary)
        .formToolbar(
            title: "Log Service",
            subtitle: "Daily Driver",
            canSave: false,
            isDirty: true,
            onSave: {}
        )
    }
}

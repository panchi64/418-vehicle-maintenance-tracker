import SwiftUI
import UIKit

/// Markdown-aware notes editor with a brutalist formatting toolbar
/// (BOLD · • · 1.). Drop-in replacement for `InstrumentTextEditor`.
struct RichNotesEditor: View {
    /// Omit when the enclosing section header already names this field — same
    /// rule as `InstrumentTextField`. Every caller but one was passing the
    /// section's own title here, so the screens read "NOTES / NOTES".
    var label: String?
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 100

    @State private var selection: NSRange = NSRange(location: 0, length: 0)
    @State private var isFocused: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FieldLabel(label: label, requirement: .optional)

            VStack(spacing: 0) {
                toolbar
                Divider().background(Theme.gridLine)
                editor
            }
            .background(Theme.surfaceInstrument)
            .clipShape(Rectangle())
            .brutalistBorder(color: isFocused ? Theme.accent : Theme.gridLine)
            .focusGlow(isActive: isFocused)
            .animation(.easeOut(duration: Theme.animationFast), value: isFocused)
        }
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty && !isFocused {
                Text(placeholder)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.horizontal, Spacing.listItem)
                    .padding(.vertical, Spacing.md)
                    .accessibilityHidden(true)
            }
            MarkdownTextView(
                text: $text,
                selection: $selection,
                isFocused: $isFocused,
                accessibilityName: label ?? placeholder
            )
                .frame(minHeight: minHeight)
                .padding(.horizontal, Spacing.sm)
        }
    }

    private var toolbar: some View {
        HStack(spacing: Spacing.sm) {
            FormatButton(label: "BOLD", accessibility: L10n.a11yFormatBold) {
                apply(MarkdownNotesEditing.applyBold)
            }

            FormatButton(label: "BULLETS", accessibility: L10n.a11yFormatBulletedList) {
                apply(MarkdownNotesEditing.applyBulletList)
            }

            FormatButton(label: "NUMBERED", accessibility: L10n.a11yFormatNumberedList) {
                apply(MarkdownNotesEditing.applyNumberedList)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
    }

    private func apply(_ op: (String, NSRange) -> MarkdownNotesEditing.EditResult) {
        let result = op(text, selection)
        text = result.text
        // Defer selection update so the text binding propagates before the
        // UITextView's selectedRange is reset (otherwise the new range can
        // land beyond the still-old text length).
        DispatchQueue.main.async { selection = result.selection }
    }
}

private struct FormatButton: View {
    let label: String
    let accessibility: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.brutalistLabel)
                .tracking(1.5)
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, Spacing.sm)
                .frame(minHeight: TouchTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility)
    }
}

private struct MarkdownTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var selection: NSRange
    @Binding var isFocused: Bool
    /// What VoiceOver calls the editor. A UITextView otherwise announces only
    /// "text field", with no idea what it is for.
    let accessibilityName: String

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textColor = UIColor(Theme.textPrimary)
        view.tintColor = UIColor(Theme.accent)
        // 15pt at the default text size, following `.body` from there — the
        // same curve as `Font.brutalistBody`.
        view.font = UIFontMetrics(forTextStyle: .body)
            .scaledFont(for: UIFont.monospacedSystemFont(ofSize: 15, weight: .regular))
        view.adjustsFontForContentSizeCategory = true
        view.accessibilityLabel = accessibilityName
        view.autocapitalizationType = .sentences
        view.autocorrectionType = .yes
        view.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        // Return inserts a newline here — it always will, in a notes field — so
        // the only way out is a button off the keyboard. SwiftUI's
        // `.toolbar(placement: .keyboard)` does not reach a first responder
        // living inside a UIViewRepresentable, so this view supplies UIKit's
        // equivalent itself.
        view.inputAccessoryView = context.coordinator.makeDoneAccessory()
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.selectedRange != selection,
           selection.location <= (uiView.text as NSString).length {
            uiView.selectedRange = selection
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownTextView
        init(parent: MarkdownTextView) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.selection = textView.selectedRange
        }
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selection = textView.selectedRange
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
            textView.scrollIntoViewOnceKeyboardIsUp()
        }

        func textViewDidEndEditing(_ textView: UITextView) { parent.isFocused = false }

        func makeDoneAccessory() -> UIToolbar {
            let bar = UIToolbar()
            bar.sizeToFit()
            bar.barTintColor = UIColor(Theme.surfaceInstrument)
            bar.tintColor = UIColor(Theme.accent)
            bar.items = [
                UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                // .plain, not .done — `.done` is deprecated as of iOS 26, and
                // the emphasis it used to add is carried by the accent tint.
                UIBarButtonItem(title: "DONE", style: .plain, target: self, action: #selector(dismissKeyboard))
            ]
            return bar
        }

        @objc private func dismissKeyboard() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }
}

// MARK: - Scroll-into-view

private extension UIView {
    /// SwiftUI scrolls a focused field clear of the keyboard on its own, but
    /// only for its OWN controls — a `UITextView` inside a
    /// `UIViewRepresentable` is invisible to that, so tapping the notes editor
    /// left it sitting under the keyboard with the caret unreachable.
    ///
    /// `scrollRectToVisible` is the system answer to exactly this; the only
    /// thing missing is the timing. It measures against the scroll view's
    /// visible area, and that area does not shrink until the keyboard is up —
    /// run it immediately and the rect is already "visible", so it scrolls
    /// nowhere. One delayed call also covers the case where the keyboard is
    /// ALREADY up because focus moved here from another field.
    func scrollIntoViewOnceKeyboardIsUp() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.35))
            guard let scrollView = enclosingScrollView() else { return }
            // Expanded so the editor doesn't land flush against the keyboard,
            // and so its formatting toolbar comes along with it.
            let target = convert(bounds, to: scrollView).insetBy(dx: 0, dy: -Spacing.xl)
            scrollView.scrollRectToVisible(target, animated: true)
        }
    }

    func enclosingScrollView() -> UIScrollView? {
        var candidate = superview
        while let view = candidate {
            if let scrollView = view as? UIScrollView { return scrollView }
            candidate = view.superview
        }
        return nil
    }
}

#Preview {
    @Previewable @State var text: String = "Synthetic 0W-20 oil change.\n- Filter replaced\n- Fluids topped"
    ZStack {
        AtmosphericBackground()
        VStack {
            RichNotesEditor(label: "Notes", text: $text, placeholder: "Add notes...", minHeight: 140)
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}

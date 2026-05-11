import SwiftUI
import UIKit

/// Markdown-aware notes editor with a brutalist formatting toolbar
/// (BOLD · • · 1.). Drop-in replacement for `InstrumentTextEditor`.
struct RichNotesEditor: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 100

    @State private var selection: NSRange = NSRange(location: 0, length: 0)
    @State private var isFocused: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)

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
            }
            MarkdownTextView(text: $text, selection: $selection, isFocused: $isFocused)
                .frame(minHeight: minHeight)
                .padding(.horizontal, Spacing.sm)
        }
    }

    private var toolbar: some View {
        HStack(spacing: Spacing.sm) {
            FormatButton(label: "B", accessibility: "Bold") {
                apply(MarkdownNotesEditing.applyBold)
            }
            .fontWeight(.bold)

            FormatButton(label: "•", accessibility: "Bulleted list") {
                apply(MarkdownNotesEditing.applyBulletList)
            }

            FormatButton(label: "1.", accessibility: "Numbered list") {
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
                .tracking(1)
                .foregroundStyle(Theme.accent)
                .frame(minWidth: 32, minHeight: 32)
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

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textColor = UIColor(Theme.textPrimary)
        view.tintColor = UIColor(Theme.accent)
        view.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        view.autocapitalizationType = .sentences
        view.autocorrectionType = .yes
        view.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
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
        func textViewDidBeginEditing(_ textView: UITextView) { parent.isFocused = true }
        func textViewDidEndEditing(_ textView: UITextView) { parent.isFocused = false }
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

//
//  InstrumentTextField.swift
//  checkpoint
//
//  Text, number, and date inputs. A single rule under the value, not a box.
//
//  ENCLOSURE IS A BUDGET. The service form used to render every control as an
//  outlined rectangle — eight quick-service chips, seven timing chips, six
//  category chips, three boxed fields. Twenty-four identical enclosures, so none
//  of them read as the decision the screen existed to capture. Spending the
//  budget means most controls give theirs up.
//
//  A field gives up its box and keeps a bottom rule. The value sits ON the line,
//  which is the same idiom the readouts already use, and the rule goes accent on
//  focus — a stronger affordance than the static border ever was, since a box
//  that is always drawn says nothing about where you are.
//
//  `InstrumentTextEditor` deliberately keeps its box: an editor has to
//  communicate its HEIGHT, and a single rule under 100pt of empty space reads as
//  a rendering fault rather than as an input.
//

import SwiftUI

struct InstrumentTextField: View {
    /// Omit when the enclosing `FormSection` header already names this field.
    /// Stacking two identical labels on one input is worse than none.
    var label: String?
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences
    var requirement: FieldRequirement = .optional

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            FieldLabel(label: label, requirement: requirement)

            FieldLine(isFocused: isFocused) {
                TextField(placeholder, text: $text)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .focused($isFocused)
                    // VoiceOver otherwise names the field by its placeholder —
                    // an example value, not what the field is for.
                    .accessibilityLabel(label ?? placeholder)
                    // Return means "done" on a single-line field — there is
                    // nothing to submit to and no next field to advance to, so
                    // the only reading of Return a user could intend is that
                    // they have finished. Without this the key is inert and the
                    // keyboard has to be dismissed some other way.
                    .submitLabel(.done)
                    .onSubmit { isFocused = false }
            }

            FieldEffectNote(requirement: requirement)
        }
    }
}

// MARK: - Shared field furniture

/// The label row: name, plus the one required marker (F5). Renders nothing when
/// the field is unlabeled.
///
/// Not private — `RichNotesEditor` renders the same label row, and two copies of
/// it drift.
struct FieldLabel: View {
    let label: String?
    let requirement: FieldRequirement

    var body: some View {
        if let label {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(label.uppercased())
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)

                if requirement.isRequired {
                    RequiredFieldMarker()
                }
            }
        }
    }
}

/// The rule the value sits on. Accent while focused, so the affordance is
/// carried by state rather than by a permanent border.
private struct FieldLine<Content: View>: View {
    let isFocused: Bool
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(minHeight: TouchTarget.minimum)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(isFocused ? Theme.accent : Theme.borderSubtle)
                    .frame(height: Theme.borderWidth)
            }
            .focusGlow(isActive: isFocused)
            .animation(.easeOut(duration: Theme.animationFast), value: isFocused)
    }
}

/// States the consequence of filling an `.optionalWithEffect` field, so the user
/// learns it before committing rather than after.
private struct FieldEffectNote: View {
    let requirement: FieldRequirement

    var body: some View {
        if let effect = requirement.effectNote {
            Text(effect)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Instrument Number Field

struct InstrumentNumberField: View {
    var label: String?
    @Binding var value: Int?
    var placeholder: String = ""
    var suffix: String = ""
    var requirement: FieldRequirement = .optional

    /// Show camera button accessory
    var showCameraButton: Bool = false

    /// Callback when camera button is tapped
    var onCameraTap: (() -> Void)?

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            FieldLabel(label: label, requirement: requirement)

            HStack(spacing: Spacing.sm) {
                FieldLine(isFocused: isFocused) {
                    HStack(spacing: Spacing.sm) {
                        TextField(placeholder, text: $textValue)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)
                            .keyboardType(.numberPad)
                            .focused($isFocused)
                            .accessibilityLabel(label ?? placeholder)
                            .onChange(of: textValue) { _, newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered != newValue {
                                    textValue = filtered
                                }
                                value = Int(filtered)
                            }
                            .onAppear {
                                if let value = value {
                                    textValue = String(value)
                                }
                            }
                            .onChange(of: value) { _, newValue in
                                let newText = newValue.map { String($0) } ?? ""
                                if newText != textValue {
                                    textValue = newText
                                }
                            }

                        // 13pt, not the label's 11pt caps and not the value's
                        // 15pt. A unit annotation set as large as the value it
                        // annotates competes with it — "mi" is not as important
                        // as "33,417" — and set as a tracked cap it reads as a
                        // second field label.
                        if !suffix.isEmpty {
                            Text(suffix)
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }

                if showCameraButton, let onCameraTap = onCameraTap {
                    Button {
                        onCameraTap()
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Theme.accent)
                            .minimumTouchTarget()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.a11yScanWithCamera)
                }
            }

            FieldEffectNote(requirement: requirement)
        }
    }
}

// MARK: - Instrument Date Picker

struct InstrumentDatePicker: View {
    var label: String?
    @Binding var date: Date
    var displayedComponents: DatePicker<Label>.Components = .date

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            FieldLabel(label: label, requirement: .optional)

            DatePicker("", selection: $date, displayedComponents: displayedComponents)
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(Theme.accent)
                // Only override when there IS a label — `accessibilityLabel("")`
                // strips the DatePicker's own description and leaves VoiceOver
                // announcing a bare date with no idea what it sets.
                .accessibilityLabel(label ?? L10n.a11yDate)
                .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum, alignment: .leading)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Theme.borderSubtle)
                        .frame(height: Theme.borderWidth)
                }
        }
    }
}

// MARK: - Keyboard Dismissal

/// Apply once to a parent container (ScrollView, Form, NavigationStack) to give
/// every field on that screen a way out of the keyboard.
///
/// WHY BOTH HALVES. Return covers the single-line fields (`InstrumentTextField`
/// sets `.submitLabel(.done)`), but a number pad has no return key and a text
/// editor's return key means "newline" — so those two need a button that is not
/// on the keyboard itself. `ToolbarItemGroup(placement: .keyboard)` is the
/// system's own accessory slot; it appears for whatever field is focused.
///
/// Was `numberPadDoneButton`. The name claimed a scope it never had — the
/// toolbar has always been shown for every keyboard type — and three screens
/// with only text fields skipped it on the strength of that name.
struct KeyboardDismissToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("DONE") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.accent)
                }
            }
            // The system's own drag-to-dismiss, the same gesture Messages and
            // Mail use. Costs one modifier and needs no affordance of its own.
            .scrollDismissesKeyboard(.interactively)
    }
}

extension View {
    func keyboardDismissToolbar() -> some View {
        modifier(KeyboardDismissToolbar())
    }
}

// MARK: - Instrument Text Editor

/// The one input that keeps its enclosure. An editor must communicate how much
/// room it offers, and a bare rule under an empty 100pt area does not.
struct InstrumentTextEditor: View {
    var label: String?
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 100

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            FieldLabel(label: label, requirement: .optional)

            ZStack(alignment: .topLeading) {
                if text.isEmpty && !isFocused {
                    Text(placeholder)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.horizontal, Spacing.listItem)
                        .padding(.vertical, Spacing.md)
                        .accessibilityHidden(true)
                }

                TextEditor(text: $text)
                    .font(.brutalistBody)
                    .foregroundStyle(Theme.textPrimary)
                    .focused($isFocused)
                    .accessibilityLabel(label ?? placeholder)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing.listItem)
            }
            .frame(minHeight: minHeight)
            .background(Theme.surfaceInstrument)
            .clipShape(Rectangle())
            .brutalistBorder(color: isFocused ? Theme.accent : Theme.gridLine)
            .focusGlow(isActive: isFocused)
            .animation(.easeOut(duration: Theme.animationFast), value: isFocused)
        }
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                InstrumentTextField(
                    label: "Vehicle name",
                    text: .constant("Daily Driver"),
                    placeholder: "Enter name..."
                )

                InstrumentNumberField(
                    label: "Odometer",
                    value: .constant(32500),
                    placeholder: "0",
                    suffix: "mi",
                    requirement: .required(reason: "Mileage reminders are measured from it.")
                )

                InstrumentTextField(
                    label: "Marbete month",
                    text: .constant(""),
                    placeholder: "November",
                    requirement: .optionalWithEffect(
                        effect: "Set it and you will be reminded a month before it expires."
                    )
                )

                InstrumentDatePicker(
                    label: "Due date",
                    date: .constant(Date())
                )

                InstrumentTextEditor(
                    label: "Notes",
                    text: .constant(""),
                    placeholder: "Add notes..."
                )
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}

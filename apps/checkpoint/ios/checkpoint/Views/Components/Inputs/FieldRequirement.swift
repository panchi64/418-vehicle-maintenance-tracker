//
//  FieldRequirement.swift
//  checkpoint
//
//  The single vocabulary for required vs. optional (F5).
//
//  Why this exists: the app previously signalled the same concept four ways —
//  an `isRequired:` parameter on some fields, a hand-rolled `Text("*")` beside
//  some headers, an `[OPTIONAL]` tag on some sections, and a validation row
//  that only appeared after tapping a disabled Save. Four signals for one
//  concept means none of them is trusted, and the user learns to ignore all
//  four.
//
//  Two rules travel with this type:
//
//  1. Required-ness is justified per item. "The form has always required it"
//     is not a justification; "the app computes X from it and X is wrong
//     without it" is. A required field the user cannot fill is a dead end.
//
//  2. `.optional` is a promise. A field marked optional must not have side
//     effects — it may not schedule notifications, alter other records, or
//     change app behavior. If it does, it isn't optional; use
//     `.optionalWithEffect` and say what happens.
//

import SwiftUI

enum FieldRequirement: Equatable {
    /// The feature cannot function without this. `reason` is shown when the
    /// user tries to save without it, so write it as an explanation rather
    /// than a scold: "Reminders need a date or a mileage to fire."
    case required(reason: String)

    /// Genuinely skippable, with no consequence for leaving it blank.
    case optional

    /// Skippable, but filling it changes behavior beyond this record —
    /// scheduling a notification, for example. `effect` states what happens,
    /// because an unlabeled side effect breaks the promise `.optional` makes.
    case optionalWithEffect(effect: String)

    var isRequired: Bool {
        if case .required = self { return true }
        return false
    }

    /// Trailing tag for a section header, or nil when the field is required
    /// (required-ness is marked at the field, not the section, so a section
    /// containing one required field isn't mislabeled wholesale).
    var sectionTag: String? {
        switch self {
        case .required: return nil
        case .optional: return L10n.formOptionalTag
        case .optionalWithEffect: return L10n.formOptionalTag
        }
    }

    /// Shown beneath the field when it carries a side effect, so the user
    /// learns the consequence before committing rather than after.
    var effectNote: String? {
        switch self {
        case .required, .optional: return nil
        case .optionalWithEffect(let effect): return effect
        }
    }

    /// The message surfaced when a save is blocked on this field.
    var unmetReason: String? {
        switch self {
        case .required(let reason): return reason
        case .optional, .optionalWithEffect: return nil
        }
    }
}

// MARK: - Marker

/// The one visual mark for a required field, rendered beside its label.
/// Deliberately not a bare asterisk: an asterisk is a convention the user has
/// to already know, and it reads as nothing at all to VoiceOver. Tertiary,
/// like `FormSection`'s trailing tag: status color here read as an error on a
/// field that was already filled, and status owns color.
struct RequiredFieldMarker: View {
    var body: some View {
        Text(L10n.formRequiredTag)
            .font(.brutalistLabel)
            .foregroundStyle(Theme.textTertiary)
            .tracking(1.5)
            .accessibilityLabel(L10n.formRequiredAccessibility)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()

        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(spacing: Spacing.sm) {
                Text("ODOMETER")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)
                RequiredFieldMarker()
            }

            FormAdvisory.info(
                FieldRequirement
                    .optionalWithEffect(effect: "Setting this schedules a renewal reminder.")
                    .effectNote ?? ""
            )

            FormAdvisory.blocking(
                FieldRequirement
                    .required(reason: "Reminders need a date or a mileage to fire.")
                    .unmetReason ?? ""
            )
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}

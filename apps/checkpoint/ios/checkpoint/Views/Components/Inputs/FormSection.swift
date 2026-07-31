//
//  FormSection.swift
//  checkpoint
//
//  A titled band of a Decision surface, separated by a header rule.
//
//  WHY THIS IS NOT `InstrumentSection`. That type gives its header
//  `.brutalistLabel` in `textTertiary` — which is exactly the treatment a FIELD
//  label gets. Once the enclosures came off the forms, section titles and field
//  labels rendered identically, and three different structural levels collapsed
//  into one: "WHEN" names a section, "COST" names a field inside one, and
//  "Already done" names a subgroup inside that. A form with one label style has
//  no structure, only a sequence.
//
//  The three levels now differ on at least two channels each:
//
//    section   11 Bold caps, secondary, + a full-width rule    FormSection
//    field     11 Medium caps, tertiary, no rule               InstrumentTextField
//    subgroup  13 Regular sentence case, tertiary              FormSubgroup
//
//  The rule does most of the work: it spans the remaining width, so a section
//  boundary is a line across the screen rather than a marginally bigger gap.
//
//  `InstrumentSection` remains correct for boxed instrument content elsewhere;
//  this is the form-specific shell. See docs/SURFACE_DOCTRINE.md, Part 2 →
//  "Decision rules".
//

import SwiftUI

struct FormSection<Content: View>: View {
    let title: String

    /// Short trailing note — "Required", "Optional". Sits past the rule.
    ///
    /// Tertiary, not accent: in the default theme `accent` equals `textPrimary`,
    /// so an accent-colored note renders at full brightness and outshines the
    /// section title it annotates.
    var trailing: String?

    @ViewBuilder let content: Content

    var body: some View {
        // Three distinct spacing steps, not two similar ones:
        //
        //   8pt   header → its content   the label belongs to what follows
        //   16pt  field → field          siblings inside one group
        //   32pt  section → section      set by the parent scroll container
        //
        // A single `spacing` on this VStack previously put the header 16pt from
        // its own content while sections sat 24pt apart — so the header was
        // very nearly equidistant between the group it labels and the one
        // above, and at a glance the sections did not separate. A 1.5:1 ratio
        // does not communicate grouping; proximity has to be unambiguous.
        //
        // Tightening the inner steps is what pays for the wider outer one, so
        // the extra separation costs almost no height.
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text(title.uppercased())
                    .font(.brutalistLabelBold)
                    .foregroundStyle(Theme.textSecondary)
                    .tracking(1.5)
                    .fixedSize(horizontal: true, vertical: false)

                // Theme.borderWidth (2), not a hairline. The section title is
                // 11pt Bold caps and a field label is 11pt Medium caps — the
                // same size — so the RULE is what actually marks the boundary,
                // and it should be as heavy as any other structural border.
                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                if let trailing {
                    Text(trailing.uppercased())
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            // Content owns its own spacing, so the header can sit closer to it
            // than the fields sit to each other.
            VStack(alignment: .leading, spacing: Spacing.md) {
                content
            }
        }
    }
}

// MARK: - Subgroup

/// A named group inside a section — the third label level.
///
/// Sentence case and no rule, so it cannot be mistaken for a section boundary.
struct FormSubgroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)

            content
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                FormSection(title: "Service") {
                    InstrumentTextField(
                        label: nil,
                        text: .constant("Oil change"),
                        placeholder: "What was done?"
                    )
                }

                FormSection(title: "When", trailing: "Required") {
                    FormSubgroup(title: "Already done") {
                        Text("Chips go here")
                            .brutalistBodyStyle()
                    }
                }

                FormSection(title: "Details", trailing: "Optional") {
                    InstrumentTextField(
                        label: "Notes",
                        text: .constant(""),
                        placeholder: "Anything worth remembering"
                    )
                }
            }
            .padding(Spacing.screenHorizontal)
        }
    }
    .preferredColorScheme(.dark)
}

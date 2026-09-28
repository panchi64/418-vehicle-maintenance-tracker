import SwiftUI

/// A fixed safety sentence that travels with a hazard: every flood item
/// (§6.6), and every downed pole or line (§6.2) and hazard report's sent
/// state. Symbol plus words, never colour alone.
struct SafetyLine: View {
    enum Kind {
        case flood
        /// "Aléjate. Si hay peligro, llama al 911."
        case hazard
    }

    let kind: Kind

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
        }
        .textRole(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(Color(.statusCritical))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var text: LocalizedStringResource {
        switch kind {
        case .flood: LocalizedStringResource("No cruces carreteras inundadas.", comment: "Safety line shown with every flooded-road item")
        case .hazard: LocalizedStringResource("Aléjate. Si hay peligro, llama al 911.", comment: "Safety line shown with every downed pole or power line")
        }
    }
}

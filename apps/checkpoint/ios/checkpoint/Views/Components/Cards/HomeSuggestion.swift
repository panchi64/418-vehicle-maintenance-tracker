//
//  HomeSuggestion.swift
//  checkpoint
//
//  Home's Suggestions slot: at most ONE item.
//
//  The service-visit cluster ("do these on the same visit") and seasonal
//  advisories used to be separate bordered cards that could all show at once —
//  up to three boxed cards between Next Up and Upcoming, each with its own
//  filled button competing with the hero's. They now share one slot, and the
//  more actionable one wins it: a cluster is built from services already due,
//  a seasonal item is a generic calendar nudge.
//

import SwiftUI

enum HomeSuggestion {
    case cluster(ServiceCluster)
    case seasonal(SeasonalReminder)

    /// The one suggestion Home shows, or nil.
    ///
    /// - Parameters:
    ///   - cluster: the vehicle's primary cluster, if any.
    ///   - dismissedClusterHashes: clusters the user said "not now" to.
    ///   - clusteringEnabled: the Settings toggle for visit bundling.
    ///   - seasonal: active seasonal reminders, most relevant first.
    static func pick(
        cluster: ServiceCluster?,
        dismissedClusterHashes: Set<String>,
        clusteringEnabled: Bool,
        seasonal: [SeasonalReminder]
    ) -> HomeSuggestion? {
        if clusteringEnabled, let cluster, !dismissedClusterHashes.contains(cluster.contentHash) {
            return .cluster(cluster)
        }
        return seasonal.first.map { .seasonal($0) }
    }
}

// MARK: - View

/// The slot's content. Plain text under the section header, not a card: the
/// hero above is the screen's one boxed, filled element, and a second box here
/// competed with it in the squint test. Actions are bracket links for the same
/// reason.
struct HomeSuggestionView: View {
    let suggestion: HomeSuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void
    /// Seasonal only: never show this reminder again.
    var onSuppress: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.brutalistBodyEmphasis)
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)

            AdaptiveStack(spacing: Spacing.md) {
                bracketLink(acceptLabel, color: Theme.accent, action: onAccept)
                bracketLink(dismissLabel, color: Theme.textTertiary, action: onDismiss)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contextMenu {
            Button(acceptLabel, action: onAccept)
            Button(dismissLabel, action: onDismiss)
            if let onSuppress {
                Button(role: .destructive, action: onSuppress) {
                    Label(L10n.homeSuggestionNeverShow, systemImage: "eye.slash")
                }
            }
        }
    }

    private func bracketLink(_ label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("[\(label.uppercased())]")
                .font(.brutalistLabel)
                .tracking(1)
                .foregroundStyle(color)
                .frame(minHeight: TouchTarget.minimum)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var title: String {
        switch suggestion {
        case .cluster(let cluster): return L10n.homeSuggestionClusterTitle(cluster.serviceCount)
        case .seasonal(let reminder): return reminder.name
        }
    }

    private var detail: String {
        switch suggestion {
        case .cluster(let cluster):
            let names = ListFormatter.localizedString(byJoining: cluster.services.map(\.name))
            return L10n.homeSuggestionClusterDetail(names, Formatters.mileage(cluster.mileageWindow))
        case .seasonal(let reminder):
            return reminder.description
        }
    }

    private var acceptLabel: String {
        switch suggestion {
        case .cluster: return L10n.homeSuggestionReviewVisit
        case .seasonal: return L10n.homeSuggestionSchedule
        }
    }

    private var dismissLabel: String {
        switch suggestion {
        case .cluster: return L10n.homeSuggestionNotNow
        case .seasonal: return L10n.homeSuggestionNotThisYear
        }
    }
}

#Preview {
    let reminder = SeasonalReminder.allReminders.first { $0.id == "winterTires" }!

    return ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        ReadoutSection(title: L10n.homeSuggestions) {
            HomeSuggestionView(
                suggestion: .seasonal(reminder),
                onAccept: {},
                onDismiss: {},
                onSuppress: {}
            )
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}

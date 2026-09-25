//
//  RecallRowCard.swift
//  checkpoint
//
//  One row per recall in `RecallSheetView`. Collapsed: component + status badge.
//  Expanded: SUMMARY / RISK / REMEDY / CAMPAIGN block plus three next-step CTAs
//  (Find dealer in Maps, Add as planned service, View on NHTSA) and a status
//  menu (Mark scheduled / Mark resolved / Reopen).
//

import SwiftUI

struct RecallRowCard: View {
    let recall: RecallInfo
    let vehicle: Vehicle
    let status: RecallStatus
    let isExpanded: Bool
    let onToggle: () -> Void
    let onSetStatus: (RecallStatus) -> Void
    /// Nil means the parent context can't accept a planned-service handoff
    /// (e.g. opened from Settings); the button is hidden in that case.
    let onAddPlannedService: (() -> Void)?

    private var nhtsaCampaignURL: URL? {
        URL(string: "https://www.nhtsa.gov/recalls?nhtsaId=\(recall.campaignNumber)")
    }

    private var dealerSearchURL: URL? {
        let query = "\(vehicle.make) dealer".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "dealer"
        return URL(string: "https://maps.apple.com/?q=\(query)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if isExpanded {
                Rectangle()
                    .fill(Theme.statusOverdue.opacity(0.3))
                    .frame(height: 1)

                expandedDetail
            }
        }
        .recallCardStyle()
        .clipped()
    }

    // MARK: - Header

    private var header: some View {
        Button(action: onToggle) {
            HStack(spacing: Spacing.sm) {
                if recall.parkIt {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.statusOverdue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(recall.component)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(isExpanded ? nil : 1)
                        .multilineTextAlignment(.leading)

                    statusBadge
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.statusOverdue)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(headerAccessibilityLabel)
        .accessibilityValue(isExpanded ? L10n.readoutExpanded : L10n.readoutCollapsed)
    }

    /// The component, plus its tracked status when it has one — the badge
    /// under the name would otherwise be replaced by this label.
    private var headerAccessibilityLabel: String {
        switch status {
        case .open: recall.component
        case .scheduled: L10n.readoutValueWithStatus(recall.component, L10n.recallStatusScheduled)
        case .resolved: L10n.readoutValueWithStatus(recall.component, L10n.recallStatusResolved)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch status {
        case .open:
            EmptyView()
        case .scheduled:
            Text(L10n.recallStatusScheduled.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.statusDueSoon)
                .tracking(1.5)
        case .resolved:
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.bold))
                    .accessibilityHidden(true)
                Text(L10n.recallStatusResolved.uppercased())
                    .font(.brutalistLabel)
                    .tracking(1.5)
            }
            .foregroundStyle(Theme.statusGood)
        }
    }

    // MARK: - Expanded detail

    private var expandedDetail: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("SUMMARY")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)

            Text(recall.summary)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !recall.consequence.isEmpty {
                Text("RISK")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.statusOverdue)
                    .tracking(1)
                    .padding(.top, Spacing.xs)

                Text(recall.consequence)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !recall.remedy.isEmpty {
                Text("REMEDY")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.statusGood)
                    .tracking(1)
                    .padding(.top, Spacing.xs)

                Text(recall.remedy)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AdaptiveStack {
                Text("NHTSA #\(recall.campaignNumber)")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)

                Spacer()

                if !recall.reportDate.isEmpty {
                    Text(recall.reportDate)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1)
                }
            }
            .padding(.top, Spacing.xs)

            ctaButtons
                .padding(.top, Spacing.sm)

            statusMenu
                .padding(.top, Spacing.xs)
        }
        .padding(Spacing.md)
        .transition(.opacity)
    }

    // MARK: - CTAs

    private var ctaButtons: some View {
        VStack(spacing: Spacing.xs) {
            if let url = dealerSearchURL {
                Link(destination: url) {
                    ctaLabel(L10n.recallActionFindDealer(vehicle.make), tint: Theme.accent)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    AnalyticsService.shared.capture(.recallDealerSearchOpened(make: vehicle.make))
                })
            }

            if let onAddPlannedService {
                Button(action: {
                    AnalyticsService.shared.capture(.recallPlannedServiceStarted(campaignNumber: recall.campaignNumber))
                    onAddPlannedService()
                }) {
                    ctaLabel(L10n.recallActionAddPlannedService, tint: Theme.accent)
                }
                .buttonStyle(.plain)
            }

            if let url = nhtsaCampaignURL {
                Link(destination: url) {
                    ctaLabel(L10n.recallActionViewNHTSA, tint: Theme.accent)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    AnalyticsService.shared.capture(.recallNHTSALinkOpened(campaignNumber: recall.campaignNumber))
                })
            }
        }
    }

    private func ctaLabel(_ text: String, tint: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(text.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(tint)
                .tracking(1.5)

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum - 2 * Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.sm)
        .background(tint.opacity(0.1))
        .contentShape(Rectangle())
    }

    // MARK: - Status menu

    private var statusMenu: some View {
        Menu {
            if status != .scheduled {
                Button {
                    onSetStatus(.scheduled)
                } label: {
                    Label(L10n.recallActionMarkScheduled, systemImage: "calendar.badge.clock")
                }
            }
            if status != .resolved {
                Button {
                    onSetStatus(.resolved)
                } label: {
                    Label(L10n.recallActionMarkResolved, systemImage: "checkmark.circle")
                }
            }
            if status != .open {
                Button {
                    onSetStatus(.open)
                } label: {
                    Label(L10n.recallActionReopen, systemImage: "arrow.uturn.backward")
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "ellipsis.circle")
                    .font(.caption2.weight(.bold))
                    .accessibilityHidden(true)
                Text("UPDATE STATUS")
                    .font(.brutalistLabel)
                    .tracking(1.5)
            }
            .foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity, minHeight: TouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(L10n.readoutUpdateRecallStatus)
    }
}

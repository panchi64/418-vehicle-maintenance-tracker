//
//  NextUpCard.swift
//  checkpoint
//
//  Home's hero: the one thing this car needs next, and the button that does it.
//
//    ┌───────────────────────────────────────────┐
//    │ ■ OVERDUE                        NEXT UP  │  status: word + shape
//    │ Oil & Filter Change                       │  20 Medium
//    │ 917  mi over                              │  56 Light hero (the primary)
//    │ Due 32,500 mi or Jul 4                    │  13 support — ONE line
//    │ [ Mark Done ]                             │  filled, full width
//    └───────────────────────────────────────────┘
//
//  NEXT UP ENDS IN AN ACTION. The card used to be a readout you tapped through
//  to a detail screen, found Mark Done on, then confirmed in a sheet — four
//  taps to close the loop on the one thing Home exists to surface. Mark Done is
//  now on the card: button → Save.
//
//  The card body and the button are SEPARATE targets. The body pushes the
//  detail; nesting the button inside a tappable card made the inner target
//  ambiguous.
//
//  The hero shows whichever trigger is closer (`NextUpReadout`). The marbete
//  takes this card when it is the most urgent item; its hero is always days
//  and its action reads "Mark Renewed". Same component — the differences are
//  props, not a fork (there used to be a separate `MarbeteNextUpCard`).
//
//  See tools/sketchpad/src/components/Cards.tsx for the resolved layout.
//

import SwiftUI

struct NextUpCard: View {
    let title: String
    let status: ServiceStatus
    let readout: NextUpReadout
    let dueLine: String
    let actionLabel: String
    let onOpen: () -> Void
    let onAction: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Button(action: onOpen) {
                readoutBody
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(CardButtonStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityValue(accessibilityValue)
            .accessibilityHint(L10n.rowViewDetailsHint)
            .accessibilityAddTraits(.isButton)

            Button(action: onAction) {
                Text(actionLabel)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
        }
        .padding(Theme.cardPadding)
        .background(tint.opacity(0.08))
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle().strokeBorder(tint, lineWidth: Theme.borderWidth)
        )
    }

    private var tint: Color {
        status == .neutral ? Theme.gridLine : status.color
    }

    private var readoutBody: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                StatusTag(status: status)
                Spacer(minLength: Spacing.sm)
                Text(L10n.homeNextUp.uppercased())
                    .font(.brutalistLabel)
                    .tracking(1.5)
                    .foregroundStyle(Theme.textTertiary)
            }

            Text(title)
                .font(.brutalistHeading)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if let figure = heroFigure {
                // Side by side while it fits; the qualifier drops beneath the
                // number at large type rather than crushing it.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .lastTextBaseline, spacing: Spacing.sm) {
                        heroNumber(figure.value)
                        heroQualifier(figure.qualifier)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        heroNumber(figure.value)
                        heroQualifier(figure.qualifier)
                    }
                }
            }

            Text(dueLine)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                .multilineTextAlignment(.leading)
        }
    }

    private func heroNumber(_ value: String) -> some View {
        Text(value)
            .font(.brutalistHero)
            .monospacedDigit()
            .foregroundStyle(status == .neutral ? Theme.textPrimary : status.color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(.numericText())
    }

    private func heroQualifier(_ text: String) -> some View {
        Text(text)
            .font(.brutalistHeading)
            .foregroundStyle(Theme.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    // MARK: - Hero text

    private struct HeroFigure {
        let value: String
        let qualifier: String
    }

    private var heroFigure: HeroFigure? {
        guard let figure = readout.figure else { return nil }
        let past = readout.isPast
        switch figure {
        case .distance(let miles):
            let unit = DistanceSettings.shared.unit.abbreviation
            return HeroFigure(
                value: Formatters.mileageNumber(abs(miles)),
                qualifier: past ? L10n.homeHeroDistanceOver(unit) : L10n.homeHeroDistanceLeft(unit)
            )
        case .days(let days):
            let count = abs(days)
            let qualifier: String
            if past {
                qualifier = L10n.homeHeroDaysOver(count)
            } else if readout.kind == .marbete {
                qualifier = L10n.homeHeroDaysToExpiry(count)
            } else {
                qualifier = L10n.homeHeroDaysLeft(count)
            }
            return HeroFigure(value: count.formatted(), qualifier: qualifier)
        }
    }

    private var accessibilityValue: String {
        let statusWord = L10n.readoutStatus(status)
        guard let heroFigure else { return L10n.readoutValueWithStatus(dueLine, statusWord) }
        let hero: String
        switch readout.figure {
        case .distance(let miles):
            let distance = L10n.spokenDistance(abs(miles))
            hero = readout.isPast ? L10n.readoutDistanceOverdue(distance) : L10n.readoutDistanceLeft(distance)
        default:
            hero = L10n.homeSpokenFigure(heroFigure.value, heroFigure.qualifier)
        }
        return L10n.homeNextUpAccessibility(statusWord, hero, dueLine)
    }
}

// MARK: - Convenience builders

extension NextUpCard {
    /// A due-tracking service as the hero.
    init(
        service: Service,
        mileage: MileageEstimate,
        onOpen: @escaping () -> Void,
        onMarkDone: @escaping () -> Void
    ) {
        self.init(
            title: service.name,
            status: service.status(currentMileage: mileage.effective),
            readout: .service(service, currentMileage: mileage.effective, dailyPace: mileage.pace),
            dueLine: Self.dueLine(for: service),
            actionLabel: L10n.homeMarkDone,
            onOpen: onOpen,
            onAction: onMarkDone
        )
    }

    /// The marbete as the hero. Always days; the action renews it.
    init(
        marbete: MarbeteUpcomingItem,
        onOpen: @escaping () -> Void,
        onMarkRenewed: @escaping () -> Void
    ) {
        let expires = marbete.vehicle.marbeteExpiration.map(Vehicle.marbeteExpirationLabel)
        self.init(
            title: marbete.itemName,
            status: marbete.itemStatus,
            readout: .marbete(daysUntilExpiration: marbete.daysRemaining),
            dueLine: expires.map(L10n.homeExpires) ?? "",
            actionLabel: L10n.homeMarkRenewed,
            onOpen: onOpen,
            onAction: onMarkRenewed
        )
    }

    /// "Due 32,500 mi or Jul 4" — both triggers, one line. The interval that
    /// produced them is detail and lives on the service screen.
    static func dueLine(for service: Service) -> String {
        let date = service.dueDate?.formatted(.dateTime.month(.abbreviated).day())
        let mileage = service.dueMileage.map(Formatters.mileage)
        switch (mileage, date) {
        case (let mileage?, let date?): return L10n.homeDueMileageOrDate(mileage, date)
        case (let mileage?, nil): return L10n.homeDue(mileage)
        case (nil, let date?): return L10n.homeDue(date)
        case (nil, nil): return ""
        }
    }
}

// MARK: - Card Button Style

/// Press feedback for a tappable card body: dims, never scales.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: Theme.animationFast), value: configuration.isPressed)
    }
}

#Preview {
    let vehicle = Vehicle.sampleVehicle
    let services = Service.sampleServices(for: vehicle)

    return ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            ForEach(services.prefix(2), id: \.name) { service in
                NextUpCard(
                    service: service,
                    mileage: MileageEstimate(pace: 40, effective: vehicle.currentMileage, isEstimated: false),
                    onOpen: {},
                    onMarkDone: {}
                )
            }
        }
        .padding(Theme.screenHorizontalPadding)
    }
    .preferredColorScheme(.dark)
}

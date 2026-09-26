//
//  AppointmentSection.swift
//  checkpoint
//
//  Home's "Shop Visit" section: the next booked visit, right after Next Up.
//  Resolved in tools/sketchpad (screens/HomeTab.tsx, "Shop Visit").
//
//  Readout rules: the section is always there (fixed order); with nothing
//  booked it is its header, one quiet line and the Book action — never an
//  apology card. With a visit booked:
//
//    Fri, Oct 3, 9:30 AM                        ← THE primary: heading size + weight
//    Firestone Complete Auto Care               ← secondary: body, regular
//    [IN 2 DAYS] Oil Change, Tire Rotation      ← tag (word + shape), then one
//                                                 truncating services line
//    [ Directions ]  [ Log Visit ]
//
//  Tried and rejected in the sketchpad: a hero-sized boxed card and an
//  outlined Log Visit — both competed with Next Up under the squint test.
//
//  It is an unbordered card: Next Up is the screen's hero and keeps the only
//  enclosure and the only status tint, so this never out-shouts it under the
//  squint test. Tapping the body edits the visit; Log Visit opens the service
//  form prefilled from it (`AppointmentCompletion`). Later visits follow as
//  one-line rows.
//

import SwiftUI

struct AppointmentSection: View {
    /// Scheduled visits, soonest first (`Appointment.scheduled`).
    let appointments: [Appointment]
    let onBook: () -> Void
    let onOpen: (Appointment) -> Void
    let onDirections: (Appointment) -> Void
    let onLogVisit: (Appointment) -> Void

    var body: some View {
        ReadoutSection(title: L10n.homeShopVisit) {
            if let next = appointments.first {
                AppointmentCard(
                    appointment: next,
                    onOpen: { onOpen(next) },
                    onDirections: { onDirections(next) },
                    onLogVisit: { onLogVisit(next) }
                )
                .onScreenEntity(AppointmentEntity.self, id: next.id)
            } else {
                InsufficientDataNote(message: L10n.homeShopVisitEmpty)
            }
        } supporting: {
            let later = appointments.dropFirst()
            if !later.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(later), id: \.id) { appointment in
                        AppointmentRow(appointment: appointment) { onOpen(appointment) }
                    }
                }
            }
        } action: {
            ReadoutSectionAction(label: L10n.appointmentBook, systemImage: "plus") {
                onBook()
            }
        }
    }
}

/// The next booked visit.
struct AppointmentCard: View {
    let appointment: Appointment
    let onOpen: () -> Void
    let onDirections: () -> Void
    let onLogVisit: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(AppointmentFormat.when(appointment.startDate))
                        .font(.brutalistHeading)
                        .foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(appointment.trimmedShopName ?? L10n.appointmentShopFallback)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)

                    // The tag leads the support line, so it survives the
                    // truncation that drops trailing services.
                    HStack(spacing: Spacing.sm) {
                        Text(AppointmentFormat.timingTag(appointment.timing()).uppercased())
                            .font(.brutalistLabelBold)
                            .tracking(1.5)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, Spacing.xs)
                            .overlay(Rectangle().strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth))
                            .fixedSize()
                        if !appointment.sortedServices.isEmpty {
                            Text(AppointmentFormat.services(appointment.sortedServices))
                                .font(.brutalistSecondary)
                                .foregroundStyle(Theme.textTertiary)
                                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(CardButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityHint(L10n.appointmentEditHint)

            AdaptiveStack(spacing: Spacing.sm) {
                Button(action: onDirections) {
                    Label(L10n.appointmentDirections, systemImage: "arrow.triangle.turn.up.right.diamond")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)

                Button(action: onLogVisit) {
                    Label(L10n.appointmentLogVisit, systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)
            }
        }
    }
}

/// A later booked visit: one line, tap to edit.
private struct AppointmentRow: View {
    let appointment: Appointment
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm) {
                Text(AppointmentFormat.rowLine(appointment))
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textTertiary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: TouchTarget.minimum)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(L10n.appointmentEditHint)
    }
}

/// How appointments read on screen. One place, so Home, the form and the
/// rows agree.
enum AppointmentFormat {
    /// "Fri, Oct 3, 9:30 AM" in the user's locale.
    static func when(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
    }

    static func services(_ services: [Service]) -> String {
        ListFormatter.localizedString(byJoining: services.map(\.name))
    }

    /// "Oct 9 · Midas" for a later visit.
    static func rowLine(_ appointment: Appointment) -> String {
        L10n.appointmentRowLine(
            appointment.startDate.formatted(.dateTime.month(.abbreviated).day().hour().minute()),
            appointment.trimmedShopName ?? L10n.appointmentShopFallback
        )
    }

    static func timingTag(_ timing: Appointment.Timing) -> String {
        switch timing {
        case .inDays(1): L10n.appointmentTimingTomorrow
        case .inDays(let days): L10n.appointmentTimingInDays(days)
        case .today: L10n.appointmentTimingToday
        case .started: L10n.appointmentTimingNotLogged
        }
    }

    /// "Reminders: Thu 9:30 AM and Fri 8:30 AM" — what saving will schedule.
    static func reminders(for start: Date, now: Date = .now) -> String? {
        let dates = Appointment.reminderDates(for: start, now: now).values.sorted()
        guard !dates.isEmpty else { return nil }
        let formatted = dates.map { $0.formatted(.dateTime.weekday(.abbreviated).hour().minute()) }
        return ListFormatter.localizedString(byJoining: formatted)
    }
}

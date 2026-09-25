//
//  LoggedReminderFields.swift
//  checkpoint
//
//  "Next Reminder" — what a logged entry leaves behind.
//
//  A READOUT, NOT AN ADVISORY: the next due date is the value the save
//  produces, so it gets a label and emphasis weight rather than a quiet `.info`
//  line. The toggle is the only decision here, and it defaults ON — turning it
//  off is the decision; leaving it is free.
//
//  Only rendered when a cadence exists: with no interval there is nothing to
//  project (F4). A cadence can be set under More details, and the post-save
//  "Schedule next" toast covers the rest.
//

import SwiftUI

struct LoggedReminderFields: View {
    @Bindable var model: ServiceLogFormModel

    private var intervalText: String? {
        Formatters.serviceInterval(months: model.intervalMonths, miles: model.intervalMiles)
    }

    var body: some View {
        if model.hasIntervalPolicy, let intervalText {
            FormSection(title: L10n.formNextReminderTitle) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(headline)
                        .font(.brutalistBodyEmphasis)
                        .foregroundStyle(model.isRecurring ? Theme.textPrimary : Theme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(model.isRecurring
                         ? L10n.formEveryIntervalWhicheverFirst(intervalText)
                         : L10n.formWontComeBack(model.serviceName))
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)

                LabeledInstrumentToggle(
                    label: L10n.formRemindNextTime,
                    accessibilityLabel: L10n.formRemindNextTime,
                    isOn: $model.isRecurring
                )
            }
        }
    }

    private var headline: String {
        guard model.isRecurring, let next = model.nextReminderAfterLog else { return L10n.formNoReminder }
        return Self.dateOrMileage(next) ?? L10n.formNoReminder
    }

    /// "Mar 12, 2027 or at 38,500 mi". Null-free grammar: a half that won't be
    /// scheduled is omitted rather than rendered as a placeholder (F8).
    static func dateOrMileage(_ schedule: ReminderImpactCalculator.Schedule) -> String? {
        switch (schedule.dueDate, schedule.dueMileage) {
        case let (date?, mileage?):
            return L10n.formDateOrMileage(Formatters.mediumDate.string(from: date), Formatters.mileage(mileage))
        case let (date?, nil):
            return Formatters.mediumDate.string(from: date)
        case let (nil, mileage?):
            return L10n.formFiresAtMileage(Formatters.mileage(mileage))
        case (nil, nil):
            return nil
        }
    }
}

/// Edit: a date or odometer change can move the next reminder its service
/// counts from. Offered, with the shift previewed before save (F9).
struct EditReminderImpactFields: View {
    @Bindable var model: ServiceLogFormModel

    var body: some View {
        if model.dateOrMileageChanged, model.occasionServiceCount > 1 {
            FormAdvisory.info(L10n.editVisitOccasionHint(model.occasionServiceCount))
        }

        if model.offersMoveReminder {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                LabeledInstrumentToggle(
                    label: L10n.editAlsoMoveReminder,
                    accessibilityLabel: L10n.editAlsoMoveReminder,
                    isOn: $model.alsoMoveNextReminder
                )

                if model.alsoMoveNextReminder,
                   let impact = ReminderImpactCalculator.impact(
                       current: model.currentReminderSchedule,
                       proposed: model.proposedReminderSchedule
                   ) {
                    ReminderImpactRow(impact: impact)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var model: ServiceLogFormModel = {
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 32500)
        let model = ServiceLogFormModel(vehicle: vehicle)
        model.customServiceName = "Oil Change"
        model.intervalMonths = 6
        model.intervalMiles = 5000
        model.isRecurring = true
        return model
    }()

    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        LoggedReminderFields(model: model)
            .padding(Spacing.screenHorizontal)
    }
}

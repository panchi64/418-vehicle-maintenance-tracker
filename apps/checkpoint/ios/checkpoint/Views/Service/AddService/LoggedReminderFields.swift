//
//  LoggedReminderFields.swift
//  checkpoint
//
//  The reminder a logged service leaves behind, on the log branch.
//
//  Picking a preset turns recurrence on, but the repeat controls lived only on
//  the scheduling branch — so logging an oil change silently created a
//  6-month / 5,000-mile reminder the user never saw. A reminder the app will
//  create is a consequence of saving, so it is stated before save (`.info`)
//  and can be switched off here (the `[OPTIONAL]`-is-a-promise rule).
//
//  Only rendered when a cadence exists: with no interval there is nothing to
//  project (F4), and the post-save "Schedule next" toast covers that case.
//

import SwiftUI

struct LoggedReminderFields: View {
    @Bindable var model: AddServiceFormModel

    var body: some View {
        if model.hasIntervalPolicy {
            FormSection(title: L10n.formTheReminder) {
                LabeledInstrumentToggle(
                    label: L10n.formRemindNextTime,
                    accessibilityLabel: L10n.formRemindNextTime,
                    isOn: $model.isRecurring
                )

                if let next = model.nextReminderAfterLog,
                   let text = Self.nextReminderText(next) {
                    FormAdvisory.info(text)
                }
            }
        }
    }

    /// Null-free grammar: a half that won't be scheduled is omitted rather
    /// than rendered as a placeholder (F8).
    static func nextReminderText(_ schedule: ReminderImpactCalculator.Schedule) -> String? {
        switch (schedule.dueDate, schedule.dueMileage) {
        case let (date?, mileage?):
            return L10n.formNextReminderDateOrMileage(
                Formatters.mediumDate.string(from: date),
                Formatters.mileage(mileage)
            )
        case let (date?, nil):
            return L10n.formNextReminderDate(Formatters.mediumDate.string(from: date))
        case let (nil, mileage?):
            return L10n.formNextReminderMileage(Formatters.mileage(mileage))
        case (nil, nil):
            return nil
        }
    }
}

#Preview {
    @Previewable @State var model: AddServiceFormModel = {
        let vehicle = Vehicle(name: "Test Car", make: "Toyota", model: "Camry", year: 2022, currentMileage: 32500)
        let model = AddServiceFormModel(vehicle: vehicle, initialTiming: .today)
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
    .preferredColorScheme(.dark)
}

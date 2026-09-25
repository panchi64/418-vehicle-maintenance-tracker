//
//  ServiceWhenSection.swift
//  checkpoint
//
//  "When" — the control that derives intent. Today is selected before the user
//  touches anything, so the everyday entry costs no tap here at all. "Not done
//  yet" is offered only from [+]: Mark Done and edit describe something that
//  already happened.
//

import SwiftUI

struct ServiceWhenSection: View {
    @Bindable var model: ServiceLogFormModel

    private var options: [ServiceTiming] {
        model.mode.offersNotYet ? ServiceTiming.pastCases + [.notYet] : ServiceTiming.pastCases
    }

    var body: some View {
        FormSection(title: L10n.formWhen) {
            WrappingChipRow(
                items: options,
                label: \.displayName,
                isSelected: { model.timing == $0 },
                onTap: select
            )

            if model.timing.needsExplicitDate {
                InstrumentDatePicker(
                    label: L10n.formDatePerformed,
                    date: $model.customDate
                )
            }

            // F6: while editing, the loaded date for as long as it differs.
            if let original = model.originalDate {
                OriginalValueHint(text: L10n.editWas(Formatters.shortDate.string(from: original)))
            }
        }
    }

    private func select(_ timing: ServiceTiming) {
        model.timing = timing
        HapticService.shared.selectionChanged()
    }
}

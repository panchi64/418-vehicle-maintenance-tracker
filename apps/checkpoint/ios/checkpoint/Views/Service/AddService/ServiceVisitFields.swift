//
//  ServiceVisitFields.swift
//  checkpoint
//
//  The past branch of the unified form: what the visit cost and what the
//  odometer read. Shown when the chosen timing is in the past.
//
//  Replaces `RecordServiceFields`, which also owned the date picker (now in the
//  timing section), the recurrence toggle (now in the reminder branch, because
//  it is a scheduling decision), and a `CollapsibleDetailsSection` (now the
//  shared `ServiceDepthSection`).
//

import SwiftUI

struct ServiceVisitFields: View {
    @Bindable var model: AddServiceFormModel
    let anchors: ServiceFormAnchors

    var body: some View {
        // No OPTIONAL tag. The tag is a promise of no side effects, and the
        // odometer here can advance the vehicle's current mileage — so this
        // section is not optional in that sense. Nothing in it is required
        // either (required-ness is marked per field), and the one side effect
        // is stated as `.info` before save, beside the field that causes it.
        FormSection(title: L10n.formTheVisit) {
            odometerField
            costField

            // A picker, not six chips. Category has a working default and is
            // rarely changed, so a permanent option set spent six enclosures on
            // a decision most users never make — while the timing chips, which
            // every user must answer, looked exactly the same.
            InlinePicker(
                label: L10n.formCategory,
                options: CostCategory.allCases.map {
                    PickerOption(value: $0, label: $0.displayName)
                },
                selection: $model.costCategory
            )
        }
    }

    // MARK: - Odometer

    @ViewBuilder
    private var odometerField: some View {
        // "Odometer at service", distinct from the reminder branch's "Remind me
        // at". Identical labels across the two branches are what made "should
        // this update current mileage?" ambiguous in the first place.
        InstrumentNumberField(
            label: L10n.formOdometerAtService,
            value: $model.mileageAtService,
            placeholder: Formatters.mileageNumber(model.vehicle.currentMileage),
            suffix: DistanceSettings.shared.unit.abbreviation
        )

        // Adoption is STATED, never prompted. The app knows what it will do; a
        // modal question would be the app asking the user to make its decision
        // for it (F11).
        if model.wouldAdoptMileage, let summary = MileageCommit.adoptionSummary(
            reading: model.mileageAtService,
            observedAt: model.performedDate,
            for: model.vehicle
        ) {
            FormAdvisory.info(summary)
        }

        // Reserved for the case the app genuinely cannot resolve: a backfilled
        // entry carrying a reading above the current odometer.
        if model.hasUnresolvedMileageContradiction {
            FormAdvisory.contradiction(
                L10n.formOdometerContradiction(Formatters.mileage(model.vehicle.currentMileage)),
                outcomes: [
                    .init(label: L10n.formKeepMyOdometer) {
                        model.mileageResolution = .keepCurrent
                    },
                    .init(label: L10n.formCorrectItUpward) {
                        model.mileageResolution = .correctUpward
                    }
                ]
            )
        }

        if model.mileageResolution == .keepCurrent {
            FormAdvisory.info(
                L10n.formOdometerStaysAt(Formatters.mileage(model.vehicle.currentMileage))
            )
        }

        if model.mileageAtService == nil {
            Text(L10n.formMileageBlankHint)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        if let warning = anchors.mileageWarning {
            SanityWarningRow(message: warning)
        }
    }

    // MARK: - Cost

    @ViewBuilder
    private var costField: some View {
        InstrumentTextField(
            label: L10n.formCost,
            text: $model.cost,
            placeholder: "0.00",
            keyboardType: .decimalPad
        )
        .onChange(of: model.cost) { _, newValue in
            model.cost = CostValidation.filterCostInput(newValue)
            model.costError = CostValidation.validate(model.cost)
        }

        if let hint = anchors.priorCostHint {
            Text(hint)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(hint)
        }

        if let warning = anchors.costWarning {
            SanityWarningRow(message: warning)
        }

        if let costError = model.costError {
            ErrorMessageRow(message: costError) {
                model.costError = nil
            }
        }
    }
}

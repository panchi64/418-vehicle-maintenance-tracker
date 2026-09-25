//
//  ServiceVisitFields.swift
//  checkpoint
//
//  "Details" — what the visit recorded: the odometer and the cost. Shown when
//  the entry happened (any past timing, and always when editing).
//
//  No OPTIONAL tag. The tag is a promise of no side effects, and the odometer
//  here can advance the vehicle's current mileage — so the section is not
//  optional in that sense. The one side effect is stated as `.info` before
//  save, beside the field that causes it (F11).
//
//  Category moved to More details: it has a working default and is rarely
//  changed, so it makes an entry complete rather than making it work.
//

import SwiftUI

struct ServiceVisitFields: View {
    @Bindable var model: ServiceLogFormModel
    let anchors: ServiceFormAnchors
    /// F2: shown after a tap on the dim Save.
    let blocker: String?

    /// Edit: an un-itemized visit's shared total is what the cost field edits.
    private var sharedCostVisit: ServiceVisit? { model.mode.editing?.sharedCostVisit }

    var body: some View {
        FormSection(title: L10n.formDetails) {
            odometerField
            costField
        }
    }

    // MARK: - Odometer

    @ViewBuilder
    private var odometerField: some View {
        // "Odometer at service", distinct from the reminder's "Remind me at".
        // Identical labels are what made "should this update current mileage?"
        // ambiguous in the first place.
        InstrumentNumberField(
            label: L10n.formOdometerAtService,
            value: $model.mileageAtService,
            placeholder: Formatters.mileageNumber(model.vehicle.currentMileage),
            suffix: DistanceSettings.shared.unit.abbreviation,
            requirement: model.mode.isEdit ? .required(reason: L10n.editLogMileageRequired) : .optional
        )

        if let blocker {
            FormAdvisory.blocking(blocker)
        }

        if let original = model.originalMileage {
            OriginalValueHint(text: L10n.editWas(OriginalValueHint.value(forMileage: original)))
        }

        estimateHint

        // Adoption is STATED, never prompted (F11).
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
                    .init(label: L10n.formKeepMyOdometer) { model.mileageResolution = .keepCurrent },
                    .init(label: L10n.formCorrectItUpward) { model.mileageResolution = .correctUpward }
                ]
            )
        }

        if model.mileageResolution == .keepCurrent {
            FormAdvisory.info(L10n.formOdometerStaysAt(Formatters.mileage(model.vehicle.currentMileage)))
        }

        if let warning = anchors.mileageWarning {
            FormAdvisory.caution(warning)
        }
    }

    /// The field holds the last CONFIRMED reading; the estimate is a hint to
    /// adopt in one tap, never a default (Mark Done once committed the
    /// estimate as fact).
    @ViewBuilder
    private var estimateHint: some View {
        let estimate = model.vehicle.mileageEstimate
        if !model.mode.isEdit, estimate.isEstimated, model.mileageAtService != estimate.effective {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(L10n.markDoneEstimateHint(Formatters.mileage(estimate.effective)))
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(L10n.formUse) {
                    model.mileageAtService = estimate.effective
                    HapticService.shared.selectionChanged()
                }
                .font(.brutalistBody)
                .foregroundStyle(Theme.accent)
                .buttonStyle(.plain)
                .frame(minHeight: TouchTarget.minimum)
                .accessibilityLabel(L10n.formUseEstimate(Formatters.mileage(estimate.effective)))
            }
        }
    }

    // MARK: - Cost

    @ViewBuilder
    private var costField: some View {
        InstrumentTextField(
            label: sharedCostVisit != nil ? L10n.editVisitTotal : L10n.formCost,
            text: $model.cost,
            placeholder: "0.00",
            keyboardType: .decimalPad,
            prefix: Formatters.currency.currencySymbol
        )
        .onChange(of: model.cost) { _, newValue in
            model.cost = CostValidation.filterCostInput(newValue)
            model.costError = CostValidation.validate(model.cost)
        }

        if let original = model.originalCost {
            OriginalValueHint(text: L10n.editWas(original.map { Formatters.currency.string(from: $0 as NSDecimalNumber) ?? "" } ?? L10n.impactNone))
        }

        // A visit total isn't comparable to this service's past single-service
        // costs, so the price anchor gives way to what the number covers.
        if let visit = sharedCostVisit {
            if visit.serviceCount > 1 {
                FormAdvisory.info(L10n.editVisitTotalHint(visit.serviceCount))
            }
        } else {
            if let hint = anchors.priorCostHint {
                Text(hint)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let warning = anchors.costWarning {
                FormAdvisory.caution(warning)
            }
        }

        if let costError = model.costError {
            FormAdvisory.caution(costError) { model.costError = nil }
        }
    }
}

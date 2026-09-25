//
//  VehicleFormSections.swift
//  checkpoint
//
//  The sections of the single-scroll add-vehicle form, in the order the app
//  needs them rather than the order the data model lists them.
//
//  WHAT CHANGED, AND WHY
//
//  - THE TWO-STEP WIZARD IS GONE. One entity should not have two disclosure
//    models, and Edit Vehicle's single scroll was already the better one.
//
//  - VIN IS FIRST, above the fields it fills. It used to sit below them, so it
//    only helped users who scrolled past fields they had just been told were
//    required. A fast path placed after the slow path is not a fast path.
//
//  - THE ODOMETER IS REQUIRED. The wizard made its step unconditionally valid,
//    so `currentMileage ?? 0` shipped vehicles at zero miles and every
//    mileage-based reminder became fiction.
//
//  - A vehicle is creatable from VIN + odometer alone.
//
//  - The nine-state VIN block collapses into the `FormAdvisory` ladder.
//

import SwiftUI

extension FieldRequirement {
    /// Marbete is skippable, but filling it schedules renewal reminders — so
    /// it is never a bare `.optional`. Shared by Add and Edit Vehicle.
    static var marbete: FieldRequirement {
        .optionalWithEffect(effect: L10n.vehicleMarbeteEffect)
    }
}

// MARK: - 1. The fast path, first

struct VehicleVINSection: View {
    @Bindable var formState: VehicleFormState

    var body: some View {
        FormSection(title: L10n.vehicleVIN, trailing: L10n.formOptionalTag) {
            HStack(spacing: Spacing.sm) {
                InstrumentTextField(
                    text: $formState.vin,
                    placeholder: L10n.vehicleVINPlaceholder,
                    autocapitalization: .characters
                )
                .autocorrectionDisabled()
                .onChange(of: formState.vin) {
                    formState.clearVINErrors()
                    formState.clearAutoFillFeedback()
                }

                if formState.isCameraAvailable {
                    Button {
                        formState.clearVINOCRError()
                        formState.showVINCamera = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Theme.accent)
                            .minimumTouchTarget()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.addVehicleScanVIN)
                }
            }

            // The nine hand-rolled states collapse into the severity ladder, so
            // "we're looking it up" and "that VIN is wrong" stop looking alike.
            vinAdvisory

            if formState.isVINValid, !formState.vinLookupSucceeded {
                VINLookupButton(formState: formState)
            }

            Text(L10n.vehicleVINHelp)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var vinAdvisory: some View {
        if formState.isProcessingVINOCR {
            OCRProcessingIndicator(text: L10n.addVehicleScanningVIN)
        }

        if let error = formState.vinOCRError {
            FormAdvisory.caution(error) { formState.clearVINOCRError() }
        }

        if let error = formState.vinLookupError {
            FormAdvisory.caution(error) { formState.vinLookupError = nil }
        }

        let trimmed = formState.vin.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, !formState.isVINValid {
            if trimmed.count < 17 {
                FormAdvisory.caution(L10n.addVehicleVINCharactersRemaining(17 - trimmed.count))
            } else {
                // Naming the likely typo beats "invalid": a VIN never contains
                // I, O, or Q, so those are almost always a 1 or a 0.
                FormAdvisory.caution(L10n.addVehicleVINForbiddenLetters)
            }
        }

        if formState.vinLookupSucceeded {
            FormAdvisory.info(L10n.addVehicleVINDetailsFilled)
        }
    }
}

// MARK: - 2. The one thing the app cannot infer

struct VehicleOdometerSection: View {
    @Bindable var formState: VehicleFormState

    var body: some View {
        FormSection(title: L10n.vehicleOdometer, trailing: L10n.formRequiredTag) {
            InstrumentNumberField(
                value: $formState.currentMileage,
                placeholder: L10n.vehicleMileagePlaceholder,
                suffix: DistanceSettings.shared.unit.abbreviation,
                requirement: .required(reason: L10n.vehicleOdometerRequired),
                showCameraButton: formState.isCameraAvailable,
                onCameraTap: {
                    formState.clearOdometerError()
                    formState.showOdometerCamera = true
                }
            )

            if formState.isProcessingOdometerOCR {
                OCRProcessingIndicator(text: L10n.addVehicleScanningOdometer)
            }

            if let error = formState.odometerOCRError {
                FormAdvisory.caution(error) { formState.clearOdometerError() }
            }

            Text(L10n.vehicleOdometerRequired)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - 3. What the VIN would have filled

struct VehicleIdentitySection: View {
    @Bindable var formState: VehicleFormState

    /// Marks a field the VIN lookup just populated, so the user can see what
    /// the scan actually did rather than having to compare against memory.
    private func autoFilled(_ key: String) -> some View {
        Rectangle()
            .strokeBorder(Theme.accent, lineWidth: Theme.borderWidth)
            .opacity(formState.autoFilledFields.contains(key) ? 1 : 0)
            .animation(.easeOut(duration: Theme.animationMedium), value: formState.autoFilledFields)
            .allowsHitTesting(false)
    }

    /// Make and model are required; year is not (see `VehicleFormState.hasIdentity`).
    /// So required-ness is marked on the two fields, not on the section — a
    /// REQUIRED section tag over an optional year field was a false claim (F5).
    private var identityRequirement: FieldRequirement {
        .required(reason: L10n.vehicleIdentityRequired)
    }

    var body: some View {
        FormSection(title: L10n.vehicleDetails) {
            // Two columns at normal type, stacked at large type. A fixed
            // two-column split cannot survive Dynamic Type on a 375pt screen —
            // forcing it crushed "MAKE" to 28pt against a 46pt word.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: Spacing.sm) {
                    yearField.frame(maxWidth: 110)
                    makeField
                }
                VStack(alignment: .leading, spacing: Spacing.md) {
                    yearField
                    makeField
                }
            }

            InstrumentTextField(
                label: L10n.vehicleModel,
                text: $formState.model,
                placeholder: L10n.vehicleModelPlaceholder,
                requirement: identityRequirement
            )
            .overlay(autoFilled("model"))
        }
    }

    private var yearField: some View {
        InstrumentNumberField(
            label: L10n.vehicleYear,
            value: $formState.year,
            placeholder: L10n.vehicleYearPlaceholder
        )
        .overlay(autoFilled("year"))
    }

    private var makeField: some View {
        InstrumentTextField(
            label: L10n.vehicleMake,
            text: $formState.make,
            placeholder: L10n.vehicleMakePlaceholder,
            requirement: identityRequirement
        )
        .overlay(autoFilled("make"))
    }
}

// MARK: - 4. Optional, and honest about consequences

struct VehicleDetailsSection: View {
    @Bindable var formState: VehicleFormState

    var body: some View {
        // The section header carries the optionality once, rather than each of
        // its fields repeating it. Six "Optional" tags in a column is noise that
        // stops meaning anything.
        FormSection(title: L10n.vehicleSpecifications, trailing: L10n.formOptionalTag) {
            InstrumentTextField(
                label: L10n.vehicleNickname,
                text: $formState.name,
                placeholder: L10n.vehicleNicknamePlaceholder
            )

            Text(L10n.vehicleNicknameEffect)
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            InstrumentTextField(
                label: L10n.vehicleLicensePlate,
                text: $formState.licensePlate,
                placeholder: "ABC-1234"
            )

            InstrumentTextField(
                label: L10n.vehicleTireSize,
                text: $formState.tireSize,
                placeholder: L10n.vehicleTireSizePlaceholder
            )

            InstrumentTextField(
                label: L10n.vehicleOilType,
                text: $formState.oilType,
                placeholder: L10n.vehicleOilTypePlaceholder
            )

            // Marbete explains the term AND states that filling it schedules a
            // notification. An optional field must not quietly create one — see
            // `FieldRequirement.optionalWithEffect`.
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(L10n.vehicleMarbete.uppercased())
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1.5)

                MarbetePicker(
                    month: $formState.marbeteExpirationMonth,
                    year: $formState.marbeteExpirationYear
                )

                Text(L10n.vehicleMarbeteHelp)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                if let effect = FieldRequirement.marbete.effectNote {
                    FormAdvisory.info(effect)
                }
            }

            InstrumentTextEditor(
                label: L10n.vehicleNotes,
                text: $formState.notes,
                placeholder: L10n.vehicleNotesPlaceholder
            )
        }
    }
}

// MARK: - VIN lookup

struct VINLookupButton: View {
    @Bindable var formState: VehicleFormState

    var body: some View {
        Button {
            lookUpVIN()
        } label: {
            HStack(spacing: Spacing.sm) {
                if formState.isDecodingVIN {
                    ProgressView()
                        .tint(Theme.surfaceInstrument)
                }
                Text(formState.isDecodingVIN ? L10n.addVehicleVINLookupLoading : L10n.addVehicleVINLookup)
            }
        }
        .buttonStyle(.secondary)
        .disabled(formState.isDecodingVIN)
    }

    private func lookUpVIN() {
        formState.isDecodingVIN = true
        formState.vinLookupError = nil

        Task {
            do {
                let result = try await NHTSAService.shared.decodeVIN(formState.vin)

                formState.isDecodingVIN = false
                formState.usedVINLookup = true

                var filled: Set<String> = []
                if formState.make.isEmpty {
                    formState.make = result.make
                    filled.insert("make")
                }
                if formState.model.isEmpty {
                    formState.model = result.model
                    filled.insert("model")
                }
                if formState.year == nil {
                    formState.year = result.modelYear
                    filled.insert("year")
                }

                if !filled.isEmpty {
                    formState.autoFilledFields = filled
                    formState.vinLookupSucceeded = true

                    Task {
                        try? await Task.sleep(for: .seconds(3))
                        formState.clearAutoFillFeedback()
                    }
                }
            } catch {
                formState.isDecodingVIN = false
                formState.vinLookupError = error.localizedDescription
            }
        }
    }
}

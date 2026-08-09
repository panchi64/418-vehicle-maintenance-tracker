//
//  AddVehicleFlowView.swift
//  checkpoint
//
//  Add a vehicle. One scroll, no wizard.
//
//  The two-step wizard is gone: one entity should not have two disclosure
//  models, and Edit Vehicle's single scroll was already the better one. Section
//  order follows what the app needs — VIN (the fast path) above the fields it
//  fills, then the odometer, then make/model/year, then everything optional.
//
//  See `VehicleFormSections` for the per-section reasoning.
//
//  FeatureHintView integration deferred — onboarding flow is already dense;
//  hints would add noise without measurable benefit to completion rate.
//

import SwiftUI
import SwiftData

struct AddVehicleFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var formState = VehicleFormState()
    @State private var showBlockingReason = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack {
                    AtmosphericBackground()

                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.xl) {
                            VehicleVINSection(formState: formState)
                                .id("top")

                            VehicleOdometerSection(formState: formState)
                                .id("odometer")

                            VehicleIdentitySection(formState: formState)

                            if showBlockingReason, let reason = formState.blockingReason {
                                FormAdvisory.blocking(reason)
                            }

                            VehicleDetailsSection(formState: formState)
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.top, Spacing.md)
                        .padding(.bottom, Spacing.xxl)
                    }
                }
                .keyboardDismissToolbar()
                .trackScreen(.addVehicleBasics)
                .navigationTitle(L10n.vehicleAdd)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.commonCancel) {
                            dismiss()
                        }
                        .toolbarButtonStyle()
                    }
                }
                .onChange(of: formState.blockingReason) { _, newValue in
                    if newValue == nil { showBlockingReason = false }
                }
                .safeAreaInset(edge: .bottom) {
                    FormActionBar(
                        primaryTitle: L10n.vehicleSave,
                        isPrimaryEnabled: formState.blockingReason == nil,
                        onPrimary: { saveVehicle() },
                        onDisabledPrimaryTap: {
                            showBlockingReason = true
                            withAnimation {
                                proxy.scrollTo(
                                    formState.currentMileage == nil ? "odometer" : "top",
                                    anchor: .top
                                )
                            }
                        }
                    )
                }
            .onAppear {
                // Apply onboarding marbete prefill if set
                if let month = appState.onboarding.marbeteMonth {
                    formState.marbeteExpirationMonth = month
                }
                if let year = appState.onboarding.marbeteYear {
                    formState.marbeteExpirationYear = year
                }
                // Apply VIN lookup result from onboarding if available
                if let vinResult = appState.onboarding.vinLookupResult {
                    formState.vin = vinResult.vin
                    formState.make = vinResult.make
                    formState.model = vinResult.model
                    formState.year = vinResult.year
                    formState.usedVINLookup = true
                    appState.onboarding.vinLookupResult = nil
                }
            }
            .fullScreenCover(isPresented: $formState.showVINCamera) {
                OdometerCameraSheet(
                    onImageCaptured: { image in
                        processVINOCR(image: image)
                    },
                    guideText: L10n.addVehicleVINAlignGuide,
                    viewfinderAspectRatio: 5.0
                )
            }
            .fullScreenCover(isPresented: $formState.showOdometerCamera) {
                OdometerCameraSheet { image in
                    processOdometerOCR(image: image)
                }
            }
            .sheet(isPresented: $formState.showOCRConfirmation) {
                if let result = formState.ocrResult {
                    OCRConfirmationView(
                        extractedMileage: result.mileage,
                        confidence: result.confidence,
                        onConfirm: { mileage in
                            formState.currentMileage = mileage
                        },
                        currentMileage: formState.currentMileage ?? 0,
                        detectedUnit: result.detectedUnit,
                        rawText: result.rawText,
                        debugImage: formState.ocrDebugImage
                    )
                    .presentationDetents([.medium])
                }
            }
            }
        }
    }

    // MARK: - VIN OCR

    private func processVINOCR(image: UIImage) {
        AnalyticsService.shared.capture(.ocrAttempted(ocrType: .vin))
        formState.isProcessingVINOCR = true
        formState.vinOCRError = nil

        Task {
            do {
                let result = try await VINOCRService.shared.recognizeVIN(from: image)

                formState.isProcessingVINOCR = false
                formState.vin = result.vin
                formState.vinOCROriginal = result.vin
                AnalyticsService.shared.capture(.ocrSucceeded(ocrType: .vin))
            } catch {
                formState.isProcessingVINOCR = false
                formState.vinOCRError = error.localizedDescription
                AnalyticsService.shared.capture(.ocrFailed(ocrType: .vin))
            }
        }
    }

    // MARK: - Odometer OCR

    private func processOdometerOCR(image: UIImage) {
        AnalyticsService.shared.capture(.ocrAttempted(ocrType: .odometer))
        formState.isProcessingOdometerOCR = true
        formState.odometerOCRError = nil
        formState.ocrDebugImage = image

        Task {
            do {
                let result = try await OdometerOCRService.shared.recognizeMileage(
                    from: image,
                    currentMileage: formState.currentMileage
                )

                formState.isProcessingOdometerOCR = false
                formState.ocrResult = result
                formState.showOCRConfirmation = true
                formState.usedOdometerOCR = true
                AnalyticsService.shared.capture(.ocrSucceeded(ocrType: .odometer))
            } catch {
                formState.isProcessingOdometerOCR = false
                formState.odometerOCRError = error.localizedDescription
                AnalyticsService.shared.capture(.ocrFailed(ocrType: .odometer))
            }
        }
    }

    // MARK: - Save

    private func saveVehicle() {
        // Analytics: track VIN OCR confirmation at save time (VIN has no separate confirmation dialog)
        if let vinOCROriginal = formState.vinOCROriginal {
            AnalyticsService.shared.capture(.ocrConfirmed(
                ocrType: .vin,
                valueEdited: formState.vin != vinOCROriginal
            ))
        }

        // Analytics: track vehicle creation
        AnalyticsService.shared.capture(.vehicleAdded(
            usedOCR: formState.usedOdometerOCR,
            usedVINLookup: formState.usedVINLookup,
            hasNickname: !formState.name.isEmpty
        ))

        // `currentMileage` is force-unwrappable in spirit — the odometer is
        // required and Save is disabled without it — but the fallback stays
        // rather than trapping. The old form had this same `?? 0` with no
        // requirement behind it, which is how vehicles shipped at zero miles
        // and every mileage-based reminder became fiction.
        let vehicle = Vehicle(
            name: formState.name,
            make: formState.make,
            model: formState.model,
            year: formState.year ?? 0,
            currentMileage: formState.currentMileage ?? 0,
            vin: formState.vin.isEmpty ? nil : formState.vin,
            licensePlate: formState.licensePlate.isEmpty ? nil : formState.licensePlate,
            tireSize: formState.tireSize.isEmpty ? nil : formState.tireSize,
            oilType: formState.oilType.isEmpty ? nil : formState.oilType,
            notes: formState.notes.isEmpty ? nil : formState.notes
        )

        // Marbete
        vehicle.marbeteExpirationMonth = formState.marbeteExpirationMonth
        vehicle.marbeteExpirationYear = formState.marbeteExpirationYear
        if vehicle.hasMarbeteExpiration {
            NotificationService.shared.scheduleMarbeteNotifications(for: vehicle)
        }

        modelContext.insert(vehicle)
        appState.selectedVehicle = vehicle
        HapticService.shared.success()
        ToastService.shared.show(L10n.toastVehicleSaved, icon: "checkmark.circle", style: .success)
        dismiss()
    }
}

#Preview {
    AddVehicleFlowView()
        .environment(AppState())
        .modelContainer(for: Vehicle.self, inMemory: true)
        .preferredColorScheme(.dark)
}

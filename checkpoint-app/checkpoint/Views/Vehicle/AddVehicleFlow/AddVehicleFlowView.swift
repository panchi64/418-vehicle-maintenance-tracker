//
//  AddVehicleFlowView.swift
//  checkpoint
//
//  Coordinator view for the 2-step add vehicle wizard flow
//

import SwiftUI
import SwiftData

struct AddVehicleFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var formState = VehicleFormState()
    @State private var currentStep: Step = .basics

    enum Step {
        case basics
        case details
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                switch currentStep {
                case .basics:
                    VehicleBasicsStep(formState: formState)
                        .trackScreen(.addVehicleBasics)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading),
                            removal: .move(edge: .leading)
                        ))

                case .details:
                    VehicleDetailsStep(formState: formState)
                        .trackScreen(.addVehicleDetails)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentStep == .basics {
                        Button(L10n.commonCancel) {
                            dismiss()
                        }
                        .toolbarButtonStyle()
                    } else {
                        Button {
                            withAnimation(.easeInOut(duration: Theme.animationMedium)) {
                                currentStep = .basics
                            }
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "chevron.left")
                                Text(L10n.commonBack)
                            }
                        }
                        .toolbarButtonStyle()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if currentStep == .basics {
                        Button(L10n.commonNext) {
                            withAnimation(.easeInOut(duration: Theme.animationMedium)) {
                                currentStep = .details
                            }
                        }
                        .toolbarButtonStyle(isDisabled: !formState.isBasicsValid)
                        .disabled(!formState.isBasicsValid)
                    } else {
                        Button(L10n.vehicleSave) {
                            saveVehicle()
                        }
                        .toolbarButtonStyle()
                    }
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

    // MARK: - Computed Properties

    private var navigationTitle: String {
        switch currentStep {
        case .basics:
            return L10n.vehicleAdd
        case .details:
            return L10n.vehicleDetails
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

                await MainActor.run {
                    formState.isProcessingVINOCR = false
                    formState.vin = result.vin
                    formState.vinOCROriginal = result.vin
                    AnalyticsService.shared.capture(.ocrSucceeded(ocrType: .vin))
                }
            } catch {
                await MainActor.run {
                    formState.isProcessingVINOCR = false
                    formState.vinOCRError = error.localizedDescription
                    AnalyticsService.shared.capture(.ocrFailed(ocrType: .vin))
                }
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

                await MainActor.run {
                    formState.isProcessingOdometerOCR = false
                    formState.ocrResult = result
                    formState.showOCRConfirmation = true
                    formState.usedOdometerOCR = true
                    AnalyticsService.shared.capture(.ocrSucceeded(ocrType: .odometer))
                }
            } catch {
                await MainActor.run {
                    formState.isProcessingOdometerOCR = false
                    formState.odometerOCRError = error.localizedDescription
                    AnalyticsService.shared.capture(.ocrFailed(ocrType: .odometer))
                }
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

        let vehicle = Vehicle(
            name: formState.name,
            make: formState.make,
            model: formState.model,
            year: formState.year ?? 0,
            currentMileage: formState.currentMileage ?? 0,
            vin: formState.vin.isEmpty ? nil : formState.vin,
            tireSize: formState.tireSize.isEmpty ? nil : formState.tireSize,
            oilType: formState.oilType.isEmpty ? nil : formState.oilType,
            notes: formState.notes.isEmpty ? nil : formState.notes
        )
        modelContext.insert(vehicle)
        appState.selectedVehicle = vehicle
        dismiss()
    }
}

#Preview {
    AddVehicleFlowView()
        .environment(AppState())
        .modelContainer(for: Vehicle.self, inMemory: true)
        .preferredColorScheme(.dark)
}

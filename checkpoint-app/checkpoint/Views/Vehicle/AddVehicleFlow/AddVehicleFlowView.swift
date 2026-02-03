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
                    VehicleBasicsStep(
                        formState: formState,
                        onNext: {
                            withAnimation(.easeInOut(duration: Theme.animationMedium)) {
                                currentStep = .details
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))

                case .details:
                    VehicleDetailsStep(
                        formState: formState,
                        onSave: saveVehicle,
                        onSkip: saveVehicle
                    )
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
                        .foregroundStyle(Theme.accent)
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
                            .foregroundStyle(Theme.accent)
                        }
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
        formState.isProcessingVINOCR = true
        formState.vinOCRError = nil

        Task {
            do {
                let result = try await VINOCRService.shared.recognizeVIN(from: image)

                await MainActor.run {
                    formState.isProcessingVINOCR = false
                    formState.vin = result.vin
                }
            } catch {
                await MainActor.run {
                    formState.isProcessingVINOCR = false
                    formState.vinOCRError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Odometer OCR

    private func processOdometerOCR(image: UIImage) {
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
                }
            } catch {
                await MainActor.run {
                    formState.isProcessingOdometerOCR = false
                    formState.odometerOCRError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Save

    private func saveVehicle() {
        let vehicle = Vehicle(
            name: formState.name,
            make: formState.make,
            model: formState.model,
            year: formState.year ?? 0,
            currentMileage: formState.currentMileage ?? 0,
            vin: formState.vin.isEmpty ? nil : formState.vin,
            tireSize: formState.tireSize.isEmpty ? nil : formState.tireSize,
            oilType: formState.oilType.isEmpty ? nil : formState.oilType,
            notes: formState.notes.isEmpty ? nil : formState.notes,
            mileageUpdatedAt: .now
        )
        modelContext.insert(vehicle)
        dismiss()
    }
}

#Preview {
    AddVehicleFlowView()
        .modelContainer(for: Vehicle.self, inMemory: true)
        .preferredColorScheme(.dark)
}

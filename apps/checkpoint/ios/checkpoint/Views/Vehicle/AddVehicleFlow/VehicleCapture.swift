//
//  VehicleCapture.swift
//  checkpoint
//
//  Camera capture for the vehicle forms: VIN and odometer scanning, and the
//  confirmation step an odometer reading needs. Add and Edit Vehicle carried
//  identical copies of this; one modifier keeps them from drifting.
//

import SwiftUI

private struct VehicleCaptureModifier: ViewModifier {
    @Bindable var formState: VehicleFormState

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $formState.showVINCamera) {
                OdometerCameraSheet(
                    onImageCaptured: processVINOCR,
                    guideText: L10n.addVehicleVINAlignGuide,
                    viewfinderAspectRatio: 5.0
                )
            }
            .fullScreenCover(isPresented: $formState.showOdometerCamera) {
                OdometerCameraSheet(onImageCaptured: processOdometerOCR)
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

    // MARK: - VIN OCR

    private func processVINOCR(image: UIImage) {
        AnalyticsService.shared.capture(.ocrAttempted(ocrType: .vin))
        formState.isProcessingVINOCR = true
        formState.vinOCRError = nil

        Task {
            do {
                let result = try await VINOCRService.shared.recognizeVIN(from: image)
                formState.isProcessingVINOCR = false
                // A scanned VIN is complete, so the form's auto-decode picks
                // it up from here.
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
}

extension View {
    /// The VIN and odometer cameras, and the odometer confirmation, for a
    /// vehicle form.
    func vehicleCapture(_ formState: VehicleFormState) -> some View {
        modifier(VehicleCaptureModifier(formState: formState))
    }
}

enum VehicleCapture {
    /// Analytics for a scanned VIN, recorded at save time (the VIN has no
    /// confirmation step of its own).
    static func recordVINScanConfirmation(_ formState: VehicleFormState) {
        guard let original = formState.vinOCROriginal else { return }
        AnalyticsService.shared.capture(.ocrConfirmed(ocrType: .vin, valueEdited: formState.vin != original))
    }
}

//
//  EditVehicleOdometerSection.swift
//  checkpoint
//
//  Odometer/mileage input section extracted from EditVehicleView
//

import SwiftUI

struct EditVehicleOdometerSection: View {
    @Binding var currentMileage: Int?
    @Binding var showOdometerCamera: Bool
    @Binding var isProcessingOdometerOCR: Bool
    @Binding var odometerOCRError: String?

    var isCameraAvailable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Odometer")

            InstrumentNumberField(
                label: "Current Mileage",
                value: $currentMileage,
                placeholder: "0",
                suffix: "mi",
                showCameraButton: isCameraAvailable,
                onCameraTap: {
                    odometerOCRError = nil
                    showOdometerCamera = true
                }
            )

            // Odometer OCR processing indicator
            if isProcessingOdometerOCR {
                OCRProcessingIndicator(text: "Scanning odometer...")
            }

            // Odometer OCR error
            if let error = odometerOCRError {
                ErrorMessageRow(message: error) {
                    odometerOCRError = nil
                }
            }
        }
    }
}

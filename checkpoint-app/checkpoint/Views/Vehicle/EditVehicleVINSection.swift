//
//  EditVehicleVINSection.swift
//  checkpoint
//
//  VIN input section extracted from EditVehicleView
//

import SwiftUI

struct EditVehicleVINSection: View {
    @Binding var vin: String
    @Binding var licensePlate: String
    @Binding var make: String
    @Binding var model: String
    @Binding var year: Int?

    @Binding var isDecodingVIN: Bool
    @Binding var vinLookupError: String?

    @Binding var showVINCamera: Bool
    @Binding var isProcessingVINOCR: Bool
    @Binding var vinOCRError: String?
    @Binding var vinOCROriginal: String?

    var isCameraAvailable: Bool

    private var isVINValid: Bool {
        Vehicle.isValidVIN(vin)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Identification")

            VStack(alignment: .leading, spacing: 4) {
                // VIN input with camera button
                VStack(alignment: .leading, spacing: 6) {
                    Text("VIN")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)
                        .textCase(.uppercase)

                    HStack(spacing: 0) {
                        TextField("Optional", text: $vin)
                            .font(.brutalistBody)
                            .foregroundStyle(Theme.textPrimary)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding(16)
                            .background(Theme.surfaceInstrument)
                            .onChange(of: vin) {
                                vinLookupError = nil
                            }

                        // Camera scan button
                        if isCameraAvailable {
                            Button {
                                vinOCRError = nil
                                showVINCamera = true
                            } label: {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 52, height: 52)
                                    .background(Theme.surfaceInstrument)
                            }
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                            )
                        }
                    }
                    .overlay(
                        Rectangle()
                            .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                    )
                }

                HStack {
                    Text("17-CHARACTER VEHICLE IDENTIFICATION NUMBER")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .tracking(1.5)

                    Spacer()

                    if !vin.isEmpty {
                        Text("\(vin.count)/17")
                            .font(.brutalistLabel)
                            .foregroundStyle(isVINValid ? Theme.statusGood : Theme.textTertiary)
                            .tracking(1)
                    }
                }
                .padding(.leading, 4)

                // VIN OCR processing indicator
                if isProcessingVINOCR {
                    OCRProcessingIndicator(text: "Scanning VIN...")
                }

                // VIN OCR error
                if let error = vinOCRError {
                    ErrorMessageRow(message: error) {
                        vinOCRError = nil
                    }
                }

                // Look Up VIN button
                if isVINValid {
                    Button {
                        lookUpVIN()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            if isDecodingVIN {
                                ProgressView()
                                    .tint(Theme.surfaceInstrument)
                            }
                            Text(isDecodingVIN ? "Looking Up..." : "Look Up VIN")
                        }
                    }
                    .buttonStyle(.secondary)
                    .disabled(isDecodingVIN)
                    .padding(.top, Spacing.xs)
                }

                // VIN lookup error
                if let error = vinLookupError {
                    ErrorMessageRow(message: error) {
                        vinLookupError = nil
                    }
                }
            }

            InstrumentTextField(
                label: "License Plate",
                text: $licensePlate,
                placeholder: "ABC-1234 (Optional)"
            )
        }
    }

    // MARK: - VIN Lookup

    private func lookUpVIN() {
        isDecodingVIN = true
        vinLookupError = nil

        Task {
            do {
                let result = try await NHTSAService.shared.decodeVIN(vin)

                await MainActor.run {
                    isDecodingVIN = false
                    // Track which fields were already populated
                    let makeSkipped = !make.isEmpty
                    let modelSkipped = !model.isEmpty
                    let yearSkipped = year != nil

                    // Auto-fill only empty fields
                    if !makeSkipped { make = result.make }
                    if !modelSkipped { model = result.model }
                    if !yearSkipped { year = result.modelYear }

                    // Notify user if all fields were already populated
                    if makeSkipped && modelSkipped && yearSkipped {
                        ToastService.shared.show("FIELDS ALREADY POPULATED", icon: "info.circle", style: .info)
                    } else if makeSkipped || modelSkipped || yearSkipped {
                        ToastService.shared.show("SOME FIELDS ALREADY POPULATED", icon: "info.circle", style: .info)
                    } else {
                        HapticService.shared.success()
                    }
                }
            } catch {
                await MainActor.run {
                    isDecodingVIN = false
                    vinLookupError = error.localizedDescription
                }
            }
        }
    }
}

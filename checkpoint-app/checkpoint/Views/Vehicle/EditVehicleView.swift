//
//  EditVehicleView.swift
//  checkpoint
//
//  Form to edit existing vehicles with delete option and instrument cluster aesthetic
//

import SwiftUI
import SwiftData

struct EditVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var services: [Service]

    @Bindable var vehicle: Vehicle

    @State private var showDeleteConfirmation = false

    // Form state (initialize from vehicle)
    @State private var name: String
    @State private var make: String
    @State private var model: String
    @State private var year: Int?
    @State private var currentMileage: Int?
    @State private var vin: String
    @State private var tireSize: String
    @State private var oilType: String
    @State private var notes: String

    // VIN lookup state
    @State private var isDecodingVIN = false
    @State private var vinLookupError: String?

    // VIN scan state
    @State private var showVINCamera = false
    @State private var isProcessingVINOCR = false
    @State private var vinOCRError: String?

    // Odometer scan state
    @State private var showOdometerCamera = false
    @State private var showOCRConfirmation = false
    @State private var ocrResult: OdometerOCRService.OCRResult?
    @State private var ocrDebugImage: UIImage?
    @State private var isProcessingOdometerOCR = false
    @State private var odometerOCRError: String?

    // Marbete state
    @State private var marbeteExpirationMonth: Int?
    @State private var marbeteExpirationYear: Int?

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        _name = State(initialValue: vehicle.name)
        _make = State(initialValue: vehicle.make)
        _model = State(initialValue: vehicle.model)
        _year = State(initialValue: vehicle.year)
        _currentMileage = State(initialValue: vehicle.currentMileage)
        _vin = State(initialValue: vehicle.vin ?? "")
        _tireSize = State(initialValue: vehicle.tireSize ?? "")
        _oilType = State(initialValue: vehicle.oilType ?? "")
        _notes = State(initialValue: vehicle.notes ?? "")
        _marbeteExpirationMonth = State(initialValue: vehicle.marbeteExpirationMonth)
        _marbeteExpirationYear = State(initialValue: vehicle.marbeteExpirationYear)
    }

    private var isFormValid: Bool {
        !make.isEmpty && !model.isEmpty && year != nil
    }

    private var isVINValid: Bool {
        let trimmed = vin.trimmingCharacters(in: .whitespaces)
        guard trimmed.count == 17 else { return false }
        let forbidden = CharacterSet(charactersIn: "IOQioq")
        return trimmed.unicodeScalars.allSatisfy { !forbidden.contains($0) && CharacterSet.alphanumerics.contains($0) }
    }

    /// Check if camera is available (requires physical device)
    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Vehicle Details Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Vehicle Details")

                            VStack(spacing: Spacing.md) {
                                InstrumentTextField(
                                    label: "Nickname",
                                    text: $name,
                                    placeholder: "Optional"
                                )

                                InstrumentTextField(
                                    label: "Make",
                                    text: $make,
                                    placeholder: "Toyota, Honda, Ford..."
                                )

                                InstrumentTextField(
                                    label: "Model",
                                    text: $model,
                                    placeholder: "Camry, Civic, F-150..."
                                )

                                InstrumentNumberField(
                                    label: "Year",
                                    value: $year,
                                    placeholder: "2024"
                                )
                            }
                        }

                        // Odometer Section
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
                                HStack(spacing: Spacing.sm) {
                                    ProgressView()
                                        .tint(Theme.accent)
                                    Text("SCANNING ODOMETER...")
                                        .font(.brutalistLabel)
                                        .foregroundStyle(Theme.textSecondary)
                                        .tracking(1)
                                }
                                .padding(Spacing.md)
                                .frame(maxWidth: .infinity)
                                .background(Theme.surfaceInstrument)
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                                )
                            }

                            // Odometer OCR error
                            if let error = odometerOCRError {
                                vinErrorRow(error) {
                                    odometerOCRError = nil
                                }
                            }
                        }

                        // VIN Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Identification")

                            VStack(alignment: .leading, spacing: 4) {
                                // VIN input with camera button
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("VIN")
                                        .font(.instrumentLabel)
                                        .foregroundStyle(Theme.textTertiary)
                                        .tracking(1.5)
                                        .textCase(.uppercase)

                                    HStack(spacing: 0) {
                                        TextField("Optional", text: $vin)
                                            .font(.instrumentBody)
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

                                Text("17-character Vehicle Identification Number")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textTertiary)
                                    .padding(.leading, 4)

                                // VIN OCR processing indicator
                                if isProcessingVINOCR {
                                    HStack(spacing: Spacing.sm) {
                                        ProgressView()
                                            .tint(Theme.accent)
                                        Text("SCANNING VIN...")
                                            .font(.brutalistLabel)
                                            .foregroundStyle(Theme.textSecondary)
                                            .tracking(1)
                                    }
                                    .padding(Spacing.md)
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.surfaceInstrument)
                                    .overlay(
                                        Rectangle()
                                            .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                                    )
                                }

                                // VIN OCR error
                                if let error = vinOCRError {
                                    vinErrorRow(error) {
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
                                    vinErrorRow(error) {
                                        vinLookupError = nil
                                    }
                                }
                            }
                        }

                        // Specifications Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Specifications")

                            VStack(spacing: Spacing.md) {
                                InstrumentTextField(
                                    label: "Tire Size",
                                    text: $tireSize,
                                    placeholder: "225/45R17 (Optional)"
                                )

                                InstrumentTextField(
                                    label: "Oil Type",
                                    text: $oilType,
                                    placeholder: "0W-20 Synthetic (Optional)"
                                )
                            }
                        }

                        // Marbete Section (PR vehicle registration tag)
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Marbete")

                            VStack(spacing: Spacing.md) {
                                // Month picker
                                marbeteMonthPicker

                                // Year picker
                                marbeteYearPicker

                                // Status indicator (only shown when marbete is set)
                                if marbeteExpirationMonth != nil && marbeteExpirationYear != nil {
                                    marbeteStatusIndicator
                                }
                            }

                            Text("Puerto Rico vehicle registration tag expiration (optional)")
                                .font(.caption)
                                .foregroundStyle(Theme.textTertiary)
                                .padding(.leading, 4)
                        }

                        // Notes Section
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            InstrumentSectionHeader(title: "Notes")

                            InstrumentTextEditor(
                                label: "Notes",
                                text: $notes,
                                placeholder: "Vehicle quirks, history, reminders..."
                            )
                        }

                        // Save button
                        Button("Save Changes") {
                            saveChanges()
                        }
                        .buttonStyle(.primary)
                        .disabled(!isFormValid)
                        .padding(.top, Spacing.md)

                        // Delete button
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Vehicle")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.statusOverdue)
                            .frame(maxWidth: .infinity)
                            .frame(height: Theme.buttonHeight)
                            .background(Theme.statusOverdue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous)
                                    .strokeBorder(Theme.statusOverdue.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("Edit Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
            .confirmationDialog(
                "Delete Vehicle?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteVehicle() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will also delete all services for this vehicle. This action cannot be undone.")
            }
            .fullScreenCover(isPresented: $showVINCamera) {
                OdometerCameraSheet(
                    onImageCaptured: { image in
                        processVINOCR(image: image)
                    },
                    guideText: "ALIGN VIN HERE",
                    viewfinderAspectRatio: 5.0
                )
            }
            .fullScreenCover(isPresented: $showOdometerCamera) {
                OdometerCameraSheet { image in
                    processOdometerOCR(image: image)
                }
            }
            .sheet(isPresented: $showOCRConfirmation) {
                if let result = ocrResult {
                    OCRConfirmationView(
                        extractedMileage: result.mileage,
                        confidence: result.confidence,
                        onConfirm: { mileage in
                            currentMileage = mileage
                        },
                        currentMileage: currentMileage ?? 0,
                        detectedUnit: result.detectedUnit,
                        rawText: result.rawText,
                        debugImage: ocrDebugImage
                    )
                    .presentationDetents([.medium])
                }
            }
        }
    }

    // MARK: - VIN Error Row

    private func vinErrorRow(_ error: String, onDismiss: @escaping () -> Void) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.statusOverdue)

            Text(error.uppercased())
                .font(.brutalistLabel)
                .foregroundStyle(Theme.statusOverdue)
                .tracking(1)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(Spacing.md)
        .background(Theme.statusOverdue.opacity(0.1))
        .overlay(
            Rectangle()
                .strokeBorder(Theme.statusOverdue.opacity(0.5), lineWidth: Theme.borderWidth)
        )
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
                    // Auto-fill only empty fields
                    if make.isEmpty { make = result.make }
                    if model.isEmpty { model = result.model }
                    if year == nil { year = result.modelYear }
                }
            } catch {
                await MainActor.run {
                    isDecodingVIN = false
                    vinLookupError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - VIN OCR

    private func processVINOCR(image: UIImage) {
        isProcessingVINOCR = true
        vinOCRError = nil

        Task {
            do {
                let result = try await VINOCRService.shared.recognizeVIN(from: image)

                await MainActor.run {
                    isProcessingVINOCR = false
                    vin = result.vin
                }
            } catch {
                await MainActor.run {
                    isProcessingVINOCR = false
                    vinOCRError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Odometer OCR

    private func processOdometerOCR(image: UIImage) {
        isProcessingOdometerOCR = true
        odometerOCRError = nil
        ocrDebugImage = image

        Task {
            do {
                let result = try await OdometerOCRService.shared.recognizeMileage(
                    from: image,
                    currentMileage: currentMileage
                )

                await MainActor.run {
                    isProcessingOdometerOCR = false
                    ocrResult = result
                    showOCRConfirmation = true
                }
            } catch {
                await MainActor.run {
                    isProcessingOdometerOCR = false
                    odometerOCRError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Marbete Pickers

    private var marbeteMonthPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EXPIRATION MONTH")
                .font(.instrumentLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)
                .textCase(.uppercase)

            Menu {
                Button("Not Set") {
                    marbeteExpirationMonth = nil
                }
                Divider()
                ForEach(1...12, id: \.self) { month in
                    Button(Calendar.current.monthSymbols[month - 1]) {
                        marbeteExpirationMonth = month
                    }
                }
            } label: {
                HStack {
                    if let month = marbeteExpirationMonth {
                        Text(Calendar.current.monthSymbols[month - 1])
                            .font(.instrumentBody)
                            .foregroundStyle(Theme.textPrimary)
                    } else {
                        Text("Not Set")
                            .font(.instrumentBody)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(16)
                .background(Theme.surfaceInstrument)
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                )
            }
        }
    }

    private var marbeteYearPicker: some View {
        let currentYear = Calendar.current.component(.year, from: .now)
        let yearRange = currentYear...(currentYear + 2)

        return VStack(alignment: .leading, spacing: 6) {
            Text("EXPIRATION YEAR")
                .font(.instrumentLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1.5)
                .textCase(.uppercase)

            Menu {
                Button("Not Set") {
                    marbeteExpirationYear = nil
                }
                Divider()
                ForEach(yearRange, id: \.self) { year in
                    Button(String(year)) {
                        marbeteExpirationYear = year
                    }
                }
            } label: {
                HStack {
                    if let year = marbeteExpirationYear {
                        Text(String(year))
                            .font(.instrumentBody)
                            .foregroundStyle(Theme.textPrimary)
                    } else {
                        Text("Not Set")
                            .font(.instrumentBody)
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(16)
                .background(Theme.surfaceInstrument)
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                )
            }
        }
    }

    private var marbeteStatusIndicator: some View {
        let status = computeMarbeteStatus()
        let statusText = marbeteStatusText(for: status)

        return HStack(spacing: Spacing.sm) {
            Rectangle()
                .fill(status.color)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.brutalistSecondary)
                .foregroundStyle(status.color)

            Spacer()

            if let formatted = marbeteFormattedExpiration() {
                Text(formatted)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(status.color.opacity(0.1))
        .overlay(
            Rectangle()
                .strokeBorder(status.color.opacity(0.3), lineWidth: Theme.borderWidth)
        )
    }

    private func computeMarbeteStatus() -> ServiceStatus {
        guard let month = marbeteExpirationMonth,
              let year = marbeteExpirationYear else { return .neutral }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let firstDay = Calendar.current.date(from: components),
              let lastDay = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay) else {
            return .neutral
        }

        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: lastDay)).day ?? 0

        if days < 0 {
            return .overdue
        } else if days <= 60 {
            return .dueSoon
        } else {
            return .good
        }
    }

    private func marbeteStatusText(for status: ServiceStatus) -> String {
        switch status {
        case .overdue: return "EXPIRED"
        case .dueSoon: return "EXPIRES SOON"
        case .good: return "VALID"
        case .neutral: return ""
        }
    }

    private func marbeteFormattedExpiration() -> String? {
        guard let month = marbeteExpirationMonth,
              let year = marbeteExpirationYear else { return nil }
        let monthName = Calendar.current.monthSymbols[month - 1]
        return "\(monthName) \(year)"
    }

    // MARK: - Save

    private func saveChanges() {
        vehicle.name = name
        vehicle.make = make
        vehicle.model = model
        vehicle.year = year ?? vehicle.year
        vehicle.currentMileage = currentMileage ?? vehicle.currentMileage
        vehicle.vin = vin.isEmpty ? nil : vin
        vehicle.tireSize = tireSize.isEmpty ? nil : tireSize
        vehicle.oilType = oilType.isEmpty ? nil : oilType
        vehicle.notes = notes.isEmpty ? nil : notes

        // Update marbete
        let oldHasMarbete = vehicle.hasMarbeteExpiration
        vehicle.marbeteExpirationMonth = marbeteExpirationMonth
        vehicle.marbeteExpirationYear = marbeteExpirationYear

        // Schedule/cancel marbete notifications
        if vehicle.hasMarbeteExpiration {
            NotificationService.shared.scheduleMarbeteNotifications(for: vehicle)
        } else if oldHasMarbete {
            NotificationService.shared.cancelMarbeteNotifications(for: vehicle)
        }

        updateAppIcon()
        updateWidgetData()
        dismiss()
    }

    private func deleteVehicle() {
        modelContext.delete(vehicle)
        updateAppIcon()
        WidgetDataService.shared.clearWidgetData()
        dismiss()
    }

    // MARK: - App Icon

    private func updateAppIcon() {
        AppIconService.shared.updateIcon(for: vehicle, services: services)
    }

    // MARK: - Widget Data

    private func updateWidgetData() {
        WidgetDataService.shared.updateWidget(for: vehicle)
    }
}

#Preview {
    @Previewable @State var vehicle = Vehicle(
        name: "Daily Driver",
        make: "Toyota",
        model: "Camry",
        year: 2022,
        currentMileage: 32500,
        vin: "1HGBH41JXMN109186",
        tireSize: "225/45R17",
        oilType: "0W-20 Synthetic"
    )

    EditVehicleView(vehicle: vehicle)
        .modelContainer(for: Vehicle.self, inMemory: true)
}

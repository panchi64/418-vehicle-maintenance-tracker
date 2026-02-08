//
//  CSVImportView.swift
//  checkpoint
//
//  Multi-step CSV import wizard: file picker -> configure -> preview -> success
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Import Step

private enum ImportStep: Int, CaseIterable {
    case pickFile = 0
    case configure = 1
    case preview = 2
    case success = 3

    var title: String {
        switch self {
        case .pickFile: return "SELECT FILE"
        case .configure: return "CONFIGURE"
        case .preview: return "PREVIEW"
        case .success: return "COMPLETE"
        }
    }
}

// MARK: - CSV Import View

struct CSVImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Vehicle.name) private var vehicles: [Vehicle]

    @State private var importService = CSVImportService.shared
    @State private var currentStep: ImportStep = .pickFile
    @State private var showFilePicker = false
    @State private var selectedVehicle: Vehicle?
    @State private var createNewVehicle = false
    @State private var newVehicleName = ""
    @State private var errorMessage: String?
    @State private var importResult: CSVImportResult?
    @State private var selectedSource: CSVImportSource = .custom

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Step indicator
                        stepIndicator

                        // Current step content
                        switch currentStep {
                        case .pickFile:
                            pickFileStep
                        case .configure:
                            configureStep
                        case .preview:
                            previewStep
                        case .success:
                            successStep
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .navigationTitle("IMPORT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentStep != .success {
                        Button("CANCEL") {
                            importService.reset()
                            dismiss()
                        }
                        .toolbarButtonStyle()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if currentStep == .success {
                        Button("DONE") {
                            importService.reset()
                            dismiss()
                        }
                        .toolbarButtonStyle()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(ImportStep.allCases, id: \.rawValue) { step in
                HStack(spacing: Spacing.xs) {
                    // Step number
                    Text("\(step.rawValue + 1)")
                        .font(.brutalistLabel)
                        .foregroundStyle(
                            step.rawValue <= currentStep.rawValue
                                ? Theme.accent
                                : Theme.textTertiary
                        )
                        .tracking(1)

                    if step == currentStep {
                        Text(step.title)
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.accent)
                            .tracking(1.5)
                    }
                }

                if step != ImportStep.allCases.last {
                    Rectangle()
                        .fill(
                            step.rawValue < currentStep.rawValue
                                ? Theme.accent
                                : Theme.gridLine
                        )
                        .frame(height: Theme.borderWidth)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Spacing.xs)
                }
            }
        }
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    // MARK: - Step 1: Pick File

    private var pickFileStep: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            InstrumentSectionHeader(title: "Import Service History")

            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Import your maintenance records from Fuelly, Drivvo, Simply Auto, or any CSV file.")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)

                Text("Supported formats: Fuelly, Drivvo, Simply Auto, Custom CSV")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.textTertiary)
                    .tracking(1)
            }

            Button {
                showFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Select CSV File")
                }
            }
            .buttonStyle(.primary)

            if let error = errorMessage {
                Text(error)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.statusOverdue)
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surfaceInstrument)
                    .overlay(
                        Rectangle()
                            .strokeBorder(Theme.statusOverdue.opacity(0.5), lineWidth: Theme.borderWidth)
                    )
            }
        }
    }

    // MARK: - Step 2: Configure

    private var configureStep: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Source detection
            InstrumentSectionHeader(title: "Source Format")

            VStack(spacing: 0) {
                ForEach(CSVImportSource.allCases) { source in
                    Button {
                        selectedSource = source
                        importService.detectedSource = source
                        importService.columnMapping = importService.autoMapColumns(
                            headers: importService.headers,
                            source: source
                        )
                    } label: {
                        HStack {
                            Text(source.rawValue)
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()

                            if selectedSource == source {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.accent)
                            }

                            if source == importService.detectedSource && source != .custom {
                                Text("DETECTED")
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.statusGood)
                                    .tracking(1)
                            }
                        }
                        .padding(Spacing.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if source != CSVImportSource.allCases.last {
                        Rectangle()
                            .fill(Theme.gridLine)
                            .frame(height: Theme.borderWidth)
                    }
                }
            }
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )

            // Column mapping
            InstrumentSectionHeader(title: "Column Mapping")

            VStack(spacing: 0) {
                columnMappingRow(
                    label: "DATE",
                    selectedColumn: Binding(
                        get: { importService.columnMapping.dateColumn },
                        set: { importService.columnMapping.dateColumn = $0 }
                    )
                )

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                columnMappingRow(
                    label: "SERVICE NAME",
                    selectedColumn: Binding(
                        get: { importService.columnMapping.descriptionColumn },
                        set: { importService.columnMapping.descriptionColumn = $0 }
                    )
                )

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                columnMappingRow(
                    label: "ODOMETER",
                    selectedColumn: Binding(
                        get: { importService.columnMapping.odometerColumn },
                        set: { importService.columnMapping.odometerColumn = $0 }
                    )
                )

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                columnMappingRow(
                    label: "COST",
                    selectedColumn: Binding(
                        get: { importService.columnMapping.costColumn },
                        set: { importService.columnMapping.costColumn = $0 }
                    )
                )

                Rectangle()
                    .fill(Theme.gridLine)
                    .frame(height: Theme.borderWidth)

                columnMappingRow(
                    label: "NOTES",
                    selectedColumn: Binding(
                        get: { importService.columnMapping.notesColumn },
                        set: { importService.columnMapping.notesColumn = $0 }
                    )
                )
            }
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )

            // Data preview (first 3 rows)
            if !importService.previewRows.isEmpty {
                InstrumentSectionHeader(title: "Data Preview")

                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header row
                        HStack(spacing: 0) {
                            ForEach(Array(importService.headers.enumerated()), id: \.offset) { index, header in
                                Text(header.uppercased())
                                    .font(.brutalistLabel)
                                    .foregroundStyle(Theme.accent)
                                    .tracking(1)
                                    .frame(width: 120, alignment: .leading)
                                    .padding(.vertical, Spacing.sm)
                                    .padding(.horizontal, Spacing.sm)

                                if index < importService.headers.count - 1 {
                                    Rectangle()
                                        .fill(Theme.gridLine)
                                        .frame(width: Theme.borderWidth)
                                }
                            }
                        }

                        Rectangle()
                            .fill(Theme.gridLine)
                            .frame(height: Theme.borderWidth)

                        // Data rows
                        ForEach(Array(importService.previewRows.enumerated()), id: \.offset) { rowIndex, row in
                            HStack(spacing: 0) {
                                ForEach(Array(importService.headers.indices), id: \.self) { colIndex in
                                    Text(colIndex < row.count ? row[colIndex] : "")
                                        .font(.brutalistSecondary)
                                        .foregroundStyle(Theme.textSecondary)
                                        .frame(width: 120, alignment: .leading)
                                        .padding(.vertical, Spacing.sm)
                                        .padding(.horizontal, Spacing.sm)
                                        .lineLimit(1)

                                    if colIndex < importService.headers.count - 1 {
                                        Rectangle()
                                            .fill(Theme.gridLine)
                                            .frame(width: Theme.borderWidth)
                                    }
                                }
                            }

                            if rowIndex < importService.previewRows.count - 1 {
                                Rectangle()
                                    .fill(Theme.gridLine)
                                    .frame(height: Theme.borderWidth)
                            }
                        }
                    }
                    .background(Theme.surfaceInstrument)
                    .overlay(
                        Rectangle()
                            .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                    )
                }
            }

            Button {
                let preview = importService.generatePreview(
                    distanceUnit: DistanceSettings.shared.unit
                )

                if preview.logCount == 0 {
                    errorMessage = "No valid rows could be parsed. Check your column mapping."
                } else {
                    errorMessage = nil
                    currentStep = .preview
                }
            } label: {
                Text("Preview Import")
            }
            .buttonStyle(.primary)

            if let error = errorMessage {
                Text(error)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.statusOverdue)
            }
        }
    }

    // MARK: - Step 3: Preview

    private var previewStep: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            guard let preview = importService.importPreview else {
                return AnyView(EmptyView())
            }

            return AnyView(VStack(alignment: .leading, spacing: Spacing.lg) {
                InstrumentSectionHeader(title: "Import Summary")

                // Stats row
                HStack(spacing: Spacing.md) {
                    statCard(
                        value: "\(preview.serviceCount)",
                        label: "SERVICES"
                    )
                    statCard(
                        value: "\(preview.logCount)",
                        label: "LOGS"
                    )
                    statCard(
                        value: Formatters.currencyWhole(preview.totalCost),
                        label: "TOTAL COST"
                    )
                }

                // Service names
                InstrumentSectionHeader(title: "Services to Create")

                VStack(spacing: 0) {
                    ForEach(Array(preview.serviceNames.enumerated()), id: \.offset) { index, name in
                        let count = preview.parsedRows.filter { $0.serviceName == name }.count

                        HStack {
                            Text(name)
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()

                            Text("\(count) LOGS")
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)
                        }
                        .padding(Spacing.md)

                        if index < preview.serviceNames.count - 1 {
                            Rectangle()
                                .fill(Theme.gridLine)
                                .frame(height: Theme.borderWidth)
                        }
                    }
                }
                .background(Theme.surfaceInstrument)
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                )

                // Vehicle assignment
                InstrumentSectionHeader(title: "Assign to Vehicle")

                VStack(spacing: 0) {
                    ForEach(vehicles) { vehicle in
                        Button {
                            selectedVehicle = vehicle
                            createNewVehicle = false
                        } label: {
                            HStack {
                                Text(vehicle.displayName)
                                    .font(.brutalistBody)
                                    .foregroundStyle(Theme.textPrimary)

                                Spacer()

                                if selectedVehicle?.id == vehicle.id && !createNewVehicle {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.accent)
                                }
                            }
                            .padding(Spacing.md)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Rectangle()
                            .fill(Theme.gridLine)
                            .frame(height: Theme.borderWidth)
                    }

                    // Create new vehicle option
                    Button {
                        createNewVehicle = true
                        selectedVehicle = nil
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.accent)

                            Text("Create New Vehicle")
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()

                            if createNewVehicle {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .padding(Spacing.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if createNewVehicle {
                        Rectangle()
                            .fill(Theme.gridLine)
                            .frame(height: Theme.borderWidth)

                        HStack {
                            TextField("Vehicle Name", text: $newVehicleName)
                                .font(.brutalistBody)
                                .foregroundStyle(Theme.textPrimary)
                                .textFieldStyle(.plain)
                        }
                        .padding(Spacing.md)
                    }
                }
                .background(Theme.surfaceInstrument)
                .overlay(
                    Rectangle()
                        .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                )

                // Warnings
                if !preview.warnings.isEmpty {
                    InstrumentSectionHeader(title: "Warnings (\(preview.warnings.count))")

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(preview.warnings.prefix(10)) { warning in
                            Text(warning.message)
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.statusDueSoon)
                                .tracking(1)
                        }
                        if preview.warnings.count > 10 {
                            Text("AND \(preview.warnings.count - 10) MORE...")
                                .font(.brutalistLabel)
                                .foregroundStyle(Theme.textTertiary)
                                .tracking(1)
                        }
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surfaceInstrument)
                    .overlay(
                        Rectangle()
                            .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
                    )
                }

                // Buttons
                HStack(spacing: Spacing.md) {
                    Button {
                        currentStep = .configure
                    } label: {
                        Text("Back")
                    }
                    .buttonStyle(.secondary)

                    Button {
                        performImport(preview: preview)
                    } label: {
                        Text("Import")
                    }
                    .buttonStyle(.primary)
                    .disabled(!canImport)
                    .opacity(canImport ? 1.0 : 0.5)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.statusOverdue)
                }
            })
        }
    }

    // MARK: - Step 4: Success

    private var successStep: some View {
        VStack(spacing: Spacing.lg) {
            guard let result = importResult else {
                return AnyView(EmptyView())
            }

            return AnyView(VStack(spacing: Spacing.lg) {
                Spacer()
                    .frame(height: Spacing.xl)

                // Success icon
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Theme.statusGood)

                Text("IMPORT COMPLETE")
                    .font(.brutalistLabel)
                    .foregroundStyle(Theme.statusGood)
                    .tracking(2)

                // Stats
                HStack(spacing: Spacing.md) {
                    statCard(
                        value: "\(result.servicesCreated)",
                        label: "SERVICES"
                    )
                    statCard(
                        value: "\(result.logsCreated)",
                        label: "LOGS"
                    )
                    statCard(
                        value: Formatters.currencyWhole(result.totalCost),
                        label: "TOTAL"
                    )
                }
            }
            .frame(maxWidth: .infinity))
        }
    }

    // MARK: - Helpers

    private var canImport: Bool {
        if createNewVehicle {
            return !newVehicleName.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return selectedVehicle != nil
    }

    private func columnMappingRow(
        label: String,
        selectedColumn: Binding<Int?>
    ) -> some View {
        HStack {
            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
                .frame(width: 120, alignment: .leading)

            Spacer()

            Picker("", selection: selectedColumn) {
                Text("None")
                    .tag(nil as Int?)
                ForEach(Array(importService.headers.enumerated()), id: \.offset) { index, header in
                    Text(header)
                        .tag(index as Int?)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accent)
        }
        .padding(Spacing.md)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)

            Text(label)
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                try importService.loadCSV(from: url)
                selectedSource = importService.detectedSource
                errorMessage = nil
                currentStep = .configure
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func performImport(preview: CSVImportPreview) {
        let vehicle: Vehicle
        if createNewVehicle {
            let trimmedName = newVehicleName.trimmingCharacters(in: .whitespaces)
            vehicle = Vehicle(name: trimmedName, make: "", model: "", year: 0)
            modelContext.insert(vehicle)
        } else if let selected = selectedVehicle {
            vehicle = selected
        } else {
            errorMessage = "Please select a vehicle."
            return
        }

        let result = importService.commitImport(
            to: vehicle,
            preview: preview,
            modelContext: modelContext
        )

        importResult = result
        errorMessage = nil
        currentStep = .success
    }
}

#Preview {
    CSVImportView()
        .preferredColorScheme(.dark)
}

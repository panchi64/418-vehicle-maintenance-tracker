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

enum CSVImportStep: Int, CaseIterable {
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
    @State private var currentStep: CSVImportStep = .pickFile
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
                            CSVImportPickFileStep(
                                onSelectFile: { showFilePicker = true },
                                errorMessage: errorMessage
                            )
                        case .configure:
                            CSVImportConfigureStep(
                                importService: importService,
                                selectedSource: $selectedSource,
                                currentStep: $currentStep,
                                errorMessage: $errorMessage
                            )
                        case .preview:
                            if let preview = importService.importPreview {
                                CSVImportPreviewStep(
                                    preview: preview,
                                    vehicles: vehicles,
                                    selectedVehicle: $selectedVehicle,
                                    createNewVehicle: $createNewVehicle,
                                    newVehicleName: $newVehicleName,
                                    currentStep: $currentStep,
                                    errorMessage: $errorMessage,
                                    onImport: { performImport(preview: $0) }
                                )
                            }
                        case .success:
                            CSVImportSuccessStep(result: importResult)
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
            ForEach(CSVImportStep.allCases, id: \.rawValue) { step in
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

                if step != CSVImportStep.allCases.last {
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

    // MARK: - Helpers

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

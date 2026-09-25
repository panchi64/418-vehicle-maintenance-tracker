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
    @State private var pendingImportPreview: CSVImportPreview?
    @State private var showImportConfirmation = false

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
                                    onImport: { preview in
                                        pendingImportPreview = preview
                                        showImportConfirmation = true
                                    }
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
            .keyboardDismissToolbar()
            .navigationTitle(L10n.importNavTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentStep != .success {
                        Button(L10n.commonCancel) {
                            importService.reset()
                            dismiss()
                        }
                        .toolbarButtonStyle()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if currentStep == .success {
                        Button(L10n.commonDone) {
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
            .alert(L10n.importConfirmTitle, isPresented: $showImportConfirmation) {
                Button(L10n.commonCancel, role: .cancel) {
                    pendingImportPreview = nil
                }
                Button(L10n.importConfirmAction) {
                    if let preview = pendingImportPreview {
                        performImport(preview: preview)
                        pendingImportPreview = nil
                    }
                }
            } message: {
                if let preview = pendingImportPreview {
                    let vehicleName = createNewVehicle
                        ? newVehicleName
                        : (selectedVehicle?.displayName ?? L10n.importConfirmFallbackVehicle)
                    Text(L10n.importConfirmMessage(
                        services: preview.serviceCount,
                        logs: preview.logCount,
                        vehicle: vehicleName
                    ))
                }
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(CSVImportStep.allCases, id: \.rawValue) { step in
                HStack(spacing: Spacing.xs) {
                    // Step number
                    Text(verbatim: "\(step.rawValue + 1)")
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
        .brutalistBorder()
        // Progress is drawn with accent color; say it in words instead.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.stepOfTotal(currentStep.rawValue + 1, CSVImportStep.allCases.count))
        .accessibilityValue(currentStep.title)
    }

    // MARK: - Helpers

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task {
                do {
                    try await importService.loadCSV(from: url)
                    selectedSource = importService.detectedSource
                    errorMessage = nil
                    currentStep = .configure
                } catch {
                    errorMessage = error.localizedDescription
                }
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
            errorMessage = L10n.importSelectVehicleError
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

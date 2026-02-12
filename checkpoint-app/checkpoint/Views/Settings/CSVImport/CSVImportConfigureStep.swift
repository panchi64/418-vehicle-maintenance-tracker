//
//  CSVImportConfigureStep.swift
//  checkpoint
//
//  Step 2 of CSV import wizard: source format selection and column mapping
//

import SwiftUI

struct CSVImportConfigureStep: View {
    @Bindable var importService: CSVImportService
    @Binding var selectedSource: CSVImportSource
    @Binding var currentStep: CSVImportStep
    @Binding var errorMessage: String?

    var body: some View {
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
}

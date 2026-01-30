//
//  ConflictResolutionView.swift
//  checkpoint
//
//  View for resolving sync conflicts between local and remote data
//

import SwiftUI

/// Represents a conflict between local and remote versions of data
struct SyncConflict: Identifiable {
    let id = UUID()
    let entityType: EntityType
    let entityName: String
    let localValue: String
    let remoteValue: String
    let localModifiedAt: Date
    let remoteModifiedAt: Date
    let fieldName: String

    enum EntityType: String {
        case vehicle = "Vehicle"
        case service = "Service"
        case serviceLog = "Service Log"
        case mileageSnapshot = "Mileage"
    }
}

/// View for presenting and resolving sync conflicts
struct ConflictResolutionView: View {
    let conflict: SyncConflict
    let onResolve: (ConflictResolution) -> Void

    @Environment(\.dismiss) private var dismiss

    enum ConflictResolution {
        case keepLocal
        case keepRemote
        case keepBoth
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Header explanation
                        headerSection

                        // Conflict details
                        conflictDetailsSection

                        // Version comparison
                        versionComparisonSection

                        // Resolution options
                        resolutionOptionsSection
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle("Sync Conflict")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.statusDueSoon)

                Text("Data Changed on Multiple Devices")
                    .font(.brutalistTitle)
                    .foregroundStyle(Theme.textPrimary)
            }

            Text("This \(conflict.entityType.rawValue.lowercased()) was edited on two devices. Choose which version to keep.")
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Conflict Details Section

    private var conflictDetailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("AFFECTED ITEM")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(conflict.entityName)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    Text("\(conflict.fieldName) field")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                conflictBadge
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
    }

    private var conflictBadge: some View {
        Text(conflict.entityType.rawValue)
            .font(.brutalistSecondary)
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Theme.accent.opacity(0.15))
    }

    // MARK: - Version Comparison Section

    private var versionComparisonSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("COMPARE VERSIONS")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            HStack(spacing: Spacing.md) {
                // Local version
                versionCard(
                    title: "This Device",
                    value: conflict.localValue,
                    modifiedAt: conflict.localModifiedAt,
                    icon: "iphone",
                    isLocal: true
                )

                // Remote version
                versionCard(
                    title: "Other Device",
                    value: conflict.remoteValue,
                    modifiedAt: conflict.remoteModifiedAt,
                    icon: "icloud",
                    isLocal: false
                )
            }
        }
    }

    private func versionCard(
        title: String,
        value: String,
        modifiedAt: Date,
        icon: String,
        isLocal: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(isLocal ? Theme.accent : Theme.textSecondary)

                Text(title)
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
            }

            Text(value)
                .font(.brutalistBody)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(3)

            Text(formatDate(modifiedAt))
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surfaceInstrument)
        .overlay(
            Rectangle()
                .strokeBorder(
                    isLocal ? Theme.accent.opacity(0.5) : Theme.gridLine,
                    lineWidth: Theme.borderWidth
                )
        )
    }

    // MARK: - Resolution Options Section

    private var resolutionOptionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("CHOOSE ACTION")
                .font(.brutalistLabel)
                .foregroundStyle(Theme.textTertiary)
                .tracking(2)

            VStack(spacing: Spacing.sm) {
                resolutionButton(
                    title: "Keep This Device",
                    description: "Use the version from this device",
                    icon: "iphone",
                    resolution: .keepLocal
                )

                resolutionButton(
                    title: "Keep Other Device",
                    description: "Use the version from iCloud",
                    icon: "icloud",
                    resolution: .keepRemote
                )

                resolutionButton(
                    title: "Keep Both",
                    description: "Create a duplicate entry",
                    icon: "doc.on.doc",
                    resolution: .keepBoth
                )
            }
        }
    }

    private func resolutionButton(
        title: String,
        description: String,
        icon: String,
        resolution: ConflictResolution
    ) -> some View {
        Button {
            onResolve(resolution)
            dismiss()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    Text(description)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Conflict List View

/// View for displaying multiple pending conflicts
struct ConflictListView: View {
    let conflicts: [SyncConflict]
    let onResolve: (SyncConflict, ConflictResolutionView.ConflictResolution) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedConflict: SyncConflict?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                if conflicts.isEmpty {
                    emptyState
                } else {
                    conflictList
                }
            }
            .navigationTitle("Sync Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
            .sheet(item: $selectedConflict) { conflict in
                ConflictResolutionView(conflict: conflict) { resolution in
                    onResolve(conflict, resolution)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.statusGood)

            Text("No Conflicts")
                .font(.brutalistTitle)
                .foregroundStyle(Theme.textPrimary)

            Text("All your data is in sync")
                .font(.brutalistSecondary)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var conflictList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("\(conflicts.count) conflict\(conflicts.count == 1 ? "" : "s") need\(conflicts.count == 1 ? "s" : "") your attention")
                    .font(.brutalistSecondary)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, Spacing.screenHorizontal)

                ForEach(conflicts) { conflict in
                    conflictRow(conflict)
                }
            }
            .padding(.top, Spacing.md)
        }
    }

    private func conflictRow(_ conflict: SyncConflict) -> some View {
        Button {
            selectedConflict = conflict
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(conflict.entityName)
                        .font(.brutalistBody)
                        .foregroundStyle(Theme.textPrimary)

                    Text("\(conflict.entityType.rawValue) • \(conflict.fieldName)")
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.screenHorizontal)
    }
}

#Preview("Single Conflict") {
    ConflictResolutionView(
        conflict: SyncConflict(
            entityType: .vehicle,
            entityName: "2022 Toyota Camry",
            localValue: "52,847 miles",
            remoteValue: "52,650 miles",
            localModifiedAt: Date(),
            remoteModifiedAt: Date().addingTimeInterval(-3600),
            fieldName: "Current Mileage"
        )
    ) { resolution in
        print("Resolved with: \(resolution)")
    }
    .preferredColorScheme(.dark)
}

#Preview("Conflict List") {
    ConflictListView(
        conflicts: [
            SyncConflict(
                entityType: .vehicle,
                entityName: "2022 Toyota Camry",
                localValue: "52,847 miles",
                remoteValue: "52,650 miles",
                localModifiedAt: Date(),
                remoteModifiedAt: Date().addingTimeInterval(-3600),
                fieldName: "Current Mileage"
            ),
            SyncConflict(
                entityType: .service,
                entityName: "Oil Change",
                localValue: "Due at 55,000 miles",
                remoteValue: "Due at 54,500 miles",
                localModifiedAt: Date(),
                remoteModifiedAt: Date().addingTimeInterval(-7200),
                fieldName: "Due Mileage"
            )
        ]
    ) { conflict, resolution in
        print("Resolved \(conflict.entityName) with: \(resolution)")
    }
    .preferredColorScheme(.dark)
}

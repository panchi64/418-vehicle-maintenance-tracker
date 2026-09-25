//
//  VehiclePickerSheet.swift
//  checkpoint
//
//  Sheet for selecting between vehicles with instrument cluster aesthetic
//

import SwiftUI
import SwiftData
import WidgetKit

struct VehiclePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]

    @Binding var selectedVehicle: Vehicle?

    /// Requests Add Vehicle. The presenter must act on it only after this sheet
    /// has dismissed (in its `onDismiss`): presenting a second sheet in the same
    /// tick as dismissing this one can silently drop it.
    let onAddVehicle: () -> Void

    // Delete is confirmed, not undone. The Undo toast renders at the app root,
    // beneath this sheet, so it could not be seen — and it restored only the
    // vehicle row, not the services and history the cascade had deleted.
    @State private var vehicleToDelete: Vehicle?
    @State private var showDeleteConfirmation = false

    // State for editing
    @State private var vehicleToEdit: Vehicle?

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        // Vehicles list
                        VStack(spacing: 0) {
                            ForEach(vehicles) { vehicle in
                                vehicleRow(vehicle)
                                    .contextMenu {
                                        Button {
                                            vehicleToEdit = vehicle
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }

                                        Button(role: .destructive) {
                                            vehicleToDelete = vehicle
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }

                                if vehicle.id != vehicles.last?.id {
                                    Rectangle()
                                        .fill(Theme.gridLine)
                                        .frame(height: 1)
                                        .padding(.leading, Spacing.md)
                                }
                            }
                        }
                        .background(Theme.surfaceInstrument)
                        .clipShape(Rectangle())
                        .overlay(
                            Rectangle()
                                .strokeBorder(Theme.gridLine, lineWidth: 1)
                        )

                        // Add vehicle button
                        Button {
                            onAddVehicle()
                            dismiss()
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.accent)

                                Text(L10n.vehicleAdd)
                                    .font(.brutalistBody)
                                    .foregroundStyle(Theme.accent)

                                Spacer()
                            }
                            .padding(Spacing.md)
                            .background(Theme.surfaceInstrument)
                            .clipShape(Rectangle())
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Theme.accent.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.instrument)
                        .accessibilityLabel("Add new vehicle")
                    }
                    .padding(Spacing.screenHorizontal)
                    .padding(.top, Spacing.md)
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.surfaceInstrument, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .toolbarButtonStyle()
                }
            }
        }
        .trackScreen(.vehiclePicker)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .applyGlassBackground()
        .alert(L10n.vehicleDeleteConfirmTitle, isPresented: $showDeleteConfirmation, presenting: vehicleToDelete) { vehicle in
            Button(L10n.commonCancel, role: .cancel) {
                vehicleToDelete = nil
            }
            Button(L10n.commonDelete, role: .destructive) {
                deleteVehicle(vehicle)
            }
        } message: { _ in
            Text(vehicles.count == 1 ? L10n.vehicleDeleteConfirmMessageLast : L10n.vehicleDeleteConfirmMessage)
        }
        .sheet(item: $vehicleToEdit) { vehicle in
            EditVehicleView(vehicle: vehicle)
        }
    }

    // MARK: - Delete Vehicle

    private func deleteVehicle(_ vehicle: Vehicle) {
        HapticService.shared.warning()
        AnalyticsService.shared.capture(.vehicleDeleted)

        let vehicleID = vehicle.id.uuidString
        let isSelectedVehicle = selectedVehicle?.id == vehicle.id

        // Cancel every notification tied to this vehicle
        NotificationService.shared.cancelAllNotifications(for: vehicle)

        // Remove widget data for this vehicle
        WidgetDataService.shared.removeWidgetData(for: vehicleID)

        // Delete the vehicle from SwiftData (cascade deletes services, logs, snapshots)
        modelContext.delete(vehicle)
        // Sweep documents linked only to this vehicle with no service log —
        // Vehicle.documents uses .nullify so they'd otherwise be orphaned.
        Document.purgeOrphans(in: modelContext)

        // Clear selection if the deleted vehicle was selected
        // ContentView's onChange(of: vehicles) will handle setting a new selection
        if isSelectedVehicle {
            selectedVehicle = nil
        }

        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()

        vehicleToDelete = nil
    }

    private func vehicleRow(_ vehicle: Vehicle) -> some View {
        Button {
            selectedVehicle = vehicle
            dismiss()
        } label: {
            HStack(spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.displayName.uppercased())
                        .font(.custom("Barlow-SemiBold", size: 16))
                        .foregroundStyle(Theme.textPrimary)
                        .tracking(0.5)

                    Text(vehicle.identityLine)
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                if selectedVehicle?.id == vehicle.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                }

                // Options menu button
                Menu {
                    Button {
                        vehicleToEdit = vehicle
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        vehicleToDelete = vehicle
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Vehicle options")
            }
            .padding(Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(ServiceRowButtonStyle())
        .accessibilityLabel(vehicle.displayName)
        .accessibilityHint(selectedVehicle?.id == vehicle.id ? "Currently selected" : "Double tap to select")
    }
}

// MARK: - Glass Background Modifier (iOS 26+)

extension View {
    @ViewBuilder
    func applyGlassBackground() -> some View {
        if #available(iOS 26, *) {
            self.presentationBackground(.regularMaterial)
        } else {
            self
        }
    }
}

#Preview {
    @Previewable @State var selected: Vehicle? = nil

    VehiclePickerSheet(
        selectedVehicle: $selected,
        onAddVehicle: { print("Add vehicle") }
    )
    .modelContainer(for: Vehicle.self, inMemory: true)
}

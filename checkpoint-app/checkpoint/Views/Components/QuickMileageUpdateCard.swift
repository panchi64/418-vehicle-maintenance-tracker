//
//  QuickMileageUpdateCard.swift
//  checkpoint
//
//  Large odometer display with UPDATE button and last updated tracking
//

import SwiftUI

struct QuickMileageUpdateCard: View {
    let vehicle: Vehicle
    let onUpdate: (Int) -> Void

    @State private var showMileageSheet = false

    private var formattedMileage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: vehicle.currentMileage)) ?? "\(vehicle.currentMileage)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            InstrumentSectionHeader(title: "Odometer")

            HStack(alignment: .center) {
                // Mileage display
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formattedMileage)
                            .font(.brutalistTitle)
                            .foregroundStyle(Theme.accent)

                        Text("MI")
                            .font(.brutalistLabel)
                            .foregroundStyle(Theme.textTertiary)
                            .tracking(1)
                    }

                    Text(vehicle.mileageUpdateDescription)
                        .font(.brutalistSecondary)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                // Update button
                Button {
                    showMileageSheet = true
                } label: {
                    Text("UPDATE")
                        .font(.brutalistLabel)
                        .foregroundStyle(Theme.surfaceInstrument)
                        .tracking(1.5)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(Theme.accent)
                }
            }
            .padding(Spacing.md)
            .background(Theme.surfaceInstrument)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
            )
        }
        .sheet(isPresented: $showMileageSheet) {
            MileageUpdateSheet(
                currentMileage: vehicle.currentMileage,
                onSave: { newMileage in
                    onUpdate(newMileage)
                }
            )
            .presentationDetents([.height(280)])
        }
    }
}

// MARK: - Mileage Update Sheet

struct MileageUpdateSheet: View {
    @Environment(\.dismiss) private var dismiss

    let currentMileage: Int
    let onSave: (Int) -> Void

    @State private var newMileage: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    InstrumentNumberField(
                        label: "Current Mileage",
                        value: $newMileage,
                        placeholder: "\(currentMileage)",
                        suffix: "mi"
                    )

                    Button("Save") {
                        if let mileage = newMileage, mileage > 0 {
                            onSave(mileage)
                            dismiss()
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(newMileage == nil || newMileage! <= 0)

                    Spacer()
                }
                .padding(Spacing.screenHorizontal)
                .padding(.top, Spacing.lg)
            }
            .navigationTitle("Update Mileage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .onAppear {
            newMileage = currentMileage
        }
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            QuickMileageUpdateCard(
                vehicle: Vehicle(
                    name: "Daily Driver",
                    make: "Toyota",
                    model: "Camry",
                    year: 2022,
                    currentMileage: 32500,
                    mileageUpdatedAt: Calendar.current.date(byAdding: .day, value: -3, to: .now)
                )
            ) { newMileage in
                print("Updated to \(newMileage)")
            }

            QuickMileageUpdateCard(
                vehicle: Vehicle(
                    name: "New Car",
                    make: "Honda",
                    model: "Civic",
                    year: 2024,
                    currentMileage: 1500
                )
            ) { newMileage in
                print("Updated to \(newMileage)")
            }
        }
        .padding(Spacing.screenHorizontal)
    }
    .preferredColorScheme(.dark)
}

//
//  VehiclePhotoView.swift
//  checkpoint
//
//  Displays vehicle photo or placeholder with consistent styling
//

import SwiftUI

struct VehiclePhotoView: View {
    let vehicle: Vehicle?
    var size: PhotoSize = .medium
    var showEditIndicator: Bool = false

    enum PhotoSize {
        case small   // 40pt - for lists and compact displays
        case medium  // 60pt - for headers
        case large   // 100pt - for detail views and forms

        var dimension: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 60
            case .large: return 100
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 36
            }
        }
    }

    var body: some View {
        ZStack {
            if let photo = vehicle?.photo {
                photo
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.dimension, height: size.dimension)
                    .clipped()
            } else {
                // Placeholder
                Rectangle()
                    .fill(Theme.surfaceInstrument)

                Image(systemName: "car.side.fill")
                    .font(.system(size: size.iconSize, weight: .medium))
                    .foregroundStyle(Theme.accent.opacity(0.6))
            }

            // Edit indicator overlay
            if showEditIndicator {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "camera.fill")
                            .font(.system(size: size == .large ? 14 : 10, weight: .medium))
                            .foregroundStyle(Theme.surfaceInstrument)
                            .padding(size == .large ? 6 : 4)
                            .background(Theme.accent)
                    }
                }
            }
        }
        .frame(width: size.dimension, height: size.dimension)
        .overlay(
            Rectangle()
                .strokeBorder(Theme.gridLine, lineWidth: Theme.borderWidth)
        )
    }
}

#Preview {
    ZStack {
        AtmosphericBackground()

        VStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.lg) {
                VehiclePhotoView(vehicle: nil, size: .small)
                VehiclePhotoView(vehicle: nil, size: .medium)
                VehiclePhotoView(vehicle: nil, size: .large)
            }

            HStack(spacing: Spacing.lg) {
                VehiclePhotoView(vehicle: nil, size: .small, showEditIndicator: true)
                VehiclePhotoView(vehicle: nil, size: .medium, showEditIndicator: true)
                VehiclePhotoView(vehicle: nil, size: .large, showEditIndicator: true)
            }
        }
    }
    .preferredColorScheme(.dark)
}

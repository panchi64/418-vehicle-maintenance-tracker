import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import CoreLocation
import DesignKit
import Localization

@MainActor
@Observable
final class SubmitPriceModel {
    enum Stage: Equatable {
        case selectingImage
        case processing
        case review
        case submitting
        case submitted
        case failed(String)
    }

    var stage: Stage = .selectingImage
    var selectedImage: UIImage?
    var compressedImageData: Data?
    var ocrRawText: String = ""
    var detectedBrand: String?
    var stationName: String = ""
    var regularPrice: Double?
    var premiumPrice: Double?
    var dieselPrice: Double?
}

struct SubmitPriceSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var model = SubmitPriceModel()
    @State private var photoPickerItem: PhotosPickerItem?
    private let locationService = LocationService.shared

    var body: some View {
        NavigationStack {
            VStack {
                switch model.stage {
                case .selectingImage: imagePicker
                case .processing: processing
                case .review: reviewForm
                case .submitting: submittingOverlay
                case .submitted: submittedState
                case .failed(let message): failureState(message: message)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle(Text("submit.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Shared.Action.cancel) { dismiss() }
                }
                if model.stage == .review {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("submit.action.send") { Task { await submit() } }
                            .disabled(!hasAnyPrice)
                    }
                }
            }
            .onChange(of: photoPickerItem) { _, item in
                guard let item else { return }
                Task { await loadImage(from: item) }
            }
        }
    }

    private var hasAnyPrice: Bool {
        model.regularPrice != nil || model.premiumPrice != nil || model.dieselPrice != nil
    }

    private var imagePicker: some View {
        VStack(spacing: DKSpacing.lg) {
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(theme.textSecondary)

            Text("submit.select_photo.title")
                .font(theme.font(.title3, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .textCase(.uppercase)
                .tracking(2)

            Text("submit.select_photo.body")
                .font(theme.font(.body))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DKSpacing.lg)

            Spacer()

            PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                Label("submit.pick_photo", systemImage: "photo.on.rectangle")
                    .font(theme.font(.body, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundStyle(theme.backgroundPrimary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(theme.accent)
            }
            .padding(.horizontal, DKSpacing.lg)
            .padding(.bottom, DKSpacing.xl)
        }
    }

    private var processing: some View {
        VStack(spacing: DKSpacing.md) {
            ProgressView()
                .tint(theme.accent)
            Text("submit.processing")
                .font(theme.font(.caption, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
        }
    }

    private var reviewForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DKSpacing.lg) {
                if let image = model.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .brutalistBorder(color: theme.borderSubtle, lineWidth: 2)
                }

                DesignKit.SectionHeader(
                    title: String(localized: "submit.review.station"),
                    labelColor: theme.textTertiary,
                    dividerColor: theme.gridLine,
                    dividerHeight: 2,
                    labelFont: theme.font(.caption, weight: .semibold)
                )

                TextField("submit.station_name_placeholder", text: $model.stationName)
                    .textFieldStyle(.roundedBorder)

                DataRow(
                    label: String(localized: "submit.detected_brand"),
                    value: model.detectedBrand ?? "—",
                    labelColor: theme.textTertiary,
                    valueColor: theme.textPrimary,
                    labelFont: theme.font(.caption, weight: .semibold),
                    valueFont: theme.font(.body, weight: .bold)
                )

                DesignKit.SectionHeader(
                    title: String(localized: "submit.review.prices"),
                    labelColor: theme.textTertiary,
                    dividerColor: theme.gridLine,
                    dividerHeight: 2,
                    labelFont: theme.font(.caption, weight: .semibold)
                )

                priceField(label: L10n.Shared.FuelGrade.regular, binding: $model.regularPrice)
                priceField(label: L10n.Shared.FuelGrade.premium, binding: $model.premiumPrice)
                priceField(label: L10n.Shared.FuelGrade.diesel, binding: $model.dieselPrice)
            }
            .padding(DKSpacing.md)
        }
    }

    private func priceField(label: String, binding: Binding<Double?>) -> some View {
        HStack {
            Text(label)
                .font(theme.font(.caption, weight: .semibold))
                .foregroundStyle(theme.textTertiary)
                .textCase(.uppercase)
                .tracking(1.5)
            Spacer()
            TextField("0.00",
                      value: binding,
                      format: .number.precision(.fractionLength(2)))
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(maxWidth: 100)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var submittingOverlay: some View {
        VStack(spacing: DKSpacing.md) {
            ProgressView().tint(theme.accent)
            Text("submit.uploading")
                .font(theme.font(.caption, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)
        }
    }

    private var submittedState: some View {
        VStack(spacing: DKSpacing.md) {
            Image(systemName: "checkmark.rectangle.fill")
                .font(.system(size: 72))
                .foregroundStyle(theme.accent)
            Text("submit.success")
                .font(theme.font(.title3, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .textCase(.uppercase)
                .tracking(2)
            Button(L10n.Shared.Action.done) { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
        }
        .padding(DKSpacing.md)
    }

    private func failureState(message: String) -> some View {
        VStack(spacing: DKSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(theme.accent)
            Text("submit.failed")
                .font(theme.font(.title3, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .textCase(.uppercase)
                .tracking(1.5)
            Text(message)
                .font(theme.font(.caption))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DKSpacing.lg)
            Button("submit.retry") {
                model.stage = .review
            }
            .buttonStyle(.bordered)
            .tint(theme.accent)
        }
    }

    private func loadImage(from item: PhotosPickerItem) async {
        model.stage = .processing
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            model.stage = .failed(String(localized: "submit.error.image_load"))
            return
        }
        model.selectedImage = image

        async let compressed = ImageCompressionService.compress(image)
        async let ocr = Self.runOCR(on: image)

        do {
            let (ocrResult, compressedData) = try await (ocr, compressed)
            model.compressedImageData = compressedData
            model.ocrRawText = ocrResult.rawText
            model.regularPrice = ocrResult.candidates.first?.value
            model.detectedBrand = BrandDetectionService.detect(
                in: ocrResult.rawText,
                context: modelContext
            )?.brand
            model.stage = .review
        } catch {
            model.stage = .failed(error.localizedDescription)
        }
    }

    private static func runOCR(on image: UIImage) async throws -> FuelOCRResult {
        try await FuelOCRService.shared.extract(from: image)
    }

    private func submit() async {
        guard let imageData = model.compressedImageData else {
            model.stage = .failed(String(localized: "submit.error.no_image"))
            return
        }

        guard let coordinate = locationService.currentLocation?.coordinate else {
            model.stage = .failed(String(localized: "submit.error.no_location"))
            return
        }

        model.stage = .submitting

        let deviceToken = await DeviceTokenService.shared.token()
        let request = SubmissionRequest(
            deviceToken: deviceToken,
            detectedBrand: model.detectedBrand,
            stationName: model.stationName.isEmpty ? nil : model.stationName,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            parsedRegular: model.regularPrice,
            parsedPremium: model.premiumPrice,
            parsedDiesel: model.dieselPrice,
            ocrText: model.ocrRawText.isEmpty ? nil : model.ocrRawText
        )

        do {
            _ = try await BiomboAPIService.shared.submitPrice(request, imageData: imageData)
            model.stage = .submitted
        } catch {
            model.stage = .failed(error.localizedDescription)
        }
    }
}

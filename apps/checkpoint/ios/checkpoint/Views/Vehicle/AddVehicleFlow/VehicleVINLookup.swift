//
//  VehicleVINLookup.swift
//  checkpoint
//
//  The NHTSA decode behind both vehicle forms. It runs by itself once a VIN
//  reaches 17 valid characters (debounced, so a pasted or scanned VIN decodes
//  once and a typed one isn't looked up mid-keystroke); the button stays for
//  a deliberate retry after a failure.
//
//  The network call lives here, in the view layer; `VehicleFormState` only
//  records what the lookup did.
//

import SwiftUI

enum VehicleVINLookup {
    /// Pause after the last keystroke before looking a complete VIN up.
    static let debounce: Duration = .milliseconds(600)

    static func run(_ formState: VehicleFormState) async {
        let vin = formState.vin
        formState.beginVINLookup()
        do {
            let result = try await NHTSAService.shared.decodeVIN(vin)
            // The user edited the VIN while this was in flight: the answer is
            // for a VIN that is no longer in the field.
            guard formState.vin == vin else { return formState.abandonVINLookup() }
            formState.applyVINLookup(result, for: vin)
            HapticService.shared.success()
        } catch {
            guard formState.vin == vin, !Task.isCancelled else { return formState.abandonVINLookup() }
            formState.failVINLookup(error.localizedDescription, for: vin)
        }
    }
}

extension View {
    /// Decode the VIN once it becomes a complete, valid one the form hasn't
    /// seen. Re-keyed on every edit, so typing cancels the pending lookup.
    func autoDecodesVIN(_ formState: VehicleFormState) -> some View {
        task(id: formState.vin) {
            guard formState.shouldAutoDecodeVIN else { return }
            try? await Task.sleep(for: VehicleVINLookup.debounce)
            guard !Task.isCancelled, formState.shouldAutoDecodeVIN else { return }
            await VehicleVINLookup.run(formState)
        }
    }
}

/// Manual lookup — shown while a valid VIN hasn't produced a result, so a
/// failed or offline auto-decode can be retried.
struct VINLookupButton: View {
    @Bindable var formState: VehicleFormState

    var body: some View {
        Button {
            Task { await VehicleVINLookup.run(formState) }
        } label: {
            HStack(spacing: Spacing.sm) {
                if formState.isDecodingVIN {
                    ProgressView()
                        .tint(Theme.surfaceInstrument)
                }
                Text(formState.isDecodingVIN ? L10n.addVehicleVINLookupLoading : L10n.addVehicleVINLookup)
            }
        }
        .buttonStyle(.secondary)
        .disabled(formState.isDecodingVIN)
    }
}

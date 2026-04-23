import SwiftUI
import DesignKit
import Localization

struct SubmitPriceSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: DKSpacing.lg) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(theme.textSecondary)

                Text("submit.placeholder_title")
                    .font(theme.font(.title3, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                    .textCase(.uppercase)
                    .tracking(2)
                    .multilineTextAlignment(.center)

                Text("submit.placeholder_body")
                    .font(theme.font(.body))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DKSpacing.lg)
            }
            .padding(DKSpacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle(Text("submit.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Shared.Action.cancel) { dismiss() }
                }
            }
        }
    }
}

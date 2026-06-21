import SwiftUI

struct PlatterAIView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(PlatterColors.brandOrangeLight)
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(PlatterColors.brandOrange)
            }

            VStack(spacing: 8) {
                Text("Platter AI")
                    .font(PlatterFont.title(26))
                    .foregroundStyle(PlatterColors.textPrimary)
                Text("Scan a menu first, then Bro will help you order smart.")
                    .font(PlatterFont.body(15))
                    .foregroundStyle(PlatterColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            PlatterPrimaryButton(title: "Scan a Menu", icon: "viewfinder") {
                appState.openScanFlow()
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PlatterColors.background)
    }
}

#Preview {
    PlatterAIView()
        .environment(AppState())
}

import SwiftUI
import PhotosUI

struct ScanMenuView: View {
    @Environment(ScanSessionStore.self) private var session
    @Environment(AppState.self) private var appState

    let onContinue: () -> Void

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false

    private var hasVerifiedMenu: Bool {
        session.menu?.source == .verified
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    FlowBackButton {
                        appState.selectedTab = .discover
                    }
                    Spacer()
                }

                FlowStepperView(currentStep: .scan)

                tipBox

                if let menu = session.menu, menu.source == .verified, let name = menu.restaurantName {
                    verifiedMenuBanner(restaurantName: name)
                }

                VStack(spacing: 12) {
                    if hasVerifiedMenu {
                        PlatterPrimaryButton(
                            title: "Continue to Preferences",
                            icon: "arrow.right",
                            isLoading: session.isLoading
                        ) {
                            onContinue()
                        }
                    }

                    PlatterPrimaryButton(
                        title: hasVerifiedMenu ? "Scan Menu Anyway" : "Capture Menu",
                        icon: "camera.fill",
                        isLoading: session.isLoading
                    ) {
                        showCamera = true
                    }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle")
                            Text("Upload from Photos")
                                .font(PlatterFont.headline(17))
                        }
                        .foregroundStyle(PlatterColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(PlatterColors.cardWhite)
                        .overlay {
                            Capsule()
                                .stroke(PlatterColors.chipBorder, lineWidth: 1)
                        }
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(PlatterColors.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCamera) {
            CameraCaptureView { image in
                Task {
                    let data = image.jpegDataForUpload()
                    await session.parseMenu(imageData: data, from: .camera)
                    if session.menu != nil, session.errorMessage == nil {
                        onContinue()
                    }
                }
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await session.parseMenu(imageData: data, from: .photo)
                } else {
                    await session.parseMenu(imageData: nil, from: .photo)
                }
                if session.menu != nil, session.errorMessage == nil {
                    onContinue()
                }
            }
        }
    }

    private var tipBox: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(PlatterColors.brandOrange)
            Text("Platter AI reads prices & items automatically.")
                .font(PlatterFont.body(13))
                .foregroundStyle(PlatterColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlatterColors.brandOrangeLight)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(PlatterColors.brandOrange.opacity(0.25), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func verifiedMenuBanner(restaurantName: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(PlatterColors.brandOrange)
            Text("Verified menu loaded for \(restaurantName)")
                .font(PlatterFont.body(13))
                .foregroundStyle(PlatterColors.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlatterColors.brandOrangeLight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ScanMenuView(onContinue: {})
        .environment(ScanSessionStore())
        .environment(AppState())
}

import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var session = ScanSessionStore()

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 0) {
            ZStack {
                DiscoverView()
                    .opacity(appState.selectedTab == .discover ? 1 : 0)
                    .allowsHitTesting(appState.selectedTab == .discover)

                ScanFlowView()
                    .opacity(appState.selectedTab == .scan ? 1 : 0)
                    .allowsHitTesting(appState.selectedTab == .scan)

                SavedView()
                    .opacity(appState.selectedTab == .saved ? 1 : 0)
                    .allowsHitTesting(appState.selectedTab == .saved)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if appState.selectedTab != .scan {
                PlatterTabBar(selectedTab: $appState.selectedTab)
            }
        }
        .background(PlatterColors.background)
        .environment(session)
        .onChange(of: appState.pendingRestaurant) { _, name in
            if let name {
                session.startWithRestaurant(name)
                appState.pendingRestaurant = nil
            }
        }
    }
}

struct PlatterTabBar: View {
    @Binding var selectedTab: PlatterTab

    var body: some View {
        HStack(alignment: .bottom) {
            sideTab(.discover)
            scanTab
            sideTab(.saved)
        }
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background(PlatterColors.cardWhite)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func sideTab(_ tab: PlatterTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? PlatterColors.brandOrange : PlatterColors.textSecondary)
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? PlatterColors.brandOrange : PlatterColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var scanTab: some View {
        let isSelected = selectedTab == .scan
        return Button {
            selectedTab = .scan
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(PlatterColors.brandOrange)
                        .frame(width: 44, height: 44)
                    Image(systemName: "viewfinder")
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(.white)
                }
                .offset(y: -10)

                Text("Scan Menu")
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? PlatterColors.brandOrange : PlatterColors.textSecondary)
                    .offset(y: -10)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44, alignment: .bottom)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
        .environment(DiscoverRecommendationStore())
}

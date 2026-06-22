import SwiftUI

@main
struct platterApp: App {
    @State private var appState = AppState()
    @State private var discoverStore = DiscoverRecommendationStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appState)
                .environment(discoverStore)
                .tint(PlatterColors.brandOrange)
        }
    }
}

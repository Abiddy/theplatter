import SwiftUI

@main
struct platterApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(appState)
                .tint(PlatterColors.brandOrange)
        }
    }
}

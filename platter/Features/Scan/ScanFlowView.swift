import SwiftUI

struct ScanFlowView: View {
    @Environment(ScanSessionStore.self) private var session

    var body: some View {
        @Bindable var session = session

        NavigationStack(path: $session.scanFlowPath) {
            ScanMenuView {
                session.scanFlowPath.append(.preferences)
            }
            .navigationDestination(for: ScanFlowRoute.self) { route in
                switch route {
                case .preferences:
                    PreferencesView {
                        session.scanFlowPath.append(.results)
                    }
                case .results:
                    CombosView(
                        onTweakPreferences: {
                            if let idx = session.scanFlowPath.lastIndex(of: .results) {
                                session.scanFlowPath.remove(at: idx)
                            }
                        },
                        onRegenerate: {
                            Task { await session.generateCombos() }
                        }
                    )
                }
            }
        }
    }
}

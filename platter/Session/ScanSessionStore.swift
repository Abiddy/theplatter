import Foundation
import Observation

@Observable
final class ScanSessionStore {
    var restaurantName: String?
    var menu: Menu?
    var constraints = Constraints()
    var combos: [Combo] = []
    var aiSummary = ""
    var constraintTags: [String] = []
    var isLoading = false
    var errorMessage: String?
    var scanFlowPath: [ScanFlowRoute] = []

    func reset() {
        restaurantName = nil
        menu = nil
        constraints = Constraints()
        combos = []
        aiSummary = ""
        constraintTags = []
        isLoading = false
        errorMessage = nil
        scanFlowPath = []
    }

    func startWithRestaurant(_ name: String, jumpTo route: ScanFlowRoute = .preferences) {
        reset()
        restaurantName = name
        menu = MockDataService.menu(for: name)
        scanFlowPath = [route]
    }

    @MainActor
    func parseMenu(imageData: Data?, from source: MenuSource) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        if PlatterAPIConfig.useBackend, let imageData {
            do {
                let response = try await PlatterAPIService.parseMenu(
                    imageData: imageData,
                    source: source,
                    restaurantName: restaurantName
                )
                menu = response.menu
                menu?.source = source
                menu?.scannedAt = Date()
                return
            } catch {
                if !PlatterAPIConfig.fallbackToLocalOnError {
                    errorMessage = error.localizedDescription
                    return
                }
            }
        }

        menu = MockDataService.menu(for: restaurantName ?? "Scanned Restaurant")
        menu?.source = source
        menu?.scannedAt = Date()
    }

    @MainActor
    func generateCombos() async {
        guard let menu else {
            errorMessage = "No menu found. Please scan again."
            return
        }

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        if PlatterAPIConfig.useBackend {
            do {
                let response = try await PlatterAPIService.generateCombos(menu: menu, constraints: constraints)
                combos = response.combos
                aiSummary = response.aiSummary
                constraintTags = response.constraintTags
                return
            } catch {
                if !PlatterAPIConfig.fallbackToLocalOnError {
                    errorMessage = error.localizedDescription
                    return
                }
                // Fall through to on-device optimizer.
            }
        }

        let result = ComboOptimizer.generate(menu: menu, constraints: constraints)
        combos = result.combos
        aiSummary = result.aiSummary
        constraintTags = result.constraintTags

        if combos.isEmpty {
            errorMessage = "No combos matched your preferences. Try loosening dietary filters or raising your budget."
        }
    }
}

enum ScanFlowRoute: Hashable {
    case preferences
    case results
}

@Observable
final class AppState {
    var selectedTab: PlatterTab = .discover
    var scanFlowActive = false
    var pendingRestaurant: String?

    func openScanFlow(restaurantName: String? = nil) {
        pendingRestaurant = restaurantName
        selectedTab = .scan
        scanFlowActive = true
    }
}

enum PlatterTab: Int, CaseIterable, Identifiable {
    case discover
    case scan
    case saved

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .discover: "Discover"
        case .scan: "Scan Menu"
        case .saved: "Saved"
        }
    }

    var icon: String {
        switch self {
        case .discover: "safari"
        case .scan: "viewfinder"
        case .saved: "heart"
        }
    }
}

import SwiftUI

struct SavedView: View {
    @Environment(DiscoverRecommendationStore.self) private var discoverStore
    @State private var selectedRestaurant: RestaurantRoute?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Saved")
                        .font(PlatterFont.title(28))
                        .foregroundStyle(PlatterColors.textPrimary)
                        .padding(.top, 8)

                    Text("Orders you've hearted")
                        .font(PlatterFont.body(14))
                        .foregroundStyle(PlatterColors.textSecondary)

                    if discoverStore.savedRecommendations.isEmpty {
                        emptyState
                    } else {
                        ForEach(discoverStore.savedRecommendations) { rec in
                            RecommendationCard(
                                recommendation: rec,
                                heartCount: discoverStore.heartCount(for: rec),
                                isHearted: true,
                                onHeart: { discoverStore.toggleHeart(for: rec) },
                                onFullMenu: { selectedRestaurant = RestaurantRoute(name: rec.restaurantName) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .background(PlatterColors.background)
            .navigationDestination(item: $selectedRestaurant) { route in
                RestaurantDetailView(restaurantName: route.name)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 40))
                .foregroundStyle(PlatterColors.textSecondary.opacity(0.4))
            Text("No saved orders yet")
                .font(PlatterFont.headline(16))
                .foregroundStyle(PlatterColors.textSecondary)
            Text("Heart a recommendation on Discover to save it here.")
                .font(PlatterFont.body(14))
                .foregroundStyle(PlatterColors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct SavedCombo: Identifiable, Codable {
    var id: UUID
    var recommendationID: UUID?
    var restaurantName: String
    var combo: Combo
    var savedAt: Date
}

enum SavedComboStore {
    private static let key = "platter.savedCombos"

    static func load() -> [SavedCombo] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let combos = try? JSONDecoder().decode([SavedCombo].self, from: data) else {
            return []
        }
        return combos
    }

    static func save(_ combo: Combo, restaurantName: String, recommendationID: UUID? = nil) {
        var existing = load()
        if let recommendationID,
           let index = existing.firstIndex(where: { $0.recommendationID == recommendationID }) {
            existing[index] = SavedCombo(
                id: existing[index].id,
                recommendationID: recommendationID,
                restaurantName: restaurantName,
                combo: combo,
                savedAt: Date()
            )
        } else {
            existing.insert(
                SavedCombo(
                    id: UUID(),
                    recommendationID: recommendationID,
                    restaurantName: restaurantName,
                    combo: combo,
                    savedAt: Date()
                ),
                at: 0
            )
        }
        persist(existing)
    }

    static func remove(recommendationID: UUID) {
        var existing = load()
        existing.removeAll { $0.recommendationID == recommendationID }
        persist(existing)
    }

    private static func persist(_ combos: [SavedCombo]) {
        if let data = try? JSONEncoder().encode(combos) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

#Preview {
    SavedView()
        .environment(DiscoverRecommendationStore())
}
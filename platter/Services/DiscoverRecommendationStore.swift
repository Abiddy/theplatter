import Foundation
import Observation

@Observable
final class DiscoverRecommendationStore {
    private(set) var recommendations: [DiscoverRecommendation]
    private var heartedIDs: Set<UUID> = []

    private static let heartedKey = "platter.heartedRecommendations"

    init(recommendations: [DiscoverRecommendation] = RecommendationSeed.load()) {
        self.recommendations = recommendations
        loadHearted()
    }

    func isHearted(_ id: UUID) -> Bool {
        heartedIDs.contains(id)
    }

    func heartCount(for recommendation: DiscoverRecommendation) -> Int {
        recommendation.baseHeartCount + (heartedIDs.contains(recommendation.id) ? 1 : 0)
    }

    func toggleHeart(for recommendation: DiscoverRecommendation) {
        if heartedIDs.contains(recommendation.id) {
            heartedIDs.remove(recommendation.id)
            SavedComboStore.remove(recommendationID: recommendation.id)
        } else {
            heartedIDs.insert(recommendation.id)
            SavedComboStore.save(
                recommendation.combo,
                restaurantName: recommendation.restaurantName,
                recommendationID: recommendation.id
            )
        }
        persistHearted()
    }

    func sorted(_ sort: DiscoverSort, filtered: [DiscoverRecommendation]) -> [DiscoverRecommendation] {
        switch sort {
        case .trending:
            filtered.sorted { heartCount(for: $0) > heartCount(for: $1) }
        case .nearby:
            filtered.sorted { $0.distanceMiles < $1.distanceMiles }
        case .newest:
            filtered.sorted { $0.baseHeartCount < $1.baseHeartCount }
        }
    }

    var savedRecommendations: [DiscoverRecommendation] {
        recommendations.filter { heartedIDs.contains($0.id) }
    }

    func recommendations(forRestaurant name: String) -> [DiscoverRecommendation] {
        recommendations
            .filter { $0.restaurantName == name }
            .sorted { heartCount(for: $0) > heartCount(for: $1) }
    }

    private func loadHearted() {
        guard let data = UserDefaults.standard.data(forKey: Self.heartedKey),
              let ids = try? JSONDecoder().decode([UUID].self, from: data) else {
            return
        }
        heartedIDs = Set(ids)
    }

    private func persistHearted() {
        if let data = try? JSONEncoder().encode(Array(heartedIDs)) {
            UserDefaults.standard.set(data, forKey: Self.heartedKey)
        }
    }
}

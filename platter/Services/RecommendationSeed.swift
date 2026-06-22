import Foundation

/// Loads auto-generated Discover cards bundled from `backend/seed/generate_cards.py`.
/// Falls back to in-code mock data if the seed file is missing or invalid.
enum RecommendationSeed {
    static func load() -> [DiscoverRecommendation] {
        guard
            let url = Bundle.main.url(forResource: "discover_recommendations", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            return MockDataService.discoverRecommendations
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard
            let cards = try? decoder.decode([DiscoverRecommendation].self, from: data),
            !cards.isEmpty
        else {
            return MockDataService.discoverRecommendations
        }

        return cards
    }
}

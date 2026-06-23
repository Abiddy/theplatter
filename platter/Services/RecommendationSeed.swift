import Foundation

/// Loads Discover cards. Order of precedence at runtime:
/// 1. Live API (`/v1/discover/recommendations`) managed via the `/recs` portal.
/// 2. Bundled `discover_recommendations.json` (offline fallback / instant first paint).
/// 3. In-code mock data (last resort).
enum RecommendationSeed {
    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    /// Synchronous bundled load for instant first paint.
    static func load() -> [DiscoverRecommendation] {
        guard
            let url = Bundle.main.url(forResource: "discover_recommendations", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let cards = try? decoder.decode([DiscoverRecommendation].self, from: data),
            !cards.isEmpty
        else {
            return MockDataService.discoverRecommendations
        }
        return cards
    }

    /// Fetch the latest cards from the backend portal. Returns nil on any failure
    /// so the caller can keep showing bundled data.
    static func fetchRemote() async -> [DiscoverRecommendation]? {
        guard PlatterAPIConfig.useBackend else { return nil }
        let url = PlatterAPIConfig.baseURL.appendingPathComponent("v1/discover/recommendations")
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 12
            let (data, response) = try await URLSession.shared.data(for: request)
            guard
                let http = response as? HTTPURLResponse, http.statusCode == 200,
                let cards = try? decoder.decode([DiscoverRecommendation].self, from: data),
                !cards.isEmpty
            else {
                return nil
            }
            return cards
        } catch {
            return nil
        }
    }
}

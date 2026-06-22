import Foundation

struct DiscoverRecommendation: Identifiable, Equatable, Codable {
    var id: UUID
    var restaurantName: String
    var cuisine: String
    var distanceMiles: Double
    var imageSeed: Int
    var isVerified: Bool
    var combo: Combo
    var partySize: Int
    var budgetCents: Int
    var contextTags: [String]
    var baseHeartCount: Int

    var distanceFormatted: String {
        String(format: "%.1f mi", distanceMiles)
    }

    var budgetFormatted: String {
        String(format: "$%.0f", Double(budgetCents) / 100.0)
    }

    var perPersonFormatted: String {
        guard partySize > 0 else { return budgetFormatted }
        let perPerson = Double(budgetCents) / Double(partySize) / 100.0
        return String(format: "$%.0f/person", perPerson)
    }
}

enum DiscoverSort: String, CaseIterable, Identifiable {
    case trending = "Trending"
    case nearby = "Nearby"
    case newest = "New"

    var id: String { rawValue }
}

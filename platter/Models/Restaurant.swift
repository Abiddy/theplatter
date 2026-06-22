import Foundation

struct Restaurant: Identifiable, Equatable {
    var id: UUID
    var name: String
    var cuisine: String
    var rating: Double
    var reviewCount: Int
    var distanceMiles: Double
    var priceTier: String
    var tags: [String]
    var isVerified: Bool
    var imageSeed: Int
    var section: RestaurantSection

    var distanceFormatted: String {
        String(format: "%.1f mi", distanceMiles)
    }

    var ratingFormatted: String {
        String(format: "%.1f", rating)
    }
}

enum RestaurantSection: String {
    case trending
    case nearby
}

enum CuisineFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case italian = "Italian"
    case japanese = "Japanese"
    case mexican = "Mexican"
    case american = "American"
    case burgers = "Burgers"

    var id: String { rawValue }
}

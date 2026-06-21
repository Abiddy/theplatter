import Foundation

enum MenuSource: String, Codable {
    case camera
    case photo
    case verified
}

enum MenuCourse: String, Codable {
    case appetizer
    case main
    case side
    case dessert
    case drink
    case unknown
}

struct Menu: Codable, Equatable {
    var restaurantName: String?
    var sections: [MenuSection]
    var scannedAt: Date
    var source: MenuSource

    var allItems: [MenuItem] {
        sections.flatMap(\.items)
    }
}

struct MenuSection: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var items: [MenuItem]

    init(id: UUID = UUID(), name: String, items: [MenuItem]) {
        self.id = id
        self.name = name
        self.items = items
    }
}

struct MenuItem: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var description: String?
    var priceCents: Int
    var course: MenuCourse?
    var isShareable: Bool?
    var servesMin: Int?
    var servesMax: Int?
    var tags: [DietaryRule]
    var isVegetarian: Bool
    var containsFish: Bool
    var containsNuts: Bool
    var containsPork: Bool
    var isVegan: Bool
    var isGlutenFree: Bool

    var priceFormatted: String {
        String(format: "$%.2f", Double(priceCents) / 100.0)
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        priceCents: Int,
        course: MenuCourse? = .unknown,
        isShareable: Bool? = false,
        servesMin: Int? = 1,
        servesMax: Int? = 1,
        tags: [DietaryRule] = [],
        isVegetarian: Bool = false,
        containsFish: Bool = false,
        containsNuts: Bool = false,
        containsPork: Bool = false,
        isVegan: Bool = false,
        isGlutenFree: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.priceCents = priceCents
        self.course = course
        self.isShareable = isShareable
        self.servesMin = servesMin
        self.servesMax = servesMax
        self.tags = tags
        self.isVegetarian = isVegetarian
        self.containsFish = containsFish
        self.containsNuts = containsNuts
        self.containsPork = containsPork
        self.isVegan = isVegan
        self.isGlutenFree = isGlutenFree
    }
}

import Foundation

enum MockDataService {
    static let restaurants: [Restaurant] = [
        Restaurant(
            id: UUID(),
            name: "Osteria Bella",
            cuisine: "Italian",
            rating: 4.8,
            reviewCount: 312,
            distanceMiles: 0.4,
            priceTier: "$$",
            tags: ["Pasta", "Wine", "Romantic"],
            isVerified: true,
            imageSeed: 0,
            section: .trending
        ),
        Restaurant(
            id: UUID(),
            name: "Sakura Ramen",
            cuisine: "Japanese",
            rating: 4.6,
            reviewCount: 189,
            distanceMiles: 0.7,
            priceTier: "$$",
            tags: ["Ramen", "Cozy", "Late Night"],
            isVerified: true,
            imageSeed: 1,
            section: .trending
        ),
        Restaurant(
            id: UUID(),
            name: "Casa Verde",
            cuisine: "Mexican",
            rating: 4.5,
            reviewCount: 245,
            distanceMiles: 1.1,
            priceTier: "$",
            tags: ["Tacos", "Margaritas", "Group Friendly"],
            isVerified: false,
            imageSeed: 2,
            section: .nearby
        ),
        Restaurant(
            id: UUID(),
            name: "Harvest & Hole",
            cuisine: "American",
            rating: 4.7,
            reviewCount: 156,
            distanceMiles: 1.3,
            priceTier: "$$$",
            tags: ["Seasonal", "Brunch", "Farm-to-Table"],
            isVerified: true,
            imageSeed: 3,
            section: .nearby
        ),
    ]

    static func osteriaBellaMenu() -> Menu {
        Menu(
            restaurantName: "Osteria Bella",
            sections: [
                MenuSection(name: "Pizza", items: [
                    MenuItem(
                        name: "Margherita Pizza",
                        priceCents: 1800,
                        course: .main,
                        isShareable: true,
                        servesMin: 1,
                        servesMax: 2,
                        isVegetarian: true
                    ),
                ]),
                MenuSection(name: "Pasta & Risotto", items: [
                    MenuItem(
                        name: "Risotto ai Funghi",
                        priceCents: 2400,
                        course: .main,
                        servesMin: 1,
                        servesMax: 1,
                        isVegetarian: true
                    ),
                    MenuItem(
                        name: "Spaghetti alle Vongole",
                        priceCents: 2600,
                        course: .main,
                        servesMin: 1,
                        servesMax: 1,
                        containsFish: true
                    ),
                ]),
                MenuSection(name: "Antipasti", items: [
                    MenuItem(
                        name: "Bruschetta al Pomodoro",
                        priceCents: 900,
                        course: .appetizer,
                        isShareable: true,
                        servesMin: 1,
                        servesMax: 2,
                        isVegetarian: true,
                        isVegan: true
                    ),
                    MenuItem(
                        name: "Burrata e Prosciutto",
                        priceCents: 1600,
                        course: .appetizer,
                        isShareable: true,
                        servesMin: 1,
                        servesMax: 2,
                        containsPork: true
                    ),
                ]),
                MenuSection(name: "Bevande", items: [
                    MenuItem(name: "Acqua Naturale", priceCents: 500, course: .drink),
                    MenuItem(name: "House Red Wine", priceCents: 1200, course: .drink),
                ]),
            ],
            scannedAt: Date(),
            source: .verified
        )
    }

    static func menu(for restaurantName: String) -> Menu {
        var menu = osteriaBellaMenu()
        menu.restaurantName = restaurantName
        return menu
    }
}

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

    static let discoverRecommendations: [DiscoverRecommendation] = [
        DiscoverRecommendation(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111101")!,
            restaurantName: "Casa Verde",
            cuisine: "Mexican",
            distanceMiles: 1.1,
            imageSeed: 2,
            isVerified: false,
            combo: Combo(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222201")!,
                rank: 1,
                isTopPick: true,
                title: "Taco Night for 4",
                subtitle: "Shareable plates · best value",
                lineItems: [
                    lineItem("Street Tacos (3)", qty: 2, price: 1400),
                    lineItem("Guacamole & Chips", qty: 1, price: 1200),
                    lineItem("Horchata Pitcher", qty: 1, price: 900),
                    lineItem("Churros", qty: 1, price: 800),
                ],
                totalCents: 5700,
                savingsCents: 600
            ),
            partySize: 4,
            budgetCents: 6000,
            contextTags: ["Group Friendly", "Best Value"],
            baseHeartCount: 891
        ),
        DiscoverRecommendation(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111102")!,
            restaurantName: "Sakura Ramen",
            cuisine: "Japanese",
            distanceMiles: 0.7,
            imageSeed: 1,
            isVerified: true,
            combo: Combo(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222202")!,
                rank: 1,
                isTopPick: true,
                title: "Ramen Feast",
                subtitle: "Warm bowls · gyoza · drinks",
                lineItems: [
                    lineItem("Tonkotsu Ramen", qty: 2, price: 1800),
                    lineItem("Miso Ramen", qty: 2, price: 1700),
                    lineItem("Pork Gyoza", qty: 2, price: 900),
                    lineItem("Green Tea", qty: 4, price: 400),
                ],
                totalCents: 9600,
                savingsCents: 800
            ),
            partySize: 4,
            budgetCents: 10000,
            contextTags: ["Most Food", "Late Night"],
            baseHeartCount: 518
        ),
        DiscoverRecommendation(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111103")!,
            restaurantName: "Osteria Bella",
            cuisine: "Italian",
            distanceMiles: 0.4,
            imageSeed: 0,
            isVerified: true,
            combo: Combo(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222203")!,
                rank: 1,
                isTopPick: true,
                title: "Date Night for 2",
                subtitle: "Pasta · wine · shared starters",
                lineItems: [
                    lineItem("Bruschetta al Pomodoro", qty: 1, price: 900),
                    lineItem("Risotto ai Funghi", qty: 1, price: 2400),
                    lineItem("Spaghetti alle Vongole", qty: 1, price: 2600),
                    lineItem("House Red Wine", qty: 2, price: 1200),
                ],
                totalCents: 7100,
                savingsCents: 400
            ),
            partySize: 2,
            budgetCents: 7500,
            contextTags: ["Date Night", "Romantic"],
            baseHeartCount: 342
        ),
        DiscoverRecommendation(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111104")!,
            restaurantName: "Sakura Ramen",
            cuisine: "Japanese",
            distanceMiles: 0.7,
            imageSeed: 1,
            isVerified: true,
            combo: Combo(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222204")!,
                rank: 1,
                isTopPick: false,
                title: "Solo Late Night",
                subtitle: "One bowl · one side",
                lineItems: [
                    lineItem("Spicy Miso Ramen", qty: 1, price: 1750),
                    lineItem("Edamame", qty: 1, price: 650),
                    lineItem("Ramune Soda", qty: 1, price: 450),
                ],
                totalCents: 2850,
                savingsCents: 150
            ),
            partySize: 1,
            budgetCents: 3000,
            contextTags: ["Solo", "Late Night"],
            baseHeartCount: 423
        ),
        DiscoverRecommendation(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111105")!,
            restaurantName: "Osteria Bella",
            cuisine: "Italian",
            distanceMiles: 0.4,
            imageSeed: 0,
            isVerified: true,
            combo: Combo(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222205")!,
                rank: 1,
                isTopPick: false,
                title: "Vegetarian Share",
                subtitle: "Meat-free · shareable",
                lineItems: [
                    lineItem("Margherita Pizza", qty: 1, price: 1800),
                    lineItem("Risotto ai Funghi", qty: 2, price: 2400),
                    lineItem("Bruschetta al Pomodoro", qty: 1, price: 900),
                    lineItem("Acqua Naturale", qty: 2, price: 500),
                ],
                totalCents: 8000,
                savingsCents: 500
            ),
            partySize: 3,
            budgetCents: 8500,
            contextTags: ["Vegetarian", "Healthy"],
            baseHeartCount: 267
        ),
        DiscoverRecommendation(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111106")!,
            restaurantName: "Harvest & Hole",
            cuisine: "American",
            distanceMiles: 1.3,
            imageSeed: 3,
            isVerified: true,
            combo: Combo(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222206")!,
                rank: 1,
                isTopPick: true,
                title: "Brunch Squad",
                subtitle: "Eggs · pancakes · coffee",
                lineItems: [
                    lineItem("Avocado Toast", qty: 2, price: 1400),
                    lineItem("Eggs Benedict", qty: 2, price: 1600),
                    lineItem("Blueberry Pancakes", qty: 1, price: 1300),
                    lineItem("Cold Brew", qty: 3, price: 550),
                ],
                totalCents: 8250,
                savingsCents: 450
            ),
            partySize: 4,
            budgetCents: 9000,
            contextTags: ["Brunch", "Family Style"],
            baseHeartCount: 156
        ),
    ]

    private static func lineItem(_ name: String, qty: Int, price: Int) -> ComboLineItem {
        ComboLineItem(
            menuItemId: UUID(),
            name: name,
            quantity: qty,
            unitPriceCents: price
        )
    }
}

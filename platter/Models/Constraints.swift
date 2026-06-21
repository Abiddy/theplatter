import Foundation

enum DietaryRule: String, Codable, CaseIterable, Identifiable {
    // Primary (always visible)
    case vegetarian
    case glutenFree = "gluten_free"
    case noNuts = "no_nuts"
    case vegan
    case noFish = "no_fish"
    case noPork = "no_pork"
    case halal
    case kosher

    // Extended (behind "See more")
    case noShellfish = "no_shellfish"
    case dairyFree = "dairy_free"
    case eggFree = "egg_free"
    case soyFree = "soy_free"
    case sesameFree = "sesame_free"
    case noBeef = "no_beef"
    case noLamb = "no_lamb"
    case noAlcohol = "no_alcohol"
    case noSpicy = "no_spicy"
    case lowSodium = "low_sodium"
    case lowCarb = "low_carb"
    case keto
    case paleo
    case pescatarian
    case diabeticFriendly = "diabetic_friendly"

    var id: String { rawValue }

    /// The 8 rules shown by default; the rest appear after "See more".
    static var primary: [DietaryRule] {
        [.vegetarian, .glutenFree, .noNuts, .vegan, .noFish, .noPork, .halal, .kosher]
    }

    static var extended: [DietaryRule] {
        allCases.filter { !primary.contains($0) }
    }

    var label: String {
        switch self {
        case .vegetarian: "Vegetarian"
        case .glutenFree: "Gluten-free"
        case .noNuts: "No Nuts"
        case .vegan: "Vegan"
        case .noFish: "No Fish"
        case .noPork: "No Pork"
        case .halal: "Halal"
        case .kosher: "Kosher"
        case .noShellfish: "No Shellfish"
        case .dairyFree: "Dairy-free"
        case .eggFree: "Egg-free"
        case .soyFree: "Soy-free"
        case .sesameFree: "Sesame-free"
        case .noBeef: "No Beef"
        case .noLamb: "No Lamb"
        case .noAlcohol: "No Alcohol"
        case .noSpicy: "Not Spicy"
        case .lowSodium: "Low Sodium"
        case .lowCarb: "Low Carb"
        case .keto: "Keto"
        case .paleo: "Paleo"
        case .pescatarian: "Pescatarian"
        case .diabeticFriendly: "Diabetic-friendly"
        }
    }

    var icon: String {
        switch self {
        case .vegetarian: "leaf"
        case .glutenFree: "leaf.circle"
        case .noNuts: "allergens"
        case .vegan: "carrot"
        case .noFish: "fish"
        case .noPork: "fork.knife"
        case .halal: "moon.stars"
        case .kosher: "star"
        case .noShellfish: "water.waves"
        case .dairyFree: "drop"
        case .eggFree: "circle.slash"
        case .soyFree: "leaf.arrow.circlepath"
        case .sesameFree: "circle.grid.3x3"
        case .noBeef: "nosign"
        case .noLamb: "nosign"
        case .noAlcohol: "wineglass"
        case .noSpicy: "flame"
        case .lowSodium: "drop.triangle"
        case .lowCarb: "chart.line.downtrend.xyaxis"
        case .keto: "bolt.heart"
        case .paleo: "figure.run"
        case .pescatarian: "fish.circle"
        case .diabeticFriendly: "cross.case"
        }
    }
}

enum OptimizeGoal: String, Codable, CaseIterable, Identifiable {
    case bestValue = "best_value"
    case mostFood = "most_food"
    case bestVariety = "best_variety"
    case healthy
    case highProtein = "high_protein"
    case familyStyle = "family_style"
    case kidFriendly = "kid_friendly"
    case dessertIncluded = "dessert_included"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bestValue: "Best value"
        case .mostFood: "Most food"
        case .bestVariety: "Best variety"
        case .healthy: "Healthy picks"
        case .highProtein: "High protein"
        case .familyStyle: "Family style"
        case .kidFriendly: "Kid friendly"
        case .dessertIncluded: "Dessert included"
        }
    }

    var icon: String {
        switch self {
        case .bestValue: "banknote"
        case .mostFood: "fork.knife"
        case .bestVariety: "sparkles"
        case .healthy: "heart"
        case .highProtein: "dumbbell"
        case .familyStyle: "person.3"
        case .kidFriendly: "face.smiling"
        case .dessertIncluded: "birthday.cake"
        }
    }

    var subtitle: String {
        switch self {
        case .bestValue: "Maximize food per dollar"
        case .mostFood: "Fill everyone up"
        case .bestVariety: "Mix of categories"
        case .healthy: "Lighter, balanced picks"
        case .highProtein: "Protein-forward dishes"
        case .familyStyle: "Shareable plates"
        case .kidFriendly: "Crowd-pleasers for all ages"
        case .dessertIncluded: "Leave room for something sweet"
        }
    }
}

struct Constraints: Codable, Equatable {
    var partySize: Int = 2
    var budgetCents: Int = 10_000
    var dietaryRules: Set<DietaryRule> = []
    var vegetarianCount: Int = 0
    var optimizeGoals: Set<OptimizeGoal> = [.bestValue]
    var freeTextNotes: String = ""

    var budgetFormatted: String {
        String(format: "$%.0f", Double(budgetCents) / 100.0)
    }

    var perPersonCents: Int {
        guard partySize > 0 else { return budgetCents }
        return budgetCents / partySize
    }

    var perPersonFormatted: String {
        String(format: "$%.0f", Double(perPersonCents) / 100.0)
    }
}

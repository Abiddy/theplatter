import Foundation

struct Combo: Codable, Equatable, Identifiable {
    var id: UUID
    var rank: Int
    var isTopPick: Bool
    var title: String
    var subtitle: String
    var lineItems: [ComboLineItem]
    var totalCents: Int
    var savingsCents: Int

    var totalFormatted: String {
        String(format: "$%.2f", Double(totalCents) / 100.0)
    }

    var savingsFormatted: String {
        String(format: "$%.2f", Double(savingsCents) / 100.0)
    }
}

struct ComboLineItem: Codable, Equatable, Identifiable {
    var id: UUID
    var menuItemId: UUID
    var name: String
    var quantity: Int
    var lineTotalCents: Int

    init(
        id: UUID = UUID(),
        menuItemId: UUID,
        name: String,
        quantity: Int,
        unitPriceCents: Int
    ) {
        self.id = id
        self.menuItemId = menuItemId
        self.name = name
        self.quantity = quantity
        self.lineTotalCents = unitPriceCents * quantity
    }

    var lineTotalFormatted: String {
        String(format: "$%.2f", Double(lineTotalCents) / 100.0)
    }
}

struct ComboGenerationResult: Equatable {
    var combos: [Combo]
    var aiSummary: String
    var constraintTags: [String]
}

import SwiftUI

struct SavedView: View {
    @State private var savedCombos: [SavedCombo] = SavedComboStore.load()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Saved")
                    .font(PlatterFont.title(28))
                    .foregroundStyle(PlatterColors.textPrimary)
                    .padding(.top, 8)

                if savedCombos.isEmpty {
                    emptyState
                } else {
                    ForEach(savedCombos) { saved in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(saved.restaurantName)
                                .font(PlatterFont.headline(16))
                                .foregroundStyle(PlatterColors.textPrimary)
                            Text(saved.combo.title)
                                .font(PlatterFont.body(14))
                                .foregroundStyle(PlatterColors.textSecondary)
                            Text(saved.combo.totalFormatted)
                                .font(PlatterFont.headline(17))
                                .foregroundStyle(PlatterColors.brandOrange)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PlatterColors.cardWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(PlatterColors.background)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 40))
                .foregroundStyle(PlatterColors.textSecondary.opacity(0.4))
            Text("No saved combos yet")
                .font(PlatterFont.headline(16))
                .foregroundStyle(PlatterColors.textSecondary)
            Text("Save a combo from your results to revisit later.")
                .font(PlatterFont.body(14))
                .foregroundStyle(PlatterColors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct SavedCombo: Identifiable, Codable {
    var id: UUID
    var restaurantName: String
    var combo: Combo
    var savedAt: Date
}

enum SavedComboStore {
    private static let key = "platter.savedCombos"

    static func load() -> [SavedCombo] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let combos = try? JSONDecoder().decode([SavedCombo].self, from: data) else {
            return []
        }
        return combos
    }

    static func save(_ combo: Combo, restaurantName: String) {
        var existing = load()
        existing.insert(SavedCombo(id: UUID(), restaurantName: restaurantName, combo: combo, savedAt: Date()), at: 0)
        if let data = try? JSONEncoder().encode(existing) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

#Preview {
    SavedView()
}

import SwiftUI

struct BudgetSlider: View {
    @Binding var budgetCents: Int
    let range: ClosedRange<Int>
    let step: Int
    let partySize: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Spacer()
                Text(budgetFormatted)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(PlatterColors.brandOrange)
            }

            Slider(
                value: Binding(
                    get: { Double(budgetCents) },
                    set: { budgetCents = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: Double(step)
            )
            .tint(PlatterColors.brandOrange)

            HStack {
                Text(minFormatted)
                Spacer()
                Text(maxFormatted)
            }
            .font(PlatterFont.caption(12))
            .foregroundStyle(PlatterColors.textSecondary)

            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(PlatterColors.brandOrange)
                Text("~\(perPersonFormatted) per person · tips & tax not included")
                    .font(PlatterFont.body(13))
                    .foregroundStyle(PlatterColors.brandOrange)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PlatterColors.brandOrangeLight)
            .clipShape(Capsule())
        }
    }

    private var budgetFormatted: String {
        String(format: "$%.0f", Double(budgetCents) / 100.0)
    }

    private var minFormatted: String {
        String(format: "$%.0f", Double(range.lowerBound) / 100.0)
    }

    private var maxFormatted: String {
        String(format: "$%.0f", Double(range.upperBound) / 100.0)
    }

    private var perPersonFormatted: String {
        guard partySize > 0 else { return "$0" }
        let perPerson = budgetCents / partySize
        return String(format: "$%.0f", Double(perPerson) / 100.0)
    }
}

import SwiftUI

struct OptimizeOptionCard: View {
    let goal: OptimizeGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? PlatterColors.brandOrange : PlatterColors.neutralGray)
                        .frame(width: 44, height: 44)
                    Image(systemName: goal.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isSelected ? .white : PlatterColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(PlatterFont.headline(15))
                        .foregroundStyle(PlatterColors.textPrimary)
                    Text(goal.subtitle)
                        .font(PlatterFont.body(13))
                        .foregroundStyle(PlatterColors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(PlatterColors.brandOrange)
                }
            }
            .padding(14)
            .background(isSelected ? PlatterColors.brandOrangeLight : PlatterColors.neutralGray.opacity(0.55))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? PlatterColors.brandOrange : Color.clear, lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// Keep OptimizeBadge for any legacy usage
struct OptimizeBadge: View {
    let goal: OptimizeGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        OptimizeOptionCard(goal: goal, isSelected: isSelected, action: action)
    }
}

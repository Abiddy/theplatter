import SwiftUI

struct DietaryChip: View {
    let rule: DietaryRule
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: rule.icon)
                    .font(.system(size: 13))
                Text(rule.label)
                    .font(PlatterFont.caption(13))
            }
            .foregroundStyle(isSelected ? PlatterColors.brandOrange : PlatterColors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? PlatterColors.brandOrangeLight : PlatterColors.cardWhite)
            .overlay {
                Capsule()
                    .stroke(isSelected ? PlatterColors.brandOrange : PlatterColors.chipBorder, lineWidth: 1.5)
            }
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

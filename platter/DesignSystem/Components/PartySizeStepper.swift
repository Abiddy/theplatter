import SwiftUI

struct PartySizeStepper: View {
    @Binding var partySize: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 16) {
            stepButton(systemName: "minus", enabled: partySize > range.lowerBound) {
                partySize -= 1
            }

            VStack(spacing: 2) {
                Text("\(partySize)")
                    .font(PlatterFont.displayNumber())
                    .foregroundStyle(PlatterColors.brandOrange)
                Text("people")
                    .font(PlatterFont.caption(12))
                    .foregroundStyle(PlatterColors.textSecondary)
            }
            .frame(maxWidth: .infinity)

            stepButton(systemName: "plus", enabled: partySize < range.upperBound) {
                partySize += 1
            }
        }
    }

    private func stepButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(enabled ? PlatterColors.textPrimary : PlatterColors.textTertiary)
                .frame(width: 48, height: 48)
                .background(PlatterColors.neutralGray)
                .clipShape(Circle())
        }
        .disabled(!enabled)
    }
}

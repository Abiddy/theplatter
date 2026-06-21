import SwiftUI

struct PlatterSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(PlatterFont.sectionLabel())
                .foregroundStyle(PlatterColors.textSecondary)
                .tracking(0.6)

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlatterColors.cardWhite)
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(PlatterColors.chipBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

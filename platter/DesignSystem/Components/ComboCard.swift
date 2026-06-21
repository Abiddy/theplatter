import SwiftUI

struct ComboCard: View {
    let combo: Combo
    var onOrder: () -> Void
    var onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if combo.isTopPick {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Platter AI Top Pick")
                        .font(PlatterFont.caption(12))
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(PlatterColors.brandOrange)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Text("#\(combo.rank)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(PlatterColors.textPrimary)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(combo.title)
                            .font(PlatterFont.headline(17))
                            .foregroundStyle(PlatterColors.textPrimary)
                        Text(combo.subtitle)
                            .font(PlatterFont.body(13))
                            .foregroundStyle(PlatterColors.textSecondary)
                    }
                }

                VStack(spacing: 10) {
                    ForEach(combo.lineItems) { item in
                        HStack(spacing: 10) {
                            Text("\(item.quantity)x")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(minWidth: 28, minHeight: 28)
                                .background(PlatterColors.brandOrange)
                                .clipShape(Circle())

                            Text(item.name)
                                .font(PlatterFont.body(14))
                                .foregroundStyle(PlatterColors.textPrimary)

                            Spacer()

                            Text(item.lineTotalFormatted)
                                .font(PlatterFont.body(14))
                                .foregroundStyle(PlatterColors.textSecondary)
                        }
                    }
                }

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 10))
                        Text("Saved \(combo.savingsFormatted)")
                            .font(PlatterFont.caption(12))
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(PlatterColors.savingsGreenText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(PlatterColors.savingsGreenBg)
                    .clipShape(Capsule())

                    Spacer()

                    Text(combo.totalFormatted)
                        .font(.system(size: 22, weight: .bold, design: .default))
                        .foregroundStyle(PlatterColors.textPrimary)
                }

                HStack(spacing: 12) {
                    Button(action: onOrder) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text("Order This")
                                .font(PlatterFont.headline(15))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(PlatterColors.brandOrange)
                        .clipShape(Capsule())
                    }

                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(PlatterColors.textPrimary)
                            .frame(width: 48, height: 48)
                            .background(PlatterColors.neutralGray)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(16)
        }
        .background(PlatterColors.cardWhite)
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(combo.isTopPick ? PlatterColors.brandOrange : PlatterColors.chipBorder, lineWidth: combo.isTopPick ? 2 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: PlatterColors.shadow, radius: 8, y: 4)
    }
}

struct AISummaryBanner: View {
    let summary: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(PlatterColors.brandOrange)
                    .frame(width: 36, height: 36)
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Platter AI says:")
                    .font(PlatterFont.caption(12))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(summary)
                    .font(PlatterFont.body(14))
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlatterColors.aiBannerDark)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct ConstraintTagRow: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 5) {
                        Image(systemName: iconForTag(tag))
                            .font(.system(size: 11))
                        Text(tag)
                            .font(PlatterFont.caption(12))
                    }
                    .foregroundStyle(PlatterColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(PlatterColors.cardWhite)
                    .overlay {
                        Capsule()
                            .stroke(PlatterColors.chipBorder, lineWidth: 1)
                    }
                    .clipShape(Capsule())
                }
            }
        }
    }

    private func iconForTag(_ tag: String) -> String {
        let lower = tag.lowercased()
        if lower.contains("party") { return "person.2" }
        if lower.contains("fish") || lower.contains("diet") { return "leaf" }
        if lower.contains("budget") || lower.contains("$") { return "dollarsign.circle" }
        return "tag"
    }
}

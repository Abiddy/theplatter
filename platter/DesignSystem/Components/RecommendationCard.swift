import SwiftUI

struct RecommendationCard: View {
    let recommendation: DiscoverRecommendation
    let heartCount: Int
    let isHearted: Bool
    var showsRestaurantMeta: Bool = true
    var showsFullMenuLink: Bool = true
    let onHeart: () -> Void
    var onFullMenu: (() -> Void)? = nil

    private var previewItems: [ComboLineItem] {
        Array(recommendation.combo.lineItems.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RestaurantImagePlaceholder(seed: recommendation.imageSeed)
                    .frame(height: 140)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))

                heartButton
                    .padding(12)
            }

            VStack(alignment: .leading, spacing: 12) {
                if showsRestaurantMeta {
                    restaurantRow
                }
                comboHeader
                lineItemsPreview
                contextRow
                footerRow
            }
            .padding(16)
        }
        .background(PlatterColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: PlatterColors.shadow, radius: 10, y: 4)
    }

    private var heartButton: some View {
        Button(action: onHeart) {
            HStack(spacing: 5) {
                Image(systemName: isHearted ? "heart.fill" : "heart")
                    .font(.system(size: 14, weight: .semibold))
                Text(formattedHeartCount)
                    .font(PlatterFont.caption(12))
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isHearted ? PlatterColors.brandOrange : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.55))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isHearted)
    }

    private var formattedHeartCount: String {
        if heartCount >= 1000 {
            return String(format: "%.1fk", Double(heartCount) / 1000.0)
        }
        return "\(heartCount)"
    }

    private var restaurantRow: some View {
        HStack(spacing: 8) {
            if recommendation.isVerified {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(PlatterColors.verifiedBadge)
            }

            Text(recommendation.restaurantName)
                .font(PlatterFont.headline(16))
                .foregroundStyle(PlatterColors.textPrimary)

            Spacer()

            Text("\(recommendation.cuisine) · \(recommendation.distanceFormatted)")
                .font(PlatterFont.caption(12))
                .foregroundStyle(PlatterColors.textSecondary)
        }
    }

    private var comboHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recommendation.combo.title)
                .font(PlatterFont.headline(17))
                .foregroundStyle(PlatterColors.textPrimary)
            Text(recommendation.combo.subtitle)
                .font(PlatterFont.body(13))
                .foregroundStyle(PlatterColors.textSecondary)
        }
    }

    private var lineItemsPreview: some View {
        VStack(spacing: 8) {
            ForEach(previewItems) { item in
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
                        .lineLimit(1)

                    Spacer()

                    Text(item.lineTotalFormatted)
                        .font(PlatterFont.caption(13))
                        .foregroundStyle(PlatterColors.textSecondary)
                }
            }

            if recommendation.combo.lineItems.count > previewItems.count {
                Text("+\(recommendation.combo.lineItems.count - previewItems.count) more items")
                    .font(PlatterFont.caption(12))
                    .foregroundStyle(PlatterColors.textSecondary)
            }
        }
        .padding(12)
        .background(PlatterColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var contextRow: some View {
        FlowLayout(spacing: 6) {
            contextChip("\(recommendation.partySize) people", icon: "person.2.fill")
            contextChip(recommendation.budgetFormatted, icon: "dollarsign.circle")
            ForEach(recommendation.contextTags, id: \.self) { tag in
                contextChip(tag, icon: nil)
            }
        }
    }

    private func contextChip(_ text: String, icon: String?) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(PlatterFont.caption(11))
        }
        .foregroundStyle(PlatterColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(PlatterColors.tagBackground)
        .clipShape(Capsule())
    }

    private var footerRow: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(recommendation.combo.totalFormatted)
                        .font(PlatterFont.headline(20))
                        .foregroundStyle(PlatterColors.brandOrange)
                    Text("total")
                        .font(PlatterFont.caption(12))
                        .foregroundStyle(PlatterColors.textSecondary)
                }
                Text(recommendation.perPersonFormatted)
                    .font(PlatterFont.caption(12))
                    .foregroundStyle(PlatterColors.textSecondary)
            }

            Spacer()

            if showsFullMenuLink, let onFullMenu {
                fullMenuButton(action: onFullMenu)
            }
        }
    }

    private func fullMenuButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: "book.fill")
                    .font(.system(size: 18, weight: .medium))
                Text("Full menu")
                    .font(PlatterFont.caption(11))
                    .fontWeight(.semibold)
            }
            .foregroundStyle(PlatterColors.brandOrange)
            .frame(minWidth: 64)
        }
        .buttonStyle(.plain)
    }
}

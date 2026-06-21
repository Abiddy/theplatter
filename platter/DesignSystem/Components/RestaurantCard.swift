import SwiftUI

struct RestaurantCard: View {
    let restaurant: Restaurant
    var onGetRecommendations: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RestaurantImagePlaceholder(seed: restaurant.imageSeed)
                    .frame(height: 180)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))

                if restaurant.isVerified {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                        Text("Verified")
                            .font(PlatterFont.caption(11))
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(PlatterColors.verifiedBadge)
                    .clipShape(Capsule())
                    .padding(12)
                }

                Text(restaurant.priceTier)
                    .font(PlatterFont.caption(13))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.65))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(12)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(restaurant.name)
                        .font(PlatterFont.headline(18))
                        .foregroundStyle(PlatterColors.textPrimary)
                    Spacer()
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(PlatterColors.brandOrange)
                        Text("\(restaurant.ratingFormatted) (\(restaurant.reviewCount))")
                            .font(PlatterFont.caption(13))
                            .foregroundStyle(PlatterColors.textSecondary)
                    }
                }

                Text("\(restaurant.cuisine) • \(restaurant.distanceFormatted)")
                    .font(PlatterFont.body(13))
                    .foregroundStyle(PlatterColors.textSecondary)

                FlowLayout(spacing: 6) {
                    ForEach(restaurant.tags, id: \.self) { tag in
                        Text(tag)
                            .font(PlatterFont.caption(11))
                            .foregroundStyle(PlatterColors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(PlatterColors.tagBackground)
                            .clipShape(Capsule())
                    }
                }

                if let onGetRecommendations {
                    Button(action: onGetRecommendations) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Get Recommendations")
                                .font(PlatterFont.headline(15))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(PlatterColors.brandOrange)
                        .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
        }
        .background(PlatterColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: PlatterColors.shadow, radius: 10, y: 4)
    }
}

struct RestaurantImagePlaceholder: View {
    let seed: Int

    private var gradient: LinearGradient {
        let palettes: [(Color, Color)] = [
            (Color(red: 0.85, green: 0.55, blue: 0.35), Color(red: 0.65, green: 0.35, blue: 0.25)),
            (Color(red: 0.45, green: 0.65, blue: 0.75), Color(red: 0.25, green: 0.45, blue: 0.55)),
            (Color(red: 0.75, green: 0.55, blue: 0.65), Color(red: 0.55, green: 0.35, blue: 0.45)),
            (Color(red: 0.55, green: 0.75, blue: 0.55), Color(red: 0.35, green: 0.55, blue: 0.35)),
        ]
        let pair = palettes[seed % palettes.count]
        return LinearGradient(colors: [pair.0, pair.1], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        ZStack {
            gradient
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

/// Simple flow layout for tag chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

import SwiftUI

struct RestaurantDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DiscoverRecommendationStore.self) private var discoverStore

    let restaurantName: String

    private var recommendations: [DiscoverRecommendation] {
        discoverStore.recommendations(forRestaurant: restaurantName)
    }

    private var menu: Menu {
        MockDataService.menu(for: restaurantName)
    }

    private var profile: DiscoverRecommendation? {
        recommendations.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroHeader
                recommendationsSection
                fullMenuSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(PlatterColors.background)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RestaurantImagePlaceholder(seed: profile?.imageSeed ?? 0)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                FlowBackButton {
                    dismiss()
                }
                .padding(12)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if profile?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(PlatterColors.verifiedBadge)
                    }
                    Text(restaurantName)
                        .font(PlatterFont.title(24))
                        .foregroundStyle(PlatterColors.textPrimary)
                }

                if let profile {
                    HStack(spacing: 12) {
                        Label(profile.cuisine, systemImage: "fork.knife")
                        Label(profile.distanceFormatted, systemImage: "location.fill")
                    }
                    .font(PlatterFont.caption(13))
                    .foregroundStyle(PlatterColors.textSecondary)
                }

                Text("\(recommendations.count) popular orders · \(menu.allItems.count) menu items")
                    .font(PlatterFont.body(14))
                    .foregroundStyle(PlatterColors.textSecondary)
            }
            .padding(.top, 16)
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Popular Orders",
                subtitle: "What people recommend here"
            )

            if recommendations.isEmpty {
                Text("No recommendations yet for this restaurant.")
                    .font(PlatterFont.body(14))
                    .foregroundStyle(PlatterColors.textSecondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(recommendations) { rec in
                    RecommendationCard(
                        recommendation: rec,
                        heartCount: discoverStore.heartCount(for: rec),
                        isHearted: discoverStore.isHearted(rec.id),
                        showsRestaurantMeta: false,
                        showsFullMenuLink: false,
                        onHeart: { discoverStore.toggleHeart(for: rec) }
                    )
                }
            }
        }
    }

    private var fullMenuSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Full Menu",
                subtitle: "Every dish available right now"
            )

            VStack(spacing: 16) {
                ForEach(menu.sections) { section in
                    menuSectionCard(section)
                }
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(PlatterFont.headline(18))
                .foregroundStyle(PlatterColors.textPrimary)
            Text(subtitle)
                .font(PlatterFont.body(13))
                .foregroundStyle(PlatterColors.textSecondary)
        }
    }

    private func menuSectionCard(_ section: MenuSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.name.uppercased())
                .font(PlatterFont.sectionLabel(11))
                .foregroundStyle(PlatterColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Divider()
                        .padding(.leading, 16)
                }
                menuItemRow(item)
            }
        }
        .background(PlatterColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(PlatterColors.chipBorder, lineWidth: 1)
        }
    }

    private func menuItemRow(_ item: MenuItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(PlatterFont.headline(15))
                    .foregroundStyle(PlatterColors.textPrimary)

                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(PlatterFont.body(13))
                        .foregroundStyle(PlatterColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if item.isVegetarian || item.isVegan || item.isGlutenFree {
                    HStack(spacing: 6) {
                        if item.isVegan {
                            dietaryBadge("Vegan")
                        } else if item.isVegetarian {
                            dietaryBadge("Vegetarian")
                        }
                        if item.isGlutenFree {
                            dietaryBadge("GF")
                        }
                    }
                }
            }

            Spacer(minLength: 12)

            Text(item.priceFormatted)
                .font(PlatterFont.headline(15))
                .foregroundStyle(PlatterColors.brandOrange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func dietaryBadge(_ label: String) -> some View {
        Text(label)
            .font(PlatterFont.caption(10))
            .foregroundStyle(PlatterColors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(PlatterColors.tagBackground)
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        RestaurantDetailView(restaurantName: "Osteria Bella")
    }
    .environment(DiscoverRecommendationStore())
}

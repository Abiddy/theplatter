import SwiftUI

struct DiscoverView: View {
    @Environment(AppState.self) private var appState
    @Environment(DiscoverRecommendationStore.self) private var discoverStore

    @State private var searchText = ""
    @State private var selectedCuisine: CuisineFilter = .all
    @State private var selectedSort: DiscoverSort = .trending
    @State private var selectedRestaurant: RestaurantRoute?

    private var filteredRecommendations: [DiscoverRecommendation] {
        discoverStore.recommendations.filter { rec in
            let matchesSearch = searchText.isEmpty
                || rec.restaurantName.localizedCaseInsensitiveContains(searchText)
                || rec.cuisine.localizedCaseInsensitiveContains(searchText)
                || rec.combo.title.localizedCaseInsensitiveContains(searchText)
                || rec.contextTags.contains { $0.localizedCaseInsensitiveContains(searchText) }
                || rec.combo.lineItems.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            let matchesCuisine = selectedCuisine == .all || rec.cuisine == selectedCuisine.rawValue
            return matchesSearch && matchesCuisine
        }
    }

    private var displayedRecommendations: [DiscoverRecommendation] {
        discoverStore.sorted(selectedSort, filtered: filteredRecommendations)
    }

    private var trendingTop: [DiscoverRecommendation] {
        discoverStore.sorted(.trending, filtered: filteredRecommendations).prefix(3).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                discoverContent
            }
            .background(PlatterColors.background)
            .navigationDestination(item: $selectedRestaurant) { route in
                RestaurantDetailView(restaurantName: route.name)
            }
            .refreshable { await discoverStore.refresh() }
            .task { await discoverStore.refresh() }
        }
    }

    private var discoverContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            searchBar
            sortPills
            cuisinePills

            if !trendingTop.isEmpty, selectedSort == .trending, searchText.isEmpty, selectedCuisine == .all {
                trendingHighlight
            }

            recommendationFeed
            aiBanner
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(PlatterColors.textSecondary)
            TextField("Search orders, dishes, or cuisines...", text: $searchText)
                .font(PlatterFont.body(14))
            Spacer(minLength: 0)
            Button {} label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(PlatterColors.brandOrange)
                    .clipShape(Circle())
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .padding(.vertical, 7)
        .background(PlatterColors.cardWhite)
        .overlay {
            Capsule()
                .stroke(PlatterColors.chipBorder, lineWidth: 1)
        }
        .clipShape(Capsule())
    }

    private var sortPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DiscoverSort.allCases) { sort in
                    Button {
                        selectedSort = sort
                    } label: {
                        HStack(spacing: 4) {
                            if sort == .trending {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                            }
                            Text(sort.rawValue)
                                .font(PlatterFont.caption(12))
                        }
                        .foregroundStyle(selectedSort == sort ? .white : PlatterColors.textPrimary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .background(selectedSort == sort ? PlatterColors.brandOrange : PlatterColors.cardWhite)
                        .overlay {
                            Capsule()
                                .stroke(PlatterColors.chipBorder, lineWidth: selectedSort == sort ? 0 : 1)
                        }
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var cuisinePills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CuisineFilter.allCases) { cuisine in
                    Button {
                        selectedCuisine = cuisine
                    } label: {
                        Text(cuisine.rawValue)
                            .font(PlatterFont.caption(12))
                            .foregroundStyle(selectedCuisine == cuisine ? .white : PlatterColors.textPrimary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 6)
                            .background(selectedCuisine == cuisine ? PlatterColors.textPrimary : PlatterColors.cardWhite)
                            .overlay {
                                Capsule()
                                    .stroke(PlatterColors.chipBorder, lineWidth: selectedCuisine == cuisine ? 0 : 1)
                            }
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var trendingHighlight: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(PlatterColors.brandOrange)
                Text("Popular near you")
                    .font(PlatterFont.headline(16))
                    .foregroundStyle(PlatterColors.textPrimary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(trendingTop) { rec in
                        trendingMiniCard(rec)
                    }
                }
            }
        }
    }

    private func trendingMiniCard(_ rec: DiscoverRecommendation) -> some View {
        let hearts = discoverStore.heartCount(for: rec)
        return VStack(alignment: .leading, spacing: 8) {
            Text(rec.combo.title)
                .font(PlatterFont.headline(14))
                .foregroundStyle(PlatterColors.textPrimary)
                .lineLimit(2)
            Text(rec.restaurantName)
                .font(PlatterFont.caption(12))
                .foregroundStyle(PlatterColors.textSecondary)
            HStack {
                Label("\(hearts)", systemImage: "heart.fill")
                    .font(PlatterFont.caption(11))
                    .foregroundStyle(PlatterColors.brandOrange)
                Spacer()
                Text(rec.combo.totalFormatted)
                    .font(PlatterFont.caption(12))
                    .fontWeight(.semibold)
                    .foregroundStyle(PlatterColors.textPrimary)
            }
        }
        .padding(14)
        .frame(width: 180, alignment: .leading)
        .background(PlatterColors.cardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(PlatterColors.chipBorder, lineWidth: 1)
        }
    }

    private var recommendationFeed: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(feedTitle)
                    .font(PlatterFont.headline(18))
                    .foregroundStyle(PlatterColors.textPrimary)
                Spacer()
                Text("\(displayedRecommendations.count) orders")
                    .font(PlatterFont.caption(13))
                    .foregroundStyle(PlatterColors.textSecondary)
            }

            if displayedRecommendations.isEmpty {
                emptyState
            } else {
                ForEach(displayedRecommendations) { rec in
                    RecommendationCard(
                        recommendation: rec,
                        heartCount: discoverStore.heartCount(for: rec),
                        isHearted: discoverStore.isHearted(rec.id),
                        onHeart: { discoverStore.toggleHeart(for: rec) },
                        onFullMenu: { selectedRestaurant = RestaurantRoute(name: rec.restaurantName) }
                    )
                }
            }
        }
    }

    private var feedTitle: String {
        switch selectedSort {
        case .trending: "Trending Orders"
        case .nearby: "Nearby Orders"
        case .newest: "New Picks"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(PlatterColors.textSecondary.opacity(0.4))
            Text("No orders match your filters")
                .font(PlatterFont.headline(15))
                .foregroundStyle(PlatterColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var aiBanner: some View {
        Button {
            appState.openScanFlow()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Build your own order")
                        .font(PlatterFont.headline(15))
                        .foregroundStyle(.white)
                    Text("Scan a menu · set budget & diet · done.")
                        .font(PlatterFont.body(13))
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(16)
            .background(PlatterColors.brandOrange)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DiscoverView()
        .environment(AppState())
        .environment(DiscoverRecommendationStore())
}

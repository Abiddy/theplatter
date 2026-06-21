import SwiftUI

struct DiscoverView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedCuisine: CuisineFilter = .all

    private var filteredRestaurants: [Restaurant] {
        MockDataService.restaurants.filter { restaurant in
            let matchesSearch = searchText.isEmpty
                || restaurant.name.localizedCaseInsensitiveContains(searchText)
                || restaurant.cuisine.localizedCaseInsensitiveContains(searchText)
            let matchesCuisine = selectedCuisine == .all || restaurant.cuisine == selectedCuisine.rawValue
            return matchesSearch && matchesCuisine
        }
    }

    private var trending: [Restaurant] {
        filteredRestaurants.filter { $0.section == .trending }
    }

    private var nearby: [Restaurant] {
        filteredRestaurants.filter { $0.section == .nearby }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                searchBar
                cuisinePills

                if !trending.isEmpty {
                    restaurantSection(title: "Trending Near You", restaurants: trending)
                }

                if !nearby.isEmpty {
                    restaurantSection(title: "More Nearby", restaurants: nearby)
                }

                aiBanner
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(PlatterColors.background)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(PlatterFont.body(14))
                    .foregroundStyle(PlatterColors.textSecondary)
                Text("Discover")
                    .font(PlatterFont.title(28))
                    .foregroundStyle(PlatterColors.textPrimary)
            }

            Spacer()

            Circle()
                .fill(LinearGradient(
                    colors: [Color(red: 0.8, green: 0.6, blue: 0.5), Color(red: 0.6, green: 0.4, blue: 0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }
        }
        .padding(.top, 8)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(PlatterColors.textSecondary)
            TextField("Search restaurants or cuisines...", text: $searchText)
                .font(PlatterFont.body(15))
            Spacer(minLength: 0)
            Button {} label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(PlatterColors.brandOrange)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(PlatterColors.cardWhite)
        .overlay {
            Capsule()
                .stroke(PlatterColors.chipBorder, lineWidth: 1)
        }
        .clipShape(Capsule())
    }

    private var cuisinePills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CuisineFilter.allCases) { cuisine in
                    Button {
                        selectedCuisine = cuisine
                    } label: {
                        Text(cuisine.rawValue)
                            .font(PlatterFont.caption(13))
                            .foregroundStyle(selectedCuisine == cuisine ? .white : PlatterColors.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCuisine == cuisine ? PlatterColors.brandOrange : PlatterColors.cardWhite)
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

    private func restaurantSection(title: String, restaurants: [Restaurant]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(PlatterFont.headline(18))
                    .foregroundStyle(PlatterColors.textPrimary)
                Spacer()
                Text("See all")
                    .font(PlatterFont.caption(13))
                    .foregroundStyle(PlatterColors.brandOrange)
            }

            ForEach(restaurants) { restaurant in
                RestaurantCard(restaurant: restaurant) {
                    appState.openScanFlow(restaurantName: restaurant.name)
                }
            }
        }
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
                    Text("Let Platter AI order for you")
                        .font(PlatterFont.headline(15))
                        .foregroundStyle(.white)
                    Text("Set budget, diet & party size — done.")
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
}

import SwiftUI

struct PriceGuideView: View {
    @State private var items: [PriceGuideItem] = []
    @State private var trendingItems: [TrendingItem] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""
    @State private var currentPage = 1
    @State private var hasMorePages = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, placeholder: "Search price guide") {
                    Task { await search() }
                }
                .padding()

                if isLoading && items.isEmpty {
                    LoadingView()
                } else if let error = error, items.isEmpty {
                    ErrorView(message: error) {
                        Task { await loadItems() }
                    }
                } else {
                    contentView
                }
            }
            .navigationTitle("Price Guide")
            .task {
                await loadTrending()
                await loadItems()
            }
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Trending section
                if searchText.isEmpty && !trendingItems.isEmpty {
                    trendingSection
                }

                // All items
                VStack(alignment: .leading, spacing: 12) {
                    Text(searchText.isEmpty ? "Browse All" : "Search Results")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVStack(spacing: 12) {
                        ForEach(items) { item in
                            NavigationLink {
                                PriceGuideDetailView(itemId: item.id)
                            } label: {
                                PriceGuideItemRow(item: item)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                if item.id == items.last?.id && hasMorePages {
                                    Task { await loadMore() }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    if isLoading && !items.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await loadTrending()
            await loadItems()
        }
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trending")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(trendingItems) { item in
                        NavigationLink {
                            PriceGuideDetailView(itemId: item.id)
                        } label: {
                            TrendingItemCard(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func loadItems() async {
        currentPage = 1
        isLoading = true
        error = nil

        do {
            let response = try await PriceGuideService.shared.getItems(
                page: 1,
                search: searchText.isEmpty ? nil : searchText
            )
            items = response.results
            hasMorePages = response.next != nil
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func loadMore() async {
        guard !isLoading && hasMorePages else { return }

        isLoading = true
        currentPage += 1

        do {
            let response = try await PriceGuideService.shared.getItems(
                page: currentPage,
                search: searchText.isEmpty ? nil : searchText
            )
            items.append(contentsOf: response.results)
            hasMorePages = response.next != nil
        } catch {
            currentPage -= 1
        }

        isLoading = false
    }

    private func loadTrending() async {
        do {
            trendingItems = try await PriceGuideService.shared.getTrending()
        } catch {
            // Non-critical
        }
    }

    private func search() async {
        await loadItems()
    }
}

struct PriceGuideItemRow: View {
    let item: PriceGuideItem

    var body: some View {
        HStack(spacing: 12) {
            // Image
            if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                AsyncImageView(url: url)
                    .frame(width: 70, height: 70)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 70, height: 70)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                if let year = item.year {
                    Text("\(year)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    if let avgPrice = item.averagePrice {
                        Text("$\(avgPrice)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    PriceChangeText(
                        change: item.priceChange30d,
                        percentChange: item.priceChangePercent30d
                    )
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.salesCount) sales")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct TrendingItemCard: View {
    let item: TrendingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                AsyncImageView(url: url)
                    .frame(width: 120, height: 120)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 120)
            }

            Text(item.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)

            HStack(spacing: 4) {
                Image(systemName: trendIcon)
                    .font(.caption2)

                if let price = item.currentPrice {
                    Text("$\(price)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(trendColor)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var trendIcon: String {
        switch item.trend {
        case "up": return "arrow.up.right"
        case "down": return "arrow.down.right"
        default: return "arrow.right"
        }
    }

    private var trendColor: Color {
        switch item.trend {
        case "up": return .brandMint
        case "down": return .brandCrimson
        default: return .secondary
        }
    }
}

#Preview {
    PriceGuideView()
}

import SwiftUI

struct MarketplaceView: View {
    @State private var listings: [Listing] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var searchText = ""
    @State private var selectedCategory: Int?
    @State private var selectedListingType: String?
    @State private var currentPage = 1
    @State private var hasMorePages = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $searchText, placeholder: "Search listings") {
                    Task { await search() }
                }
                .padding()

                FilterChipGroup(
                    options: ["Fixed Price", "Auction"],
                    selected: $selectedListingType
                )
                .onChange(of: selectedListingType) {
                    Task { await search() }
                }

                if isLoading && listings.isEmpty {
                    LoadingView()
                } else if let error = error, listings.isEmpty {
                    ErrorView(message: error) {
                        Task { await loadListings() }
                    }
                } else if listings.isEmpty {
                    EmptyStateView(
                        icon: "storefront",
                        title: "No Listings",
                        message: "No listings match your search criteria"
                    )
                } else {
                    listingsGrid
                }
            }
            .navigationTitle("Marketplace")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SavedListingsView()
                    } label: {
                        Image(systemName: "heart")
                    }
                }
            }
            .task {
                await loadListings()
            }
        }
    }

    private var listingsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(listings) { listing in
                    NavigationLink {
                        ListingDetailView(listingId: listing.id)
                    } label: {
                        ListingCard(listing: listing)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if listing.id == listings.last?.id && hasMorePages {
                            Task { await loadMore() }
                        }
                    }
                }
            }
            .padding()

            if isLoading && !listings.isEmpty {
                ProgressView()
                    .padding()
            }
        }
        .refreshable {
            await loadListings()
        }
    }

    private func loadListings() async {
        currentPage = 1
        isLoading = true
        error = nil

        do {
            let response = try await MarketplaceService.shared.getListings(
                page: 1,
                category: selectedCategory,
                search: searchText.isEmpty ? nil : searchText,
                listingType: listingTypeValue
            )
            listings = response.results
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
            let response = try await MarketplaceService.shared.getListings(
                page: currentPage,
                category: selectedCategory,
                search: searchText.isEmpty ? nil : searchText,
                listingType: listingTypeValue
            )
            listings.append(contentsOf: response.results)
            hasMorePages = response.next != nil
        } catch {
            currentPage -= 1
        }

        isLoading = false
    }

    private func search() async {
        await loadListings()
    }

    private var listingTypeValue: String? {
        switch selectedListingType {
        case "Fixed Price": return "fixed"
        case "Auction": return "auction"
        default: return nil
        }
    }
}

struct ListingCard: View {
    let listing: Listing

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            AsyncImageView(url: listing.primaryImageURL)
                .frame(height: 140)
                .clipped()
                .cornerRadius(8)

            // Title
            Text(listing.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Price
            HStack {
                if listing.isAuction {
                    VStack(alignment: .leading, spacing: 2) {
                        if let currentBid = listing.currentBid {
                            Text("$\(currentBid)")
                                .font(.headline)
                                .foregroundStyle(.blue)
                        } else {
                            Text("$\(listing.price)")
                                .font(.headline)
                        }
                        Text("\(listing.bidCount) bids")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("$\(listing.price)")
                        .font(.headline)
                }

                Spacer()

                if listing.isAuction {
                    Image(systemName: "gavel")
                        .foregroundStyle(.orange)
                }
            }

            // Seller info
            HStack(spacing: 4) {
                AvatarView(url: listing.seller.avatarUrl, size: 20)
                Text(listing.seller.username)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if listing.seller.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                if listing.seller.isTrustedSeller {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                        Text("Trusted")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.83, green: 0.63, blue: 0.09))
                    .cornerRadius(4)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    MarketplaceView()
}

import SwiftUI

struct SavedListingsView: View {
    @State private var listings: [Listing] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadListings() }
                }
            } else if listings.isEmpty {
                EmptyStateView(
                    icon: "heart",
                    title: "No Saved Listings",
                    message: "Items you save will appear here"
                )
            } else {
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
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await loadListings()
                }
            }
        }
        .navigationTitle("Saved Listings")
        .task {
            await loadListings()
        }
    }

    private func loadListings() async {
        isLoading = true
        error = nil

        do {
            let response = try await MarketplaceService.shared.getSavedListings()
            listings = response.results
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        SavedListingsView()
    }
}

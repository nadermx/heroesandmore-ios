import SwiftUI

struct SubmitLotView: View {
    let eventSlug: String
    let eventTitle: String
    var onSubmitted: (() -> Void)?

    @Environment(\.dismiss) var dismiss
    @State private var listings: [Listing] = []
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var error: String?
    @State private var successMessage: String?
    @State private var searchText = ""
    @State private var currentPage = 1
    @State private var hasMorePages = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Info banner
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Select one of your active listings to submit as a lot for \"\(eventTitle)\".")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))

                // Search
                SearchBar(text: $searchText, placeholder: "Search your listings") {
                    Task { await searchListings() }
                }
                .padding()

                // Content
                if let successMessage = successMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)

                        Text(successMessage)
                            .font(.headline)

                        Text("Staff will review your submission and you will be notified of the decision.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Done") {
                            onSubmitted?()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isLoading && listings.isEmpty {
                    LoadingView(message: "Loading your listings...")
                } else if let error = error, listings.isEmpty {
                    ErrorView(message: error) {
                        Task { await loadListings() }
                    }
                } else if listings.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "No Listings",
                        message: "You don't have any active listings to submit. Create a listing first, then come back to submit it."
                    )
                } else {
                    listingsList
                }
            }
            .navigationTitle("Submit a Lot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await loadListings()
            }
        }
    }

    private var listingsList: some View {
        List {
            ForEach(listings) { listing in
                Button {
                    Task { await submitListing(listing) }
                } label: {
                    listingRow(listing)
                }
                .disabled(isSubmitting)
                .onAppear {
                    if listing.id == listings.last?.id && hasMorePages {
                        Task { await loadMore() }
                    }
                }
            }

            if isLoading && !listings.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .listStyle(.plain)
    }

    private func listingRow(_ listing: Listing) -> some View {
        HStack(spacing: 12) {
            AsyncImageView(url: listing.primaryImageURL)
                .frame(width: 60, height: 60)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text("$\(listing.price)")
                        .font(.caption)
                        .fontWeight(.semibold)

                    if listing.isAuction {
                        HStack(spacing: 2) {
                            Image(systemName: "gavel")
                                .font(.system(size: 9))
                            Text("Auction")
                                .font(.caption2)
                        }
                        .foregroundStyle(.orange)
                    }

                    if let condition = listing.conditionDisplay {
                        Text(condition)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if isSubmitting {
                ProgressView()
            } else {
                Image(systemName: "arrow.up.circle")
                    .foregroundStyle(.blue)
                    .font(.title3)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Data Loading

    private func loadListings() async {
        currentPage = 1
        isLoading = true
        error = nil

        do {
            // Load user's own active listings
            let response = try await MarketplaceService.shared.getListings(
                page: 1,
                search: searchText.isEmpty ? nil : searchText
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
                search: searchText.isEmpty ? nil : searchText
            )
            listings.append(contentsOf: response.results)
            hasMorePages = response.next != nil
        } catch {
            currentPage -= 1
        }

        isLoading = false
    }

    private func searchListings() async {
        await loadListings()
    }

    private func submitListing(_ listing: Listing) async {
        isSubmitting = true
        error = nil

        do {
            let submission = try await MarketplaceService.shared.submitAuctionLot(
                eventSlug: eventSlug,
                listingId: listing.id
            )
            successMessage = "\"\(submission.listingTitle)\" submitted successfully!"
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = "Failed to submit lot. Please try again."
        }

        isSubmitting = false
    }
}

#Preview {
    SubmitLotView(
        eventSlug: "monthly-premium-jan-2026",
        eventTitle: "Monthly Premium Auction"
    )
}

import SwiftUI

struct PlatformAuctionsView: View {
    @State private var events: [AuctionEvent] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            if isLoading && events.isEmpty {
                LoadingView()
            } else if let error = error, events.isEmpty {
                ErrorView(message: error) {
                    Task { await loadEvents() }
                }
            } else if events.isEmpty {
                EmptyStateView(
                    icon: "gavel",
                    title: "No Auction Events",
                    message: "There are no platform auction events at this time. Check back soon!"
                )
            } else {
                eventsList
            }
        }
        .navigationTitle("Platform Auctions")
        .task {
            await loadEvents()
        }
    }

    private var eventsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(events) { event in
                    NavigationLink {
                        PlatformAuctionDetailView(event: event)
                    } label: {
                        AuctionEventCard(event: event)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .refreshable {
            await loadEvents()
        }
    }

    private func loadEvents() async {
        isLoading = true
        error = nil

        do {
            events = try await MarketplaceService.shared.getPlatformAuctionEvents()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct AuctionEventCard: View {
    let event: AuctionEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Event image
            if let imageUrlString = event.imageUrl, let imageUrl = URL(string: imageUrlString) {
                AsyncImageView(url: imageUrl, contentMode: .fill)
                    .frame(height: 180)
                    .clipped()
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandNavy, Color.brandNavyLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "gavel")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.6))
                            Text(event.title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
            }

            // Event details
            VStack(alignment: .leading, spacing: 10) {
                // Title and status badge row
                HStack(alignment: .top) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)

                    Spacer()

                    statusBadge
                }

                // Description
                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                // Info row
                HStack(spacing: 16) {
                    // Lot count
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2")
                            .font(.caption)
                        Text("\(event.listingCount) lots")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)

                    // Cadence badge
                    if let cadence = event.cadence {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(cadence.capitalized)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Dates
                    if let startDate = event.startDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(startDate, style: .date)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                // Accepting submissions indicator
                if event.acceptingSubmissions {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.brandMint)
                        Text("Accepting Submissions")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.brandMint)

                        if let deadline = event.submissionDeadline {
                            Text("until \(deadline, style: .date)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }

    private var statusBadge: some View {
        Text(event.status.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(6)
    }

    private var statusColor: Color {
        switch event.status.lowercased() {
        case "live":
            return .brandMint
        case "preview":
            return .brandCyan
        case "ended":
            return .gray
        case "draft":
            return .brandGold
        default:
            return .secondary
        }
    }
}

#Preview {
    NavigationStack {
        PlatformAuctionsView()
    }
}

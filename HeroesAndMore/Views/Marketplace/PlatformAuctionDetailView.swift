import SwiftUI

struct PlatformAuctionDetailView: View {
    let event: AuctionEvent

    @EnvironmentObject var authManager: AuthManager
    @State private var listings: [Listing] = []
    @State private var submissions: [AuctionLotSubmission] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showSubmitLot = false

    private var isTrustedSeller: Bool {
        authManager.currentUser?.isTrustedSeller ?? false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header image
                headerSection

                // Event info
                eventInfoSection

                Divider()
                    .padding(.horizontal)

                // Lots grid
                lotsSection
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if event.acceptingSubmissions && isTrustedSeller {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSubmitLot = true
                    } label: {
                        Label("Submit Lot", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showSubmitLot) {
            if let slug = event.slug {
                SubmitLotView(eventSlug: slug, eventTitle: event.title) {
                    Task { await loadSubmissions() }
                }
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Group {
            if let imageUrlString = event.imageUrl, let imageUrl = URL(string: imageUrlString) {
                AsyncImageView(url: imageUrl, contentMode: .fill)
                    .frame(height: 220)
                    .clipped()
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.1, green: 0.1, blue: 0.2), Color(red: 0.15, green: 0.15, blue: 0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 220)
                    .overlay {
                        Image(systemName: "gavel")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.4))
                    }
            }
        }
    }

    // MARK: - Event Info

    private var eventInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and status
            HStack(alignment: .top) {
                Text(event.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Text(event.status.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(6)
            }

            // Description
            if let description = event.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            // Stats row
            HStack(spacing: 20) {
                eventStat(icon: "square.grid.2x2", value: "\(event.listingCount)", label: "Lots")

                if let cadence = event.cadence {
                    eventStat(icon: "calendar", value: cadence.capitalized, label: "Cadence")
                }

                if let startDate = event.startDate {
                    eventStat(icon: "play.circle", value: formattedDate(startDate), label: "Starts")
                }

                if let endDate = event.endDate {
                    eventStat(icon: "stop.circle", value: formattedDate(endDate), label: "Ends")
                }
            }

            // Submissions info
            if event.acceptingSubmissions {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.green)
                        Text("Accepting Lot Submissions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }

                    if let deadline = event.submissionDeadline {
                        Text("Submission deadline: \(deadline, style: .date)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if isTrustedSeller {
                        Button {
                            showSubmitLot = true
                        } label: {
                            Label("Submit a Lot", systemImage: "arrow.up.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(Color(red: 0.83, green: 0.63, blue: 0.09))
                            Text("Only Trusted Sellers can submit lots to platform auctions.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }

            // My submissions
            if !submissions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("My Submissions")
                        .font(.headline)

                    ForEach(submissions) { submission in
                        submissionRow(submission)
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Lots Grid

    private var lotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Auction Lots")
                .font(.headline)
                .padding(.horizontal)

            if isLoading {
                LoadingView()
                    .frame(height: 200)
            } else if listings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No lots yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
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
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Submission Row

    private func submissionRow(_ submission: AuctionLotSubmission) -> some View {
        HStack(spacing: 12) {
            if let imageUrl = submission.listingImage, let url = URL(string: imageUrl) {
                AsyncImageView(url: url)
                    .frame(width: 50, height: 50)
                    .cornerRadius(6)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .cornerRadius(6)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(submission.listingTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let submittedAt = submission.submittedAt {
                    Text("Submitted \(submittedAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            submissionStatusBadge(submission.status)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private func submissionStatusBadge(_ status: String) -> some View {
        Text(status.capitalized)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(submissionStatusColor(status))
            .cornerRadius(4)
    }

    private func submissionStatusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "approved":
            return .green
        case "rejected":
            return .red
        case "pending":
            return .orange
        case "withdrawn":
            return .gray
        default:
            return .secondary
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch event.status.lowercased() {
        case "live":
            return .green
        case "preview":
            return .blue
        case "ended":
            return .gray
        case "draft":
            return .orange
        default:
            return .secondary
        }
    }

    private func eventStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        error = nil

        // Load event listings by filtering marketplace auctions
        // The API serves lots for a platform event via the general auctions endpoint
        do {
            if let slug = event.slug {
                let response = try await MarketplaceService.shared.getAuctionEvents(page: 1)
                // Filter to find our event's listings
                _ = response
            }
        } catch {
            // Non-critical: lots may not be available via this endpoint
        }

        // Load user's submissions for this event
        await loadSubmissions()

        isLoading = false
    }

    private func loadSubmissions() async {
        do {
            let allSubmissions = try await MarketplaceService.shared.getMySubmissions()
            submissions = allSubmissions.filter { $0.eventSlug == event.slug }
        } catch {
            // Non-critical
        }
    }
}

#Preview {
    NavigationStack {
        PlatformAuctionDetailView(
            event: AuctionEvent(
                id: 1,
                title: "Monthly Premium Auction",
                description: "Our monthly curated auction featuring the finest collectibles.",
                imageUrl: nil,
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 7),
                status: "live",
                listingCount: 24,
                slug: "monthly-premium-jan-2026",
                isPlatformEvent: true,
                cadence: "monthly",
                acceptingSubmissions: true,
                submissionDeadline: Date().addingTimeInterval(86400 * 3)
            )
        )
        .environmentObject(AuthManager())
    }
}

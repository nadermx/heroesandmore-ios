import SwiftUI

struct MyOffersView: View {
    @State private var offers: [Offer] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadOffers() }
                }
            } else if offers.isEmpty {
                EmptyStateView(
                    icon: "hand.raised",
                    title: "No Offers",
                    message: "Offers you make or receive will appear here"
                )
            } else {
                List(offers) { offer in
                    OfferRow(offer: offer) {
                        Task { await loadOffers() }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My Offers")
        .task {
            await loadOffers()
        }
        .refreshable {
            await loadOffers()
        }
    }

    private func loadOffers() async {
        isLoading = true
        error = nil

        do {
            let response = try await MarketplaceService.shared.getOffers()
            offers = response.results
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct OfferRow: View {
    let offer: Offer
    var onAction: () -> Void

    @State private var showCounterSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if let imageUrl = offer.listing.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImageView(url: url)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(offer.listing.title)
                        .font(.subheadline)
                        .lineLimit(2)

                    HStack {
                        Text("List: $\(offer.listing.price)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Offer: $\(offer.amount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    // Show counter-offer amount if present
                    if let counterAmount = offer.counterAmount {
                        HStack {
                            Text("Counter:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$\(counterAmount)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.brandCyan)
                        }
                    }
                }

                Spacer()

                statusBadge
            }

            if offer.status == "pending" && !offer.isFromBuyer {
                // Seller actions for pending offers
                HStack(spacing: 12) {
                    Button {
                        Task {
                            do {
                                try await MarketplaceService.shared.acceptOffer(offerId: offer.id)
                                onAction()
                            } catch {}
                        }
                    } label: {
                        Text("Accept")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button {
                        showCounterSheet = true
                    } label: {
                        Text("Counter")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button(role: .destructive) {
                        Task {
                            do {
                                try await MarketplaceService.shared.declineOffer(offerId: offer.id)
                                onAction()
                            } catch {}
                        }
                    } label: {
                        Text("Decline")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            if offer.status == "countered" && offer.isFromBuyer {
                // Buyer actions for counter-offers
                VStack(spacing: 8) {
                    if let timeRemaining = offer.timeRemaining {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("Expires in \(timeRemaining)")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Button {
                            Task {
                                do {
                                    try await MarketplaceService.shared.acceptCounterOffer(offerId: offer.id)
                                    onAction()
                                } catch {}
                            }
                        } label: {
                            Text("Accept Counter")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button(role: .destructive) {
                            Task {
                                do {
                                    try await MarketplaceService.shared.declineCounterOffer(offerId: offer.id)
                                    onAction()
                                } catch {}
                            }
                        } label: {
                            Text("Decline")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            if let message = offer.message, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showCounterSheet) {
            CounterOfferSheet(offer: offer, onCounter: onAction)
        }
    }

    private var statusBadge: some View {
        Text(offer.status.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .cornerRadius(8)
    }

    private var statusColor: Color {
        switch offer.status {
        case "accepted": return .brandMint
        case "declined": return .brandCrimson
        case "pending": return .brandGold
        case "countered": return .brandCyan
        default: return .secondary
        }
    }
}

struct CounterOfferSheet: View {
    let offer: Offer
    var onCounter: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var amount = ""
    @State private var message = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Their Offer")
                        Spacer()
                        Text("$\(offer.amount)")
                    }

                    HStack {
                        Text("$")
                        TextField("Your Counter", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Message (Optional)") {
                    TextField("Add a message...", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Counter Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Send") {
                        Task { await sendCounter() }
                    }
                    .disabled(amount.isEmpty || isLoading)
                }
            }
        }
    }

    private func sendCounter() async {
        isLoading = true

        do {
            _ = try await MarketplaceService.shared.counterOffer(
                offerId: offer.id,
                amount: amount,
                message: message.isEmpty ? nil : message
            )
            onCounter()
            dismiss()
        } catch {}

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        MyOffersView()
    }
}

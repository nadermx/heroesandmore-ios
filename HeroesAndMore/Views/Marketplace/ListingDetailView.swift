import SwiftUI

struct ListingDetailView: View {
    let listingId: Int

    @State private var listing: ListingDetail?
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedImageIndex = 0
    @State private var showBidSheet = false
    @State private var showOfferSheet = false
    @State private var isWatched = false
    @State private var showFullscreenImage = false
    @State private var selectedQuantity = 1
    @State private var quickBidAmount: String?

    var body: some View {
        ScrollView {
            if isLoading {
                LoadingView()
                    .frame(height: 400)
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadListing() }
                }
                .frame(height: 400)
            } else if let listing = listing {
                listingContent(listing)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await toggleWatched() }
                } label: {
                    Image(systemName: isWatched ? "heart.fill" : "heart")
                        .foregroundStyle(isWatched ? .red : .primary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: URL(string: "https://heroesandmore.com/marketplace/\(listingId)/")!) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .task {
            await loadListing()
        }
        .sheet(isPresented: $showBidSheet) {
            if let listing = listing {
                BidSheet(listing: listing, prefillAmount: quickBidAmount) {
                    Task { await loadListing() }
                }
            }
        }
        .onChange(of: showBidSheet) {
            if !showBidSheet {
                quickBidAmount = nil
            }
        }
        .sheet(isPresented: $showOfferSheet) {
            if let listing = listing {
                OfferSheet(listing: listing)
            }
        }
    }

    @ViewBuilder
    private func listingContent(_ listing: ListingDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Images
            if !listing.images.isEmpty {
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(listing.images.enumerated()), id: \.element.id) { index, image in
                        AsyncImageView(url: URL(string: image.url), contentMode: .fit)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 300)
                .background(Color.black)
                .onTapGesture {
                    showFullscreenImage = true
                }
                .fullScreenCover(isPresented: $showFullscreenImage) {
                    FullscreenImageViewer(
                        images: listing.images,
                        selectedIndex: $selectedImageIndex,
                        isPresented: $showFullscreenImage
                    )
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(listing.title)
                    .font(.title2)
                    .fontWeight(.bold)

                // Price section
                priceSection(listing)

                Divider()

                // Seller info
                sellerSection(listing)

                Divider()

                // Details
                if let description = listing.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)

                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                // Condition
                if let condition = listing.conditionDisplay {
                    HStack {
                        Text("Condition")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(condition)
                            .fontWeight(.medium)
                    }
                }

                // Shipping
                if let shipping = listing.shippingPrice {
                    HStack {
                        Text("Shipping")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(shipping == "0.00" ? "Free" : "$\(shipping)")
                            .fontWeight(.medium)
                    }
                }

                // Action buttons
                actionButtons(listing)

                // Bid history
                bidHistorySection(listing)

                // Sell Yours CTA
                sellYoursCTA()
            }
            .padding()
        }
    }

    @ViewBuilder
    private func sellYoursCTA() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Have one like this?")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("List yours and reach thousands of collectors.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Button("Sell Yours") {
                    // Navigate to create listing
                }
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.1))
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func priceSection(_ listing: ListingDetail) -> some View {
        if listing.listingType == "auction" {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current Bid")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let bid = listing.currentBid {
                        Text("$\(bid)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.brandCrimson)
                    } else {
                        Text("No bids yet")
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text("Starting Price")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(listing.price)")
                }

                if let buyNow = listing.buyNowPrice {
                    HStack {
                        Text("Buy Now")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("$\(buyNow)")
                            .fontWeight(.semibold)
                    }
                }

                HStack {
                    Image(systemName: "gavel")
                    Text("\(listing.bidCount) bids")

                    Spacer()

                    if let endDate = listing.endDate {
                        Image(systemName: "clock")
                        Text(endDate, style: .relative)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Social proof badges
                socialProofBadges(listing)

                // Comps range
                if let comps = listing.compsRange {
                    HStack {
                        Text("Recent Comps:")
                            .fontWeight(.bold)
                        Text("$\(comps.low) – $\(comps.high)")
                            .foregroundStyle(.brandCrimson)
                    }
                    .font(.subheadline)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("$\(listing.price)")
                        .font(.title)
                        .fontWeight(.bold)

                    Spacer()

                    if listing.acceptsOffers {
                        Text("or Best Offer")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let available = listing.quantityAvailable, available > 1 {
                    Text("\(available) available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func socialProofBadges(_ listing: ListingDetail) -> some View {
        if listing.listingType == "auction" {
            HStack(spacing: 8) {
                if let watchers = listing.watcherCount, watchers > 0 {
                    Label("\(watchers) watching", systemImage: "eye")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                if let recentBids = listing.recentBidCount, recentBids > 0 {
                    Label("\(recentBids) bid\(recentBids == 1 ? "" : "s") in last minute", systemImage: "bolt.fill")
                        .font(.caption2)
                        .foregroundStyle(.brandCrimson)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.brandCrimson.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                if listing.bidWarActive == true {
                    Label("Bid war active", systemImage: "flame.fill")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.brandCrimson)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    @ViewBuilder
    private func sellerSection(_ listing: ListingDetail) -> some View {
        HStack {
            AvatarView(url: listing.seller.avatarUrl, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(listing.seller.username)
                        .fontWeight(.semibold)

                    if listing.seller.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.brandCyan)
                    }

                    if listing.seller.isTrustedSeller {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("Trusted")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.brandGold)
                        .cornerRadius(4)
                    }
                }

                RatingView(rating: listing.seller.rating, count: listing.seller.ratingCount)
            }

            Spacer()

            NavigationLink {
                // SellerProfileView
                Text("Seller Profile")
            } label: {
                Text("View Profile")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private func bidHistorySection(_ listing: ListingDetail) -> some View {
        if let bids = listing.bidHistory, !bids.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bid History")
                    .font(.headline)

                ForEach(Array(bids.enumerated()), id: \.element.id) { index, bid in
                    HStack {
                        if index == 0 {
                            Image(systemName: "trophy.fill")
                                .font(.caption)
                                .foregroundStyle(.brandGold)
                        }
                        Text(bid.bidder)
                            .fontWeight(index == 0 ? .bold : .regular)
                            .foregroundStyle(index == 0 ? .brandCrimson : .primary)
                        Spacer()
                        Text("$\(bid.amount)")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    if index < bids.count - 1 { Divider() }
                }
            }
        }
    }

    @ViewBuilder
    private func actionButtons(_ listing: ListingDetail) -> some View {
        VStack(spacing: 12) {
            if listing.listingType == "auction" {
                Button {
                    showBidSheet = true
                } label: {
                    Label("Place Bid", systemImage: "gavel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                // Quick bid buttons
                HStack(spacing: 8) {
                    ForEach([10, 25, 50], id: \.self) { increment in
                        Button("+$\(increment)") {
                            let currentPrice = Decimal(string: listing.currentBid ?? listing.price) ?? 0
                            let newBid = currentPrice + Decimal(increment)
                            quickBidAmount = "\(newBid)"
                            showBidSheet = true
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                if listing.buyNowPrice != nil {
                    Button {
                        // Buy now action
                    } label: {
                        Label("Buy Now", systemImage: "cart")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            } else {
                let available = listing.quantityAvailable ?? 1

                // Quantity selector for multi-quantity listings
                if available > 1 {
                    HStack {
                        Text("Quantity")
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 12) {
                            Button {
                                selectedQuantity = max(1, selectedQuantity - 1)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .disabled(selectedQuantity <= 1)

                            Text("\(selectedQuantity)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(minWidth: 30)

                            Button {
                                selectedQuantity = min(available, selectedQuantity + 1)
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                            .disabled(selectedQuantity >= available)
                        }
                    }
                    .padding(.bottom, 4)
                }

                if available == 0 {
                    Button {} label: {
                        Label("Sold Out", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(true)
                } else {
                    Button {
                        // Buy action
                    } label: {
                        Label(selectedQuantity > 1 ? "Buy \(selectedQuantity)" : "Buy Now", systemImage: "cart")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if listing.acceptsOffers {
                        Button {
                            showOfferSheet = true
                        } label: {
                            Label("Make Offer", systemImage: "hand.raised")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
            }

            Button {
                // Message seller
            } label: {
                Label("Message Seller", systemImage: "message")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top)
    }

    private func loadListing() async {
        isLoading = true
        error = nil

        do {
            listing = try await MarketplaceService.shared.getListing(id: listingId)
            isWatched = listing?.isWatched ?? false
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func toggleWatched() async {
        do {
            if isWatched {
                try await MarketplaceService.shared.unsaveListing(id: listingId)
            } else {
                try await MarketplaceService.shared.saveListing(id: listingId)
            }
            isWatched.toggle()
        } catch {
            // Handle error
        }
    }
}

struct BidSheet: View {
    let listing: ListingDetail
    var prefillAmount: String?
    var onBidPlaced: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var bidAmount = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Current Bid")
                        Spacer()
                        Text("$\(listing.currentBid ?? listing.price)")
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Your Bid")
                        TextField("Amount", text: $bidAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // Quick bid buttons
                Section {
                    HStack(spacing: 8) {
                        ForEach([10, 25, 50], id: \.self) { increment in
                            Button("+$\(increment)") {
                                let currentPrice = Decimal(string: listing.currentBid ?? listing.price) ?? 0
                                let newBid = currentPrice + Decimal(increment)
                                bidAmount = "\(newBid)"
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await placeBid() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Place Bid")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(bidAmount.isEmpty || isLoading)
                }
            }
            .navigationTitle("Place Bid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let prefillAmount = prefillAmount {
                    bidAmount = prefillAmount
                }
            }
        }
    }

    private func placeBid() async {
        isLoading = true
        error = nil

        do {
            _ = try await MarketplaceService.shared.placeBid(listingId: listing.id, amount: bidAmount)
            onBidPlaced()
            dismiss()
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = "Failed to place bid"
        }

        isLoading = false
    }
}

struct OfferSheet: View {
    let listing: ListingDetail

    @Environment(\.dismiss) var dismiss
    @State private var amount = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("List Price")
                        Spacer()
                        Text("$\(listing.price)")
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("Your Offer")
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Message (Optional)") {
                    TextField("Add a message to the seller...", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await makeOffer() }
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Send Offer")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(amount.isEmpty || isLoading)
                }
            }
            .navigationTitle("Make Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func makeOffer() async {
        isLoading = true
        error = nil

        do {
            _ = try await MarketplaceService.shared.makeOffer(
                listingId: listing.id,
                amount: amount,
                message: message.isEmpty ? nil : message
            )
            dismiss()
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = "Failed to make offer"
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ListingDetailView(listingId: 1)
    }
}

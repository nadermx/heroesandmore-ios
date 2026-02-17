import SwiftUI

struct MyOrdersView: View {
    @State private var orders: [Order] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var orderType = "bought"

    var body: some View {
        VStack(spacing: 0) {
            Picker("Order Type", selection: $orderType) {
                Text("Purchased").tag("bought")
                Text("Sold").tag("sold")
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: orderType) {
                Task { await loadOrders() }
            }

            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadOrders() }
                }
            } else if orders.isEmpty {
                EmptyStateView(
                    icon: "bag",
                    title: "No Orders",
                    message: orderType == "bought" ? "Items you purchase will appear here" : "Items you sell will appear here"
                )
            } else {
                List(orders) { order in
                    NavigationLink {
                        OrderDetailView(orderId: order.id)
                    } label: {
                        OrderRow(order: order)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My Orders")
        .task {
            await loadOrders()
        }
    }

    private func loadOrders() async {
        isLoading = true
        error = nil

        do {
            let response = try await MarketplaceService.shared.getOrders(type: orderType)
            orders = response.results
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct OrderRow: View {
    let order: Order

    var body: some View {
        HStack(spacing: 12) {
            if let imageUrl = order.listing.imageUrl, let url = URL(string: imageUrl) {
                AsyncImageView(url: url)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(order.listing.title)
                    .font(.subheadline)
                    .lineLimit(2)

                Text(order.statusDisplay)
                    .font(.caption)
                    .foregroundStyle(statusColor)

                if let date = order.created {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("$\(order.total)")
                .fontWeight(.semibold)
        }
    }

    private var statusColor: Color {
        switch order.status {
        case "completed": return .brandMint
        case "shipped": return .brandCyan
        case "pending": return .brandGold
        case "cancelled": return .brandCrimson
        default: return .secondary
        }
    }
}

struct OrderDetailView: View {
    let orderId: Int

    @State private var order: Order?
    @State private var isLoading = true
    @State private var error: String?
    @State private var showShipSheet = false
    @State private var showReviewSheet = false

    var body: some View {
        ScrollView {
            if isLoading {
                LoadingView()
                    .frame(height: 400)
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadOrder() }
                }
                .frame(height: 400)
            } else if let order = order {
                orderContent(order)
            }
        }
        .navigationTitle("Order #\(order?.orderNumber ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadOrder()
        }
        .sheet(isPresented: $showShipSheet) {
            if let order = order {
                ShipOrderSheet(order: order) {
                    Task { await loadOrder() }
                }
            }
        }
        .sheet(isPresented: $showReviewSheet) {
            if let order = order {
                ReviewOrderSheet(order: order) {
                    Task { await loadOrder() }
                }
            }
        }
    }

    @ViewBuilder
    private func orderContent(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Status
            HStack {
                Text("Status")
                Spacer()
                Text(order.statusDisplay)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor(order.status))
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)

            // Item
            VStack(alignment: .leading, spacing: 12) {
                Text("Item")
                    .font(.headline)

                HStack(spacing: 12) {
                    if let imageUrl = order.listing.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImageView(url: url)
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading) {
                        Text(order.listing.title)
                            .fontWeight(.medium)
                        Text("$\(order.total)")
                            .font(.headline)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)

            // Tracking
            if let tracking = order.trackingNumber {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tracking")
                        .font(.headline)

                    HStack {
                        if let carrier = order.trackingCarrier {
                            Text(carrier)
                        }
                        Text(tracking)
                            .foregroundStyle(.brandCyan)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }

            // Shipping address
            if let address = order.shippingAddress {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shipping Address")
                        .font(.headline)

                    Text(address.name)
                    Text(address.street1)
                    if let street2 = address.street2, !street2.isEmpty {
                        Text(street2)
                    }
                    Text("\(address.city), \(address.state) \(address.zip)")
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }

            // Actions
            orderActions(order)
        }
        .padding()
    }

    @ViewBuilder
    private func orderActions(_ order: Order) -> some View {
        VStack(spacing: 12) {
            if order.status == "paid" {
                Button {
                    showShipSheet = true
                } label: {
                    Label("Mark as Shipped", systemImage: "shippingbox")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if order.status == "shipped" {
                Button {
                    Task {
                        do {
                            _ = try await MarketplaceService.shared.markOrderReceived(orderId: order.id)
                            await loadOrder()
                        } catch {}
                    }
                } label: {
                    Label("Confirm Received", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if order.status == "delivered" {
                Button {
                    showReviewSheet = true
                } label: {
                    Label("Leave Review", systemImage: "star")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "completed": return .brandMint
        case "shipped": return .brandCyan
        case "pending", "paid": return .brandGold
        case "cancelled": return .brandCrimson
        default: return .secondary
        }
    }

    private func loadOrder() async {
        isLoading = true
        error = nil

        do {
            order = try await MarketplaceService.shared.getOrder(id: orderId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct ShipOrderSheet: View {
    let order: Order
    var onShipped: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var trackingNumber = ""
    @State private var carrier = "USPS"
    @State private var isLoading = false

    let carriers = ["USPS", "UPS", "FedEx", "DHL", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Carrier", selection: $carrier) {
                        ForEach(carriers, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }

                    TextField("Tracking Number (optional)", text: $trackingNumber)
                }
            }
            .navigationTitle("Ship Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Ship") {
                        Task { await shipOrder() }
                    }
                    .disabled(isLoading)
                }
            }
        }
    }

    private func shipOrder() async {
        isLoading = true

        do {
            _ = try await MarketplaceService.shared.markOrderShipped(
                orderId: order.id,
                trackingNumber: trackingNumber.isEmpty ? nil : trackingNumber,
                carrier: carrier
            )
            onShipped()
            dismiss()
        } catch {}

        isLoading = false
    }
}

struct ReviewOrderSheet: View {
    let order: Order
    var onReviewed: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var rating = 5
    @State private var comment = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Rating")
                        Spacer()
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundStyle(.brandGold)
                                .onTapGesture {
                                    rating = star
                                }
                        }
                    }
                }

                Section("Comment (Optional)") {
                    TextField("Write a review...", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Leave Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Submit") {
                        Task { await submitReview() }
                    }
                    .disabled(isLoading)
                }
            }
        }
    }

    private func submitReview() async {
        isLoading = true

        do {
            _ = try await MarketplaceService.shared.leaveReview(
                orderId: order.id,
                rating: rating,
                comment: comment.isEmpty ? nil : comment
            )
            onReviewed()
            dismiss()
        } catch {}

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        MyOrdersView()
    }
}

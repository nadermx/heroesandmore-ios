import SwiftUI

struct PriceAlertsView: View {
    @State private var priceAlerts: [PriceAlert] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadPriceAlerts() }
                }
            } else if priceAlerts.isEmpty {
                EmptyStateView(
                    icon: "bell.badge",
                    title: "No Price Alerts",
                    message: "Set alerts to get notified when prices change"
                )
            } else {
                List {
                    ForEach(priceAlerts) { alert in
                        PriceAlertRow(alert: alert)
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                try? await AlertService.shared.deletePriceAlert(id: priceAlerts[index].id)
                            }
                            await loadPriceAlerts()
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Price Alerts")
        .task {
            await loadPriceAlerts()
        }
    }

    private func loadPriceAlerts() async {
        isLoading = true
        error = nil

        do {
            let response = try await AlertService.shared.getPriceAlerts()
            priceAlerts = response.results
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct PriceAlertRow: View {
    let alert: PriceAlert

    var body: some View {
        NavigationLink {
            PriceGuideDetailView(itemId: alert.priceGuideItem.id)
        } label: {
            HStack(spacing: 12) {
                if let imageUrl = alert.priceGuideItem.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImageView(url: url)
                        .frame(width: 50, height: 50)
                        .cornerRadius(6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.priceGuideItem.name)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    HStack {
                        Image(systemName: alert.alertType == "below" ? "arrow.down" : "arrow.up")
                        Text("$\(alert.targetPrice)")
                    }
                    .font(.caption)
                    .foregroundStyle(alert.alertType == "below" ? .brandMint : .brandCrimson)
                }

                Spacer()

                if alert.triggered {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.brandMint)
                } else if alert.isActive {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(.brandCyan)
                } else {
                    Image(systemName: "bell.slash")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PriceAlertsView()
    }
}

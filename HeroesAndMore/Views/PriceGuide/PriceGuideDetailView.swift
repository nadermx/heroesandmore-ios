import SwiftUI
import Charts

struct PriceGuideDetailView: View {
    let itemId: Int

    @State private var item: PriceGuideItem?
    @State private var gradePrices: [GradePrice] = []
    @State private var priceHistory: [PriceHistory] = []
    @State private var recentSales: [SaleRecord] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedPeriod = "1y"
    @State private var showAddToCollectionSheet = false
    @State private var showPriceAlertSheet = false

    let periods = ["1m", "3m", "6m", "1y", "all"]

    var body: some View {
        ScrollView {
            if isLoading {
                LoadingView()
                    .frame(height: 400)
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadData() }
                }
                .frame(height: 400)
            } else if let item = item {
                itemContent(item)
            }
        }
        .navigationTitle(item?.name ?? "Price Guide")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showAddToCollectionSheet = true
                    } label: {
                        Label("Add to Collection", systemImage: "plus.square")
                    }

                    Button {
                        showPriceAlertSheet = true
                    } label: {
                        Label("Set Price Alert", systemImage: "bell")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await loadData()
        }
        .sheet(isPresented: $showPriceAlertSheet) {
            if let item = item {
                PriceAlertSheet(item: item)
            }
        }
    }

    @ViewBuilder
    private func itemContent(_ item: PriceGuideItem) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 16) {
                if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImageView(url: url)
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    if let year = item.year {
                        Text("\(year)")
                            .foregroundStyle(.secondary)
                    }

                    if let avgPrice = item.averagePrice {
                        HStack {
                            Text("$\(avgPrice)")
                                .font(.title2)
                                .fontWeight(.bold)

                            PriceChangeText(
                                change: item.priceChange30d,
                                percentChange: item.priceChangePercent30d
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)

            // Price stats
            priceStatsSection(item)

            // Price chart
            if !priceHistory.isEmpty {
                priceChartSection
            }

            // Grade prices
            if !gradePrices.isEmpty {
                gradePricesSection
            }

            // Recent sales
            if !recentSales.isEmpty {
                recentSalesSection
            }
        }
        .padding(.vertical)
    }

    private func priceStatsSection(_ item: PriceGuideItem) -> some View {
        HStack(spacing: 0) {
            statBox(title: "Low", value: item.lowPrice)
            Divider()
            statBox(title: "Average", value: item.averagePrice)
            Divider()
            statBox(title: "High", value: item.highPrice)
        }
        .frame(height: 70)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
        .padding(.horizontal)
    }

    private func statBox(title: String, value: String?) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let value = value {
                Text("$\(value)")
                    .font(.headline)
            } else {
                Text("--")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var priceChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Price History")
                    .font(.headline)

                Spacer()

                Picker("Period", selection: $selectedPeriod) {
                    ForEach(periods, id: \.self) { period in
                        Text(period.uppercased()).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .onChange(of: selectedPeriod) {
                    Task { await loadPriceHistory() }
                }
            }
            .padding(.horizontal)

            if #available(iOS 16.0, *) {
                Chart(priceHistory) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Price", Double(dataPoint.averagePrice) ?? 0)
                    )
                    .foregroundStyle(.brandCyan)

                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Price", Double(dataPoint.averagePrice) ?? 0)
                    )
                    .foregroundStyle(.brandCyan.opacity(0.1))
                }
                .frame(height: 200)
                .padding(.horizontal)
            }
        }
    }

    private var gradePricesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prices by Grade")
                .font(.headline)
                .padding(.horizontal)

            LazyVStack(spacing: 8) {
                ForEach(gradePrices) { gradePrice in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(gradePrice.gradeCompany) \(gradePrice.grade)")
                                .fontWeight(.medium)

                            Text("\(gradePrice.salesCount) sales")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if let avgPrice = gradePrice.averagePrice {
                            Text("$\(avgPrice)")
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }

    private var recentSalesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sales")
                .font(.headline)
                .padding(.horizontal)

            LazyVStack(spacing: 8) {
                ForEach(recentSales) { sale in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            if let grade = sale.grade {
                                Text("\(sale.gradeCompany ?? "") \(grade)")
                                    .font(.subheadline)
                            }

                            if let date = sale.saleDate {
                                Text(date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(sale.price)")
                                .fontWeight(.semibold)

                            Text(sale.source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }

    private func loadData() async {
        isLoading = true
        error = nil

        do {
            async let itemTask = PriceGuideService.shared.getItem(id: itemId)
            async let gradesTask = PriceGuideService.shared.getGradePrices(itemId: itemId)
            async let historyTask = PriceGuideService.shared.getPriceHistory(itemId: itemId, period: selectedPeriod)
            async let salesTask = PriceGuideService.shared.getSales(itemId: itemId)

            item = try await itemTask
            gradePrices = try await gradesTask
            priceHistory = try await historyTask
            recentSales = try await salesTask.results
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func loadPriceHistory() async {
        do {
            priceHistory = try await PriceGuideService.shared.getPriceHistory(itemId: itemId, period: selectedPeriod)
        } catch {
            // Non-critical
        }
    }
}

struct PriceAlertSheet: View {
    let item: PriceGuideItem

    @Environment(\.dismiss) var dismiss
    @State private var targetPrice = ""
    @State private var alertType = "below"
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Current Price")
                        Spacer()
                        Text("$\(item.averagePrice ?? "0")")
                    }
                }

                Section {
                    Picker("Alert When", selection: $alertType) {
                        Text("Price drops below").tag("below")
                        Text("Price rises above").tag("above")
                    }

                    HStack {
                        Text("$")
                        TextField("Target Price", text: $targetPrice)
                            .keyboardType(.decimalPad)
                    }
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Price Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task { await createAlert() }
                    }
                    .disabled(targetPrice.isEmpty || isLoading)
                }
            }
        }
    }

    private func createAlert() async {
        isLoading = true
        error = nil

        do {
            _ = try await AlertService.shared.createPriceAlert(
                priceGuideItemId: item.id,
                targetPrice: targetPrice,
                alertType: alertType
            )
            dismiss()
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = "Failed to create alert"
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        PriceGuideDetailView(itemId: 1)
    }
}

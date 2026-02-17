import SwiftUI

struct CollectionDetailView: View {
    let collectionId: Int

    @State private var collection: CollectionDetail?
    @State private var valueSummary: ValueSummary?
    @State private var isLoading = true
    @State private var error: String?
    @State private var showAddItemSheet = false

    var body: some View {
        ScrollView {
            if isLoading {
                LoadingView()
                    .frame(height: 400)
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadCollection() }
                }
                .frame(height: 400)
            } else if let collection = collection {
                collectionContent(collection)
            }
        }
        .navigationTitle(collection?.name ?? "Collection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddItemSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await loadCollection()
            await loadValueSummary()
        }
        .sheet(isPresented: $showAddItemSheet) {
            AddCollectionItemSheet(collectionId: collectionId) {
                Task { await loadCollection() }
            }
        }
    }

    @ViewBuilder
    private func collectionContent(_ collection: CollectionDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Value summary card
            if let summary = valueSummary {
                valueSummaryCard(summary)
                    .padding(.horizontal)
            }

            // Description
            if let description = collection.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            // Items
            VStack(alignment: .leading, spacing: 12) {
                Text("Items (\(collection.itemCount))")
                    .font(.headline)
                    .padding(.horizontal)

                if collection.items.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "No Items",
                        message: "Add items to your collection",
                        actionTitle: "Add Item"
                    ) {
                        showAddItemSheet = true
                    }
                    .frame(height: 200)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(collection.items) { item in
                            CollectionItemRow(item: item)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .padding(.vertical)
    }

    private func valueSummaryCard(_ summary: ValueSummary) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(summary.totalValue)")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Gain/Loss")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text("$\(summary.totalGainLoss)")
                        Text("(\(summary.gainLossPercent)%)")
                            .font(.caption)
                    }
                    .foregroundStyle(
                        summary.totalGainLoss.hasPrefix("-") ? .brandCrimson : .brandMint
                    )
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("Total Cost")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("$\(summary.totalCost)")
                        .font(.subheadline)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(summary.itemCount)")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func loadCollection() async {
        isLoading = true
        error = nil

        do {
            collection = try await CollectionService.shared.getCollection(id: collectionId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func loadValueSummary() async {
        do {
            valueSummary = try await CollectionService.shared.getCollectionValue(id: collectionId)
        } catch {
            // Non-critical, don't show error
        }
    }
}

struct CollectionItemRow: View {
    let item: CollectionItem

    var body: some View {
        HStack(spacing: 12) {
            // Image
            if let imageUrl = item.image ?? item.priceGuideItem?.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImageView(url: url)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let grade = item.grade {
                    HStack(spacing: 4) {
                        if let company = item.gradeCompany {
                            Text(company)
                        }
                        Text(grade)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if let currentValue = item.currentValue {
                    Text("$\(currentValue)")
                        .font(.subheadline)
                        .foregroundStyle(.brandMint)
                }
            }

            Spacer()

            if let purchasePrice = item.purchasePrice {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Cost")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("$\(purchasePrice)")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct AddCollectionItemSheet: View {
    let collectionId: Int
    var onAdded: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var searchResults: [PriceGuideItem] = []
    @State private var selectedItem: PriceGuideItem?
    @State private var customName = ""
    @State private var grade = ""
    @State private var gradeCompany = "PSA"
    @State private var purchasePrice = ""
    @State private var notes = ""
    @State private var isLoading = false
    @State private var error: String?

    let gradeCompanies = ["PSA", "BGS", "CGC", "CBCS", "Other"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Find Item") {
                    HStack {
                        TextField("Search price guide...", text: $searchText)
                        Button {
                            Task { await search() }
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }

                    if !searchResults.isEmpty {
                        ForEach(searchResults) { item in
                            Button {
                                selectedItem = item
                                searchResults = []
                            } label: {
                                HStack {
                                    Text(item.name)
                                    Spacer()
                                    if selectedItem?.id == item.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.brandCyan)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }

                    if let selected = selectedItem {
                        HStack {
                            Text("Selected:")
                            Text(selected.name)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.brandMint)
                    }
                }

                Section("Or Enter Custom Name") {
                    TextField("Item name", text: $customName)
                }

                Section("Details") {
                    Picker("Grading Company", selection: $gradeCompany) {
                        ForEach(gradeCompanies, id: \.self) { company in
                            Text(company).tag(company)
                        }
                    }

                    TextField("Grade (e.g., 9.5, 10)", text: $grade)
                        .keyboardType(.decimalPad)

                    HStack {
                        Text("$")
                        TextField("Purchase Price", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        Task { await addItem() }
                    }
                    .disabled((selectedItem == nil && customName.isEmpty) || isLoading)
                }
            }
        }
    }

    private func search() async {
        guard !searchText.isEmpty else { return }

        do {
            let response = try await PriceGuideService.shared.getItems(search: searchText)
            searchResults = Array(response.results.prefix(5))
        } catch {
            // Ignore search errors
        }
    }

    private func addItem() async {
        isLoading = true
        error = nil

        do {
            _ = try await CollectionService.shared.addItemToCollection(
                collectionId: collectionId,
                priceGuideItemId: selectedItem?.id,
                customName: customName.isEmpty ? nil : customName,
                grade: grade.isEmpty ? nil : grade,
                gradeCompany: grade.isEmpty ? nil : gradeCompany,
                certNumber: nil,
                purchasePrice: purchasePrice.isEmpty ? nil : purchasePrice,
                purchaseDate: nil,
                notes: notes.isEmpty ? nil : notes
            )
            onAdded()
            dismiss()
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = "Failed to add item"
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(collectionId: 1)
    }
}

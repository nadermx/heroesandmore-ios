import SwiftUI

struct CreateListingView: View {
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var shippingPrice = ""
    @State private var selectedCategory: Category?
    @State private var condition = "Good"
    @State private var listingType = "fixed"
    @State private var allowOffers = false

    @State private var categories: [Category] = []
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var error: String?
    @State private var createdListing: Listing?
    @State private var showSuccess = false

    let conditions = ["Mint", "Near Mint", "Excellent", "Good", "Fair", "Poor"]

    var isValid: Bool {
        !title.isEmpty && !price.isEmpty && selectedCategory != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Title", text: $title)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    HStack {
                        Text("$")
                        TextField("Price", text: $price)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Category & Condition") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select a category").tag(nil as Category?)
                        ForEach(categories) { category in
                            Text(category.name).tag(category as Category?)
                        }
                    }

                    Picker("Condition", selection: $condition) {
                        ForEach(conditions, id: \.self) { condition in
                            Text(condition).tag(condition)
                        }
                    }
                }

                Section("Listing Type") {
                    Picker("Type", selection: $listingType) {
                        Text("Fixed Price").tag("fixed")
                        Text("Auction").tag("auction")
                    }
                    .pickerStyle(.segmented)

                    if listingType == "fixed" {
                        Toggle("Allow Offers", isOn: $allowOffers)
                    }
                }

                Section("Shipping") {
                    HStack {
                        Text("$")
                        TextField("Shipping price (empty = free)", text: $shippingPrice)
                            .keyboardType(.decimalPad)
                    }
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await createListing() }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Listing")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .navigationTitle("Sell")
            .task {
                await loadCategories()
            }
            .alert("Listing Created", isPresented: $showSuccess) {
                Button("OK") {
                    resetForm()
                }
            } message: {
                Text("Your listing has been created successfully.")
            }
        }
    }

    private func loadCategories() async {
        do {
            categories = try await CategoryService.shared.getCategories()
        } catch {
            // Silently fail — user can still type
        }
    }

    private func createListing() async {
        guard let category = selectedCategory else { return }
        isSubmitting = true
        error = nil

        do {
            let listing = try await MarketplaceService.shared.createListing(
                title: title,
                description: description,
                price: price,
                categoryId: category.id,
                listingType: listingType,
                condition: condition.lowercased().replacingOccurrences(of: " ", with: "_")
            )
            createdListing = listing
            showSuccess = true
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = "Failed to create listing. Please try again."
        }

        isSubmitting = false
    }

    private func resetForm() {
        title = ""
        description = ""
        price = ""
        shippingPrice = ""
        selectedCategory = nil
        condition = "Good"
        listingType = "fixed"
        allowOffers = false
        createdListing = nil
    }
}

#Preview {
    CreateListingView()
}

import SwiftUI

struct WishlistsView: View {
    @State private var wishlists: [Wishlist] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showCreateSheet = false

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadWishlists() }
                }
            } else if wishlists.isEmpty {
                EmptyStateView(
                    icon: "list.star",
                    title: "No Wishlists",
                    message: "Create a wishlist to track items you want",
                    actionTitle: "Create Wishlist"
                ) {
                    showCreateSheet = true
                }
            } else {
                List(wishlists) { wishlist in
                    NavigationLink {
                        WishlistDetailView(wishlistId: wishlist.id)
                    } label: {
                        WishlistRow(wishlist: wishlist)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Wishlists")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await loadWishlists()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateWishlistSheet {
                Task { await loadWishlists() }
            }
        }
    }

    private func loadWishlists() async {
        isLoading = true
        error = nil

        do {
            let response = try await AlertService.shared.getWishlists()
            wishlists = response.results
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct WishlistRow: View {
    let wishlist: Wishlist

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(wishlist.name)
                        .fontWeight(.medium)

                    if !wishlist.isPublic {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("\(wishlist.itemCount) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
    }
}

struct WishlistDetailView: View {
    let wishlistId: Int

    @State private var wishlist: Wishlist?
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadWishlist() }
                }
            } else if let wishlist = wishlist {
                List {
                    if let items = wishlist.items {
                        ForEach(items) { item in
                            WishlistItemRow(item: item)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(wishlist?.name ?? "Wishlist")
        .task {
            await loadWishlist()
        }
    }

    private func loadWishlist() async {
        isLoading = true
        error = nil

        do {
            wishlist = try await AlertService.shared.getWishlist(id: wishlistId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct WishlistItemRow: View {
    let item: WishlistItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .fontWeight(.medium)

                if let maxPrice = item.maxPrice {
                    Text("Max: $\(maxPrice)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if item.matchingListingsCount > 0 {
                    Text("\(item.matchingListingsCount) matching listings")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            Spacer()
        }
    }
}

struct CreateWishlistSheet: View {
    var onCreated: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var isPublic = false
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Wishlist Name", text: $name)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("Public Wishlist", isOn: $isPublic)
                }
            }
            .navigationTitle("New Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task { await createWishlist() }
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
        }
    }

    private func createWishlist() async {
        isLoading = true

        do {
            _ = try await AlertService.shared.createWishlist(
                name: name,
                description: description.isEmpty ? nil : description,
                isPublic: isPublic
            )
            onCreated()
            dismiss()
        } catch {}

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        WishlistsView()
    }
}

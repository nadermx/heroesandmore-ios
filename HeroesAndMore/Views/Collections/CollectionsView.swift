import SwiftUI

struct CollectionsView: View {
    @State private var collections: [Collection] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView()
                } else if let error = error {
                    ErrorView(message: error) {
                        Task { await loadCollections() }
                    }
                } else if collections.isEmpty {
                    EmptyStateView(
                        icon: "square.grid.2x2",
                        title: "No Collections",
                        message: "Create a collection to track your items",
                        actionTitle: "Create Collection"
                    ) {
                        showCreateSheet = true
                    }
                } else {
                    collectionsList
                }
            }
            .navigationTitle("Collections")
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
                await loadCollections()
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateCollectionSheet {
                    Task { await loadCollections() }
                }
            }
        }
    }

    private var collectionsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(collections) { collection in
                    NavigationLink {
                        CollectionDetailView(collectionId: collection.id)
                    } label: {
                        CollectionCard(collection: collection)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .refreshable {
            await loadCollections()
        }
    }

    private func loadCollections() async {
        isLoading = true
        error = nil

        do {
            let response = try await CollectionService.shared.getMyCollections()
            collections = response.results
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct CollectionCard: View {
    let collection: Collection

    var body: some View {
        HStack(spacing: 16) {
            // Cover image
            if let coverImage = collection.coverImage, let url = URL(string: coverImage) {
                AsyncImageView(url: url)
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "photo.stack")
                            .foregroundStyle(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(collection.name)
                        .font(.headline)

                    if !collection.isPublic {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("\(collection.itemCount) items")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let totalValue = collection.totalValue {
                    Text("Value: $\(totalValue)")
                        .font(.subheadline)
                        .foregroundStyle(.brandMint)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct CreateCollectionSheet: View {
    var onCreated: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var isPublic = false
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Collection Name", text: $name)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("Public Collection", isOn: $isPublic)
                } footer: {
                    Text("Public collections can be viewed by other users")
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task { await createCollection() }
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
        }
    }

    private func createCollection() async {
        isLoading = true
        error = nil

        do {
            _ = try await CollectionService.shared.createCollection(
                name: name,
                description: description.isEmpty ? nil : description,
                isPublic: isPublic
            )
            onCreated()
            dismiss()
        } catch let apiError as APIError {
            error = apiError.errorDescription
        } catch {
            self.error = "Failed to create collection"
        }

        isLoading = false
    }
}

#Preview {
    CollectionsView()
}

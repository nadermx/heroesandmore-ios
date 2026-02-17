import SwiftUI

struct SavedSearchesView: View {
    @State private var savedSearches: [SavedSearch] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadSavedSearches() }
                }
            } else if savedSearches.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Saved Searches",
                    message: "Save searches to get notified of new listings"
                )
            } else {
                List {
                    ForEach(savedSearches) { search in
                        SavedSearchRow(search: search)
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                try? await AlertService.shared.deleteSavedSearch(id: savedSearches[index].id)
                            }
                            await loadSavedSearches()
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Saved Searches")
        .task {
            await loadSavedSearches()
        }
    }

    private func loadSavedSearches() async {
        isLoading = true
        error = nil

        do {
            let response = try await AlertService.shared.getSavedSearches()
            savedSearches = response.results
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct SavedSearchRow: View {
    let search: SavedSearch

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(search.name)
                    .fontWeight(.medium)

                Text("\"\(search.query)\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    if search.notifyEmail {
                        Label("Email", systemImage: "envelope")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if search.notifyPush {
                        Label("Push", systemImage: "bell")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if search.newResultsCount > 0 {
                Text("\(search.newResultsCount) new")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandCyan.opacity(0.2))
                    .foregroundStyle(.brandCyan)
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SavedSearchesView()
    }
}

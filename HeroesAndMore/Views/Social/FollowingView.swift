import SwiftUI

struct FollowingView: View {
    @State private var selectedTab = 0
    @State private var following: [FollowUser] = []
    @State private var followers: [FollowUser] = []
    @State private var isLoading = true
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            Picker("Tab", selection: $selectedTab) {
                Text("Following").tag(0)
                Text("Followers").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            .onChange(of: selectedTab) {
                Task { await loadUsers() }
            }

            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(message: error) {
                    Task { await loadUsers() }
                }
            } else {
                let users = selectedTab == 0 ? following : followers

                if users.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        title: selectedTab == 0 ? "Not Following Anyone" : "No Followers",
                        message: selectedTab == 0 ? "Follow users to see their activity" : "Share your profile to get followers"
                    )
                } else {
                    List(users) { user in
                        FollowUserRow(user: user) {
                            Task { await loadUsers() }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Connections")
        .task {
            await loadUsers()
        }
    }

    private func loadUsers() async {
        isLoading = true
        error = nil

        do {
            if selectedTab == 0 {
                let response = try await SocialService.shared.getFollowing()
                following = response.results
            } else {
                let response = try await SocialService.shared.getFollowers()
                followers = response.results
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

struct FollowUserRow: View {
    let user: FollowUser
    var onAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(url: user.avatarUrl, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .fontWeight(.medium)

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                Task {
                    // Note: Would need user ID, not username
                    // Simplified for example
                    onAction()
                }
            } label: {
                Text(user.isFollowing ? "Following" : "Follow")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .tint(user.isFollowing ? .secondary : .blue)
        }
    }
}

#Preview {
    NavigationStack {
        FollowingView()
    }
}

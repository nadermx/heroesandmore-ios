import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showEditProfile = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                if let profile = authManager.currentUser {
                    profileHeader(profile)
                }

                // Quick actions
                Section {
                    NavigationLink {
                        MyOrdersView()
                    } label: {
                        Label("My Orders", systemImage: "bag")
                    }

                    NavigationLink {
                        MyOffersView()
                    } label: {
                        Label("My Offers", systemImage: "hand.raised")
                    }

                    NavigationLink {
                        SavedListingsView()
                    } label: {
                        Label("Saved Listings", systemImage: "heart")
                    }

                    NavigationLink {
                        NotificationsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                // Alerts & Wishlists
                Section("Alerts") {
                    NavigationLink {
                        WishlistsView()
                    } label: {
                        Label("Wishlists", systemImage: "list.star")
                    }

                    NavigationLink {
                        SavedSearchesView()
                    } label: {
                        Label("Saved Searches", systemImage: "magnifyingglass")
                    }

                    NavigationLink {
                        PriceAlertsView()
                    } label: {
                        Label("Price Alerts", systemImage: "bell.badge")
                    }
                }

                // Social
                Section("Social") {
                    NavigationLink {
                        MessagesView()
                    } label: {
                        Label("Messages", systemImage: "message")
                    }

                    NavigationLink {
                        FollowingView()
                    } label: {
                        Label("Following", systemImage: "person.2")
                    }

                    NavigationLink {
                        ForumsView()
                    } label: {
                        Label("Forums", systemImage: "bubble.left.and.bubble.right")
                    }
                }

                // Settings
                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }

                    Button(role: .destructive) {
                        authManager.logout()
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Text("Edit")
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .refreshable {
                await authManager.fetchCurrentUser()
            }
        }
    }

    @ViewBuilder
    private func profileHeader(_ profile: Profile) -> some View {
        Section {
            HStack(spacing: 16) {
                AvatarView(url: profile.avatarUrl, size: 70)

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.username)
                        .font(.title2)
                        .fontWeight(.bold)

                    if profile.isSellerVerified {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.blue)
                            Text("Verified Seller")
                                .font(.caption)
                        }
                    }

                    if profile.ratingCount > 0 {
                        RatingView(rating: profile.rating, count: profile.ratingCount)
                    }
                }
            }
            .padding(.vertical, 8)

            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Stats
            HStack {
                statItem(value: "\(profile.totalSalesCount)", label: "Sales")
                Spacer()
                statItem(value: profile.sellerTier?.capitalized ?? "Free", label: "Tier")
                Spacer()
                statItem(value: profile.location ?? "--", label: "Location")
            }
            .padding(.vertical, 4)
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var bio: String = ""
    @State private var location: String = ""
    @State private var website: String = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Details") {
                    TextField("Location", text: $location)
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await saveProfile() }
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                if let profile = authManager.currentUser {
                    bio = profile.bio ?? ""
                    location = profile.location ?? ""
                    website = profile.website ?? ""
                }
            }
        }
    }

    private func saveProfile() async {
        isLoading = true

        let success = await authManager.updateProfile(
            bio: bio.isEmpty ? nil : bio,
            location: location.isEmpty ? nil : location,
            website: website.isEmpty ? nil : website
        )

        if success {
            dismiss()
        }

        isLoading = false
    }
}

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showChangePassword = false

    var body: some View {
        List {
            Section("Account") {
                if let profile = authManager.currentUser {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(profile.email)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Username")
                        Spacer()
                        Text(profile.username)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Change Password") {
                    showChangePassword = true
                }
            }

            Section("Notifications") {
                if let profile = authManager.currentUser {
                    Toggle("Email Notifications", isOn: .constant(profile.emailNotifications))
                }
            }

            Section("Privacy") {
                if let profile = authManager.currentUser {
                    Toggle("Public Profile", isOn: .constant(profile.isPublic))
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("\(Config.appVersion) (\(Config.buildNumber))")
                        .foregroundStyle(.secondary)
                }

                Link("Terms of Service", destination: URL(string: "https://heroesandmore.com/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://heroesandmore.com/privacy")!)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Current Password", text: $oldPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task { await changePassword() }
                    }
                    .disabled(oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || isLoading)
                }
            }
        }
    }

    private func changePassword() async {
        if newPassword != confirmPassword {
            error = "Passwords don't match"
            return
        }

        isLoading = true
        error = nil

        let success = await authManager.changePassword(
            oldPassword: oldPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword
        )

        if success {
            dismiss()
        } else {
            error = authManager.error
        }

        isLoading = false
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}

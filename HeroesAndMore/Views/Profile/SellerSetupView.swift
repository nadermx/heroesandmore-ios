import SwiftUI
import SafariServices

struct SellerSetupView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showSafari = false

    private let sellerSetupURL = URL(string: "https://heroesandmore.com/marketplace/seller-setup/")!

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero section
                VStack(spacing: 16) {
                    Image(systemName: "storefront")
                        .font(.system(size: 60))
                        .foregroundStyle(.brandCrimson)

                    Text("Start Selling on Heroes & More")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Set up your seller account to list collectibles, reach thousands of collectors, and get paid securely through Stripe.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Benefits cards
                VStack(spacing: 12) {
                    benefitRow(
                        icon: "dollarsign.circle.fill",
                        iconColor: .brandMint,
                        title: "Secure Payments",
                        description: "Payments processed securely through Stripe. Funds deposited directly to your bank account."
                    )

                    benefitRow(
                        icon: "person.2.fill",
                        iconColor: .brandCyan,
                        title: "Reach Collectors",
                        description: "Access a community of thousands of collectors looking for items like yours."
                    )

                    benefitRow(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .brandGold,
                        title: "Seller Tools",
                        description: "Bulk import, inventory management, analytics, and more to grow your business."
                    )

                    benefitRow(
                        icon: "shield.checkmark.fill",
                        iconColor: .brandGold,
                        title: "Trusted Seller Program",
                        description: "Build your reputation and earn reduced commissions with our Trusted Seller program."
                    )
                }

                // Tiers info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Seller Tiers")
                        .font(.headline)

                    tierRow(tier: "Starter", price: "Free", listings: "50 listings", commission: "12.95%")
                    tierRow(tier: "Basic", price: "$9.99/mo", listings: "200 listings", commission: "9.95%")
                    tierRow(tier: "Featured", price: "$29.99/mo", listings: "1,000 listings", commission: "7.95%")
                    tierRow(tier: "Premium", price: "$99.99/mo", listings: "Unlimited", commission: "5.95%")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // How it works
                VStack(alignment: .leading, spacing: 12) {
                    Text("How It Works")
                        .font(.headline)

                    stepRow(number: 1, text: "Tap the button below to start setup")
                    stepRow(number: 2, text: "Select your country and enter your details")
                    stepRow(number: 3, text: "Connect your bank account through Stripe")
                    stepRow(number: 4, text: "Start listing and selling!")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Setup button
                Button {
                    showSafari = true
                } label: {
                    Label("Set Up Seller Account", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)

                Text("You will be redirected to complete setup securely through Stripe.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Seller Setup")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSafari) {
            SafariView(url: sellerSetupURL)
                .ignoresSafeArea()
        }
    }

    private func benefitRow(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func tierRow(tier: String, price: String, listings: String, commission: String) -> some View {
        HStack {
            Text(tier)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 70, alignment: .leading)

            Text(price)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            Text(listings)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(commission)
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.brandCrimson)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Safari View Controller Wrapper

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false

        let safari = SFSafariViewController(url: url, configuration: configuration)
        safari.preferredControlTintColor = UIColor(red: 0.90, green: 0.22, blue: 0.27, alpha: 1.0)
        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SellerSetupView()
            .environmentObject(AuthManager())
    }
}

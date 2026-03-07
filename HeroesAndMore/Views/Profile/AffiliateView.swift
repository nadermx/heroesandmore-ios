import SwiftUI

struct AffiliateView: View {
    @State private var affiliate: Affiliate?
    @State private var referrals: [Referral] = []
    @State private var commissions: [AffiliateCommission] = []
    @State private var payouts: [AffiliatePayout] = []
    @State private var selectedTab = 0
    @State private var commissionFilter: String?
    @State private var paypalEmail = ""
    @State private var isLoading = true
    @State private var isJoining = false
    @State private var isSaving = false
    @State private var notAffiliate = false
    @State private var error: String?
    @State private var successMessage: String?

    var body: some View {
        Group {
            if isLoading && affiliate == nil {
                ProgressView("Loading...")
            } else if notAffiliate {
                joinView
            } else if let affiliate = affiliate {
                affiliateContent(affiliate)
            } else if let error = error {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") { Task { await loadDashboard() } }
                }
            }
        }
        .navigationTitle("Affiliate Program")
        .task { await loadDashboard() }
        .alert("Success", isPresented: .init(
            get: { successMessage != nil },
            set: { if !$0 { successMessage = nil } }
        )) {
            Button("OK") { successMessage = nil }
        } message: {
            if let msg = successMessage { Text(msg) }
        }
    }

    // MARK: - Join View

    private var joinView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundStyle(.brandCyan)
                    .padding(.top, 40)

                Text("Earn with our Affiliate Program")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Share your referral link and earn 2% commission on every sale from people you refer. Both buyers and sellers count!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    benefitRow("2% commission on all referred sales")
                    benefitRow("Lifetime referral attribution")
                    benefitRow("Monthly PayPal payouts")
                    benefitRow("Real-time dashboard & tracking")
                }
                .padding()

                if let error = error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button {
                    Task { await join() }
                } label: {
                    if isJoining {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Join Affiliate Program")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isJoining)
            }
            .padding()
        }
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - Main Content

    private func affiliateContent(_ affiliate: Affiliate) -> some View {
        VStack(spacing: 0) {
            Picker("Tab", selection: $selectedTab) {
                Text("Dashboard").tag(0)
                Text("Referrals").tag(1)
                Text("Commissions").tag(2)
                Text("Payouts").tag(3)
                Text("Settings").tag(4)
            }
            .pickerStyle(.segmented)
            .padding()

            switch selectedTab {
            case 0: dashboardView(affiliate)
            case 1: referralsView
            case 2: commissionsView
            case 3: payoutsView
            case 4: settingsView
            default: EmptyView()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            Task {
                switch newTab {
                case 1: await loadReferrals()
                case 2: await loadCommissions()
                case 3: await loadPayouts()
                default: break
                }
            }
        }
    }

    // MARK: - Dashboard

    private func dashboardView(_ affiliate: Affiliate) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statCard(title: "Total Earnings", value: "$\(affiliate.totalEarnings)")
                    statCard(title: "Pending", value: "$\(affiliate.pendingBalance)")
                    statCard(title: "Paid Out", value: "$\(affiliate.paidBalance)")
                    statCard(title: "Referrals", value: "\(affiliate.totalReferrals)")
                }

                // Referral link
                GroupBox("Your Referral Link") {
                    VStack(spacing: 12) {
                        HStack {
                            Text(affiliate.referralUrl)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = affiliate.referralUrl
                                successMessage = "Link copied!"
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                        }

                        HStack(spacing: 12) {
                            ShareLink(item: "Check out Heroes & More! \(affiliate.referralUrl)") {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // Referral code
                GroupBox {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Referral Code")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(affiliate.referralCode)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        Button {
                            UIPasteboard.general.string = affiliate.referralCode
                            successMessage = "Code copied!"
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
            }
            .padding()
        }
        .refreshable { await loadDashboard() }
    }

    private func statCard(title: String, value: String) -> some View {
        GroupBox {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Referrals

    private var referralsView: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if referrals.isEmpty {
                ContentUnavailableView {
                    Label("No Referrals", systemImage: "person.badge.plus")
                } description: {
                    Text("Share your referral link to start earning")
                }
            } else {
                List(referrals) { referral in
                    HStack {
                        Label(referral.referredUsername, systemImage: "person")
                        Spacer()
                        Text(referral.created)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .refreshable { await loadReferrals() }
            }
        }
    }

    // MARK: - Commissions

    private var commissionsView: some View {
        VStack(spacing: 0) {
            // Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("All", isSelected: commissionFilter == nil) {
                        commissionFilter = nil
                        Task { await loadCommissions() }
                    }
                    ForEach(["pending", "approved", "paid", "reversed"], id: \.self) { status in
                        filterChip(status.capitalized, isSelected: commissionFilter == status) {
                            commissionFilter = status
                            Task { await loadCommissions() }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if commissions.isEmpty {
                ContentUnavailableView {
                    Label("No Commissions", systemImage: "dollarsign.circle")
                } description: {
                    Text("Commissions appear when your referrals make purchases")
                }
            } else {
                List(commissions) { commission in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Order #\(commission.orderId)")
                                .fontWeight(.medium)
                            Spacer()
                            statusBadge(commission.status)
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(commission.commissionType.capitalized) referral")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("$\(commission.orderItemPrice) x \(commission.commissionRate)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("$\(commission.commissionAmount)")
                                .font(.headline)
                                .foregroundStyle(.brandCyan)
                        }

                        Text(commission.created)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .refreshable { await loadCommissions() }
            }
        }
    }

    // MARK: - Payouts

    private var payoutsView: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if payouts.isEmpty {
                ContentUnavailableView {
                    Label("No Payouts", systemImage: "banknote")
                } description: {
                    Text("Payouts are processed monthly for balances over $25")
                }
            } else {
                List(payouts) { payout in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("$\(payout.amount)")
                                .font(.headline)
                            Spacer()
                            statusBadge(payout.status)
                        }

                        Text("PayPal: \(payout.paypalEmail)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Period: \(payout.periodStart) - \(payout.periodEnd)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(payout.created)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .refreshable { await loadPayouts() }
            }
        }
    }

    // MARK: - Settings

    private var settingsView: some View {
        Form {
            Section {
                Text("Enter your PayPal email to receive affiliate payouts. Payouts are processed monthly for balances of $25 or more.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("PayPal Email", text: $paypalEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                if let error = error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button {
                    Task { await saveSettings() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save PayPal Email")
                    }
                }
                .disabled(isSaving || paypalEmail.trimmingCharacters(in: .whitespaces).isEmpty)
            } header: {
                Text("Payout Settings")
            }
        }
    }

    // MARK: - Helper Views

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.brandCyan : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .cornerRadius(4)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "pending", "processing": return .orange
        case "approved", "completed": return .blue
        case "paid": return .green
        case "reversed", "failed": return .red
        default: return .secondary
        }
    }

    // MARK: - Data Loading

    private func loadDashboard() async {
        isLoading = true
        error = nil
        do {
            let result = try await AffiliateService.shared.getDashboard()
            affiliate = result
            paypalEmail = result.paypalEmail
            notAffiliate = false
        } catch let apiError as APIError {
            if case .notFound = apiError {
                notAffiliate = true
            } else if case .httpError(let code, _) = apiError, code == 404 {
                notAffiliate = true
            } else {
                error = apiError.localizedDescription
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func join() async {
        isJoining = true
        error = nil
        do {
            let result = try await AffiliateService.shared.join()
            affiliate = result
            paypalEmail = result.paypalEmail
            notAffiliate = false
            successMessage = "Welcome to the affiliate program!"
        } catch {
            self.error = error.localizedDescription
        }
        isJoining = false
    }

    private func loadReferrals() async {
        isLoading = true
        do {
            let response = try await AffiliateService.shared.getReferrals()
            referrals = response.results
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func loadCommissions() async {
        isLoading = true
        do {
            let response = try await AffiliateService.shared.getCommissions(status: commissionFilter)
            commissions = response.results
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func loadPayouts() async {
        isLoading = true
        do {
            let response = try await AffiliateService.shared.getPayouts()
            payouts = response.results
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func saveSettings() async {
        let email = paypalEmail.trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty else {
            error = "Please enter a PayPal email address"
            return
        }

        isSaving = true
        error = nil
        do {
            let result = try await AffiliateService.shared.updateSettings(paypalEmail: email)
            affiliate = result
            paypalEmail = result.paypalEmail
            successMessage = "PayPal email saved"
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}

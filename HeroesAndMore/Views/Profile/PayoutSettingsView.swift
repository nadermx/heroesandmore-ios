import SwiftUI
import SafariServices

struct PayoutSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var paypalEmail = ""
    @State private var preferredMethod = "stripe"
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSafari = false

    private let stripeSetupURL = URL(string: "https://heroesandmore.com/marketplace/seller-setup/")!

    var body: some View {
        Form {
            // Preferred Payout Method
            Section {
                Picker("Preferred Method", selection: $preferredMethod) {
                    Text("Stripe").tag("stripe")
                    Text("PayPal").tag("paypal")
                }
                .pickerStyle(.segmented)
                .onChange(of: preferredMethod) { newValue in
                    savePreferredMethod(newValue)
                }
            } header: {
                Text("Preferred Payout Method")
            } footer: {
                if preferredMethod == "stripe" {
                    Text("Payouts will be sent to your bank account via Stripe.")
                } else {
                    Text("Payouts will be sent to your PayPal email address.")
                }
            }

            // PayPal Email
            Section {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundStyle(.secondary)
                    TextField("PayPal Email", text: $paypalEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Button {
                    savePaypalEmail()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Save PayPal Email")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isSaving || paypalEmail.trimmingCharacters(in: .whitespaces).isEmpty)
            } header: {
                Text("PayPal")
            } footer: {
                Text("Enter the email associated with your PayPal account to receive payouts.")
            }

            // Stripe Account
            Section {
                if authManager.currentUser?.stripeAccountComplete == true {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.brandMint)
                        Text("Stripe Connected")
                            .foregroundStyle(.brandMint)
                        Spacer()
                    }
                } else {
                    Button {
                        showSafari = true
                    } label: {
                        Label("Set Up Stripe Account", systemImage: "arrow.up.right.square")
                    }
                }
            } header: {
                Text("Stripe")
            } footer: {
                if authManager.currentUser?.stripeAccountComplete != true {
                    Text("Connect a Stripe account to receive bank payouts directly.")
                }
            }
        }
        .navigationTitle("Payout Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let user = authManager.currentUser {
                paypalEmail = user.paypalEmail ?? ""
                preferredMethod = user.preferredPayoutMethod ?? "stripe"
            }
        }
        .sheet(isPresented: $showSafari) {
            SafariView(url: stripeSetupURL)
                .ignoresSafeArea()
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(successMessage)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func savePaypalEmail() {
        let email = paypalEmail.trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty else { return }

        isSaving = true
        Task {
            let success = await authManager.updatePaypalEmail(email)
            isSaving = false
            if success {
                successMessage = "PayPal email saved"
                showSuccess = true
            } else {
                errorMessage = authManager.error ?? "Failed to save PayPal email"
                showError = true
            }
        }
    }

    private func savePreferredMethod(_ method: String) {
        if method == "paypal" && (authManager.currentUser?.paypalEmail ?? "").isEmpty && paypalEmail.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please add a PayPal email first"
            showError = true
            preferredMethod = "stripe"
            return
        }

        Task {
            let success = await authManager.updatePreferredPayoutMethod(method)
            if success {
                successMessage = "Preferred payout method updated"
                showSuccess = true
            } else {
                errorMessage = authManager.error ?? "Failed to update payout method"
                showError = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        PayoutSettingsView()
            .environmentObject(AuthManager())
    }
}

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @State private var showLogin = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 80))
                        .foregroundStyle(.brandCrimson)

                    Text("HeroesAndMore")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Collectibles Marketplace")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)

                // Tab picker
                Picker("Auth Mode", selection: $showLogin) {
                    Text("Login").tag(true)
                    Text("Register").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Form
                if showLogin {
                    LoginView()
                } else {
                    RegisterView()
                }

                Spacer()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    @FocusState private var focusedField: Field?

    enum Field {
        case username, password
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { login() }
            }
            .padding(.horizontal)

            if let error = authManager.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            Button(action: login) {
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Login")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(username.isEmpty || password.isEmpty || authManager.isLoading)
            .padding(.horizontal)

            Button("Forgot Password?") {
                showForgotPassword = true
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Divider
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                Text("or").font(.caption).foregroundStyle(.secondary)
                Rectangle().frame(height: 1).foregroundStyle(.quaternary)
            }
            .padding(.horizontal)

            // Sign in with Apple
            AppleSignInButton()
                .padding(.horizontal)
        }
        .padding(.top, 30)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

    private func login() {
        Task {
            _ = await authManager.login(username: username, password: password)
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case username, email, password, passwordConfirm
    }

    var passwordsMatch: Bool {
        !password.isEmpty && password == passwordConfirm
    }

    var isValid: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty && passwordsMatch
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .username)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .email }

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .passwordConfirm }

                SecureField("Confirm Password", text: $passwordConfirm)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .passwordConfirm)
                    .submitLabel(.go)
                    .onSubmit { register() }

                if !passwordConfirm.isEmpty && !passwordsMatch {
                    Text("Passwords don't match")
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                if let error = authManager.error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Button(action: register) {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Create Account")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isValid || authManager.isLoading)

                // Divider
                HStack {
                    Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                    Text("or").font(.caption).foregroundStyle(.secondary)
                    Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                }

                // Sign in with Apple
                AppleSignInButton()

                Text("By creating an account, you agree to our Terms of Service and Privacy Policy.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .padding(.top, 10)
    }

    private func register() {
        Task {
            _ = await authManager.register(
                username: username,
                email: email,
                password: password,
                passwordConfirm: passwordConfirm
            )
        }
    }
}

// MARK: - Apple Sign In

struct AppleSignInButton: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            handleResult(result)
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 50)
        .cornerRadius(8)
    }

    private func handleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                authManager.error = "Failed to get Apple credentials"
                return
            }

            let firstName = credential.fullName?.givenName ?? ""
            let lastName = credential.fullName?.familyName ?? ""

            Task {
                _ = await authManager.loginWithApple(
                    identityToken: identityToken,
                    firstName: firstName,
                    lastName: lastName
                )
            }

        case .failure(let error):
            // Don't show error for user cancellation
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                authManager.error = "Apple sign-in failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Forgot Password

struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var emailSent = false
    @State private var error: String?
    @FocusState private var emailFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if emailSent {
                    // Success state
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.brandCrimson)

                        Text("Check Your Email")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("If an account exists with **\(email)**, we've sent a password reset link. Check your inbox and spam folder.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.top, 8)
                    }
                    .padding(.top, 40)
                } else {
                    // Input state
                    VStack(spacing: 16) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 50))
                            .foregroundStyle(.brandCrimson)

                        Text("Reset Password")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)

                    TextField("Email address", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($emailFocused)
                        .submitLabel(.go)
                        .onSubmit { sendReset() }
                        .padding(.horizontal)

                    if let error = error {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    Button(action: sendReset) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Send Reset Link")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(email.isEmpty || isLoading)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear { emailFocused = true }
    }

    private func sendReset() {
        isLoading = true
        error = nil

        Task {
            let success = await authManager.requestPasswordReset(email: email)
            isLoading = false
            if success {
                emailSent = true
            } else {
                error = authManager.error ?? "Failed to send reset email"
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}

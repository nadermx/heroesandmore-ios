import SwiftUI

struct AuthView: View {
    @State private var showLogin = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)

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
                // TODO: Implement forgot password
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 30)
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

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}

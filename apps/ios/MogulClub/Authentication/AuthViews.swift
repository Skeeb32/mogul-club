import AuthenticationServices
import SwiftUI

struct AuthEntryView: View {
    @ObservedObject var manager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var screen: Screen = .menu
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var showPassword = false
    @State private var acceptedLegal = false
    @State private var notice: String?
    enum Screen { case menu, signIn, signUp, reset, verify }
    private var validForm: Bool {
        guard AuthValidation.email(email) else { return false }
        switch screen {
        case .signIn: return !password.isEmpty
        case .signUp: return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && AuthValidation.password(password) && password == confirmation && acceptedLegal
        case .reset: return true
        default: return false
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    MogulLogo(width: 215).padding(.top, 28)
                    Text(title).font(.largeTitle.weight(.semibold)).multilineTextAlignment(.center)
                    Text(subtitle).font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    if let setup = manager.setupMessage { Label(setup, systemImage: "wrench.and.screwdriver").font(.footnote).frame(maxWidth: .infinity, alignment: .leading).padding().background(.quaternary, in: RoundedRectangle(cornerRadius: 14)) }
                    if screen == .menu {
                        appleButton
                        providerButton("Continue with Google", icon: "g.circle") { Task { await manager.googleSignIn() } }
                            .disabled(manager.setupMessage != nil || manager.isWorking)
                        Divider().overlay(Text("or").font(.caption).padding(.horizontal, 10).background(.background)).padding(.vertical, 4)
                        Button { screen = .signIn } label: { Text("Continue with Email") }.buttonStyle(PrimaryAuthButton())
                        Button("Create an account") { screen = .signUp }.font(.subheadline.weight(.semibold))
                    } else if screen == .verify {
                        Label("Check your inbox", systemImage: "envelope.badge").font(.title3.weight(.semibold))
                        Text("Verify \(email) using the link we sent. Then return here to continue.").foregroundStyle(.secondary).multilineTextAlignment(.center)
                        Button("I verified my email") { Task { await manager.refreshVerification(); if manager.currentUser != nil { dismiss() } } }.buttonStyle(PrimaryAuthButton()).disabled(manager.isWorking)
                        Button("Resend verification email") { Task { await manager.resendVerification(); notice = "If the account is available, a new verification message has been sent." } }.disabled(manager.isWorking)
                        Button("Back to sign in") { screen = .signIn }
                    } else {
                        formFields
                        if screen == .signUp { legalAcknowledgment }
                        if screen == .signIn { Button("Forgot password?") { screen = .reset }.frame(maxWidth: .infinity, alignment: .trailing) }
                        Button(actionTitle) { Task { await submit() } }.buttonStyle(PrimaryAuthButton()).disabled(!validForm || manager.isWorking || manager.setupMessage != nil)
                        if screen == .signUp { Button("Already have an account? Sign In") { screen = .signIn } }
                        else if screen == .signIn { Button("Don't have an account? Sign Up") { screen = .signUp } }
                        else { Button("Back to sign in") { screen = .signIn } }
                    }
                    if manager.isWorking { ProgressView().accessibilityLabel("Signing in") }
                    if case .failed(let message) = manager.state { Text(message).font(.footnote).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("auth-error") }
                    if let notice { Text(notice).font(.footnote).foregroundStyle(.secondary).accessibilityIdentifier("auth-notice") }
                    legalLinks
                }.padding(24).frame(maxWidth: 480).frame(maxWidth: .infinity)
            }
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() }.accessibilityIdentifier("close-auth") } }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { if case .needsVerification(let address) = manager.state { email = address; screen = .verify } }
            .onChange(of: manager.currentUser) { _, value in if value != nil { dismiss() } }
            .onChange(of: manager.state) { _, value in if case .needsVerification(let address) = value { email = address; screen = .verify } }
        }
        .tint(ClubStyle.emerald)
    }
    private var title: String {
        switch screen { case .menu: "Welcome to Mogul Club"; case .signIn: "Welcome back"; case .signUp: "Create your account"; case .reset: "Reset your password"; case .verify: "Verify your email" }
    }
    private var subtitle: String {
        switch screen { case .menu: "A clearer perspective on real estate."; case .signIn: "Sign in to your Mogul Club account."; case .signUp: "Create a secure account to continue."; case .reset: "We’ll email you a secure password reset link."; case .verify: "One more step to secure your account." }
    }
    private var actionTitle: String { screen == .signIn ? "Sign In" : screen == .signUp ? "Create Account" : "Send Reset Link" }
    private var appleButton: some View {
        SignInWithAppleButton(.signIn, onRequest: manager.prepareApple) { result in Task { await manager.completeApple(result) } }
            .signInWithAppleButtonStyle(.black).frame(height: 54).clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(manager.setupMessage != nil || manager.isWorking).accessibilityIdentifier("sign-in-apple")
    }
    private func providerButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Label(title, systemImage: icon).font(.body.weight(.semibold)).frame(maxWidth: .infinity).frame(height: 54) }
            .buttonStyle(.bordered).clipShape(RoundedRectangle(cornerRadius: 14))
    }
    @ViewBuilder private var formFields: some View {
        if screen == .signUp { TextField("Full name", text: $name).textContentType(.name).textFieldStyle(AuthFieldStyle()).textInputAutocapitalization(.words) }
        TextField("Email address", text: $email).keyboardType(.emailAddress).textContentType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(AuthFieldStyle()).accessibilityIdentifier("auth-email")
        if screen != .reset {
            Group {
                if showPassword { TextField("Password", text: $password).textContentType(screen == .signUp ? .newPassword : .password) }
                else { SecureField("Password", text: $password).textContentType(screen == .signUp ? .newPassword : .password) }
            }.textFieldStyle(AuthFieldStyle()).overlay(alignment: .trailing) { Button(showPassword ? "Hide" : "Show") { showPassword.toggle() }.font(.caption).padding(.trailing, 14).accessibilityIdentifier("toggle-password") }
            if screen == .signUp {
                Text("Use at least 8 characters.").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                SecureField("Confirm password", text: $confirmation).textContentType(.newPassword).textFieldStyle(AuthFieldStyle()).accessibilityIdentifier("confirm-password")
                if !confirmation.isEmpty && password != confirmation { Text("Passwords do not match.").font(.caption).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading) }
            }
        }
    }
    private var legalAcknowledgment: some View {
        Toggle(isOn: $acceptedLegal) { Text("I agree to the Terms of Service and Privacy Policy.").font(.footnote) }.accessibilityIdentifier("legal-acknowledgment")
    }
    private var legalLinks: some View {
        HStack(spacing: 18) {
            Link("Privacy Policy", destination: URL(string: "https://app.mogul.com/privacy-policy")!)
            Link("Terms of Service", destination: URL(string: "https://app.mogul.com/terms-of-service")!)
        }.font(.footnote).foregroundStyle(.secondary)
    }
    private func submit() async {
        notice = nil
        switch screen {
        case .signIn: await manager.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
        case .signUp: await manager.createAccount(name: name, email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
        case .reset:
            await manager.sendPasswordReset(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            if case .failed = manager.state {} else { notice = "If an account uses this email, we sent a password reset link." }
        default: break
        }
    }
}
struct AuthAccountSection: View {
    @ObservedObject var manager: AuthManager
    var onSignedOut: () -> Void = {}
    @State private var showingAuth = false
    @State private var showingDelete = false
    @State private var editingName = false
    @State private var name = ""
    var body: some View {
        Group {
            if let profile = manager.currentUser {
                Section("Signed in") {
                    LabeledContent("Name", value: profile.displayName)
                    LabeledContent("Email", value: profile.email)
                    LabeledContent("Verification", value: profile.emailVerified ? "Verified" : "Pending")
                    LabeledContent("Provider", value: profile.provider)
                    Button("Edit display name") { name = profile.displayName; editingName = true }
                    Button("Sign Out", role: .destructive) { manager.signOut(); onSignedOut() }.accessibilityIdentifier("sign-out")
                    Button("Delete My Account", role: .destructive) { showingDelete = true }
                }
                .alert("Edit display name", isPresented: $editingName) {
                    TextField("Name", text: $name)
                    Button("Save") { Task { await manager.updateDisplayName(name) } }
                    Button("Cancel", role: .cancel) { }
                }
                .confirmationDialog("Delete your Mogul Club account?", isPresented: $showingDelete, titleVisibility: .visible) {
                    Button("Delete Account", role: .destructive) { Task { await manager.deleteAccount() } }
                    Button("Cancel", role: .cancel) { }
                } message: { Text("This permanently removes your Firebase sign-in account. You may be asked to sign in again first. This demo has no associated investor records.") }
            } else {
                Section("Mogul Club account") {
                    Text("Sign in to verify your identity. Property discovery remains a synthetic demonstration.").font(.subheadline).foregroundStyle(.secondary)
                    Button("Sign In or Create Account") { showingAuth = true }.accessibilityIdentifier("open-auth")
                }
                .sheet(isPresented: $showingAuth) { AuthEntryView(manager: manager) }
            }
        }
    }
}
private struct AuthFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.padding(.horizontal, 14).frame(minHeight: 52).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
private struct PrimaryAuthButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.body.weight(.semibold)).foregroundStyle(.white).frame(maxWidth: .infinity).frame(minHeight: 54).background(ClubStyle.emerald.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 14))
    }
}

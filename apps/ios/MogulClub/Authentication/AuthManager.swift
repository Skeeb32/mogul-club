import AuthenticationServices
import Combine
import CryptoKit
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseCore
import Foundation
@preconcurrency import GoogleSignIn
import Security
import SwiftUI
import UIKit

struct UserProfile: Equatable, Identifiable {
    let id: String
    var displayName: String
    let email: String
    let emailVerified: Bool
    var provider: String
    var role: String
}
enum AuthState: Equatable {
    case restoring
    case signedOut
    case needsVerification(String)
    case authenticated(UserProfile)
    case failed(String)
}
enum AuthConfiguration {
    static var isReady: Bool { guard let app = FirebaseApp.app() else { return false }; return app.options.apiKey != nil }
    static func configure() {
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else { return }
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
    }
}
@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var state: AuthState = .restoring
    @Published private(set) var isWorking = false
    private var listener: AuthStateDidChangeListenerHandle?
    private var rawNonce: String?
    init() {
        AuthConfiguration.configure()
        guard AuthConfiguration.isReady else { state = .signedOut; return }
        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.receive(user) }
        }
    }
    deinit { if let listener { Auth.auth().removeStateDidChangeListener(listener) } }
    var currentUser: UserProfile? { if case .authenticated(let profile) = state { return profile }; return nil }
    var setupMessage: String? { AuthConfiguration.isReady ? nil : "Authentication is not configured yet. Add the Firebase configuration file and enable providers using the setup guide." }
    func signIn(email: String, password: String) async { await run { try await Auth.auth().signIn(withEmail: email, password: password) } }
    func createAccount(name: String, email: String, password: String) async {
        await run {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest(); change.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            try await change.commitChanges(); try await result.user.sendEmailVerification()
            self.state = .needsVerification(email)
        }
    }
    func sendPasswordReset(email: String) async { await run { try await Auth.auth().sendPasswordReset(withEmail: email) } }
    func resendVerification() async { await run { guard let user = Auth.auth().currentUser else { throw AuthError.signedOut }; try await user.sendEmailVerification() } }
    func refreshVerification() async { await run { try await Auth.auth().currentUser?.reload(); self.receive(Auth.auth().currentUser) } }
    func signOut() { do { try Auth.auth().signOut(); state = .signedOut } catch { state = .failed(Self.message(error)) } }
    func updateDisplayName(_ name: String) async {
        await run { guard let user = Auth.auth().currentUser else { throw AuthError.signedOut }; let request = user.createProfileChangeRequest(); request.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines); try await request.commitChanges(); self.receive(user) }
    }
    func deleteAccount() async { await run { guard let user = Auth.auth().currentUser else { throw AuthError.signedOut }; try await user.delete(); self.state = .signedOut } }
    func googleSignIn() async {
        await run {
            guard let clientID = FirebaseApp.app()?.options.clientID,
                  let presenter = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap(\.windows).first(where: \.isKeyWindow)?.rootViewController else { throw AuthError.setup }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else { throw AuthError.identityToken }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            _ = try await Auth.auth().signIn(with: credential)
        }
    }
    func prepareApple(_ request: ASAuthorizationAppleIDRequest) {
        guard let nonce = Self.randomNonce() else { state = .failed("Could not prepare secure Apple sign-in. Try again."); return }
        rawNonce = nonce; request.requestedScopes = [.fullName, .email]; request.nonce = Self.sha256(nonce)
    }
    func completeApple(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }; state = .failed(Self.message(error))
        case .success(let authorization):
            guard let apple = authorization.credential as? ASAuthorizationAppleIDCredential, let token = apple.identityToken, let idToken = String(data: token, encoding: .utf8), let nonce = rawNonce else { state = .failed("Apple did not return a usable identity token."); return }
            rawNonce = nil
            await run {
                let credential = OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: nonce, fullName: apple.fullName)
                let result = try await Auth.auth().signIn(with: credential)
                if let fullName = apple.fullName, result.user.displayName == nil {
                    let change = result.user.createProfileChangeRequest()
                    change.displayName = PersonNameComponentsFormatter.localizedString(from: fullName, style: .default)
                    try await change.commitChanges()
                }
            }
        }
    }
    private func run(_ operation: () async throws -> Void) async {
        guard AuthConfiguration.isReady else { state = .failed("Authentication setup is required. See the Firebase setup guide."); return }
        if case .failed = state { state = .signedOut }
        isWorking = true; defer { isWorking = false }
        do { try await operation() } catch { state = .failed(Self.message(error)) }
    }
    private func receive(_ user: User?) {
        guard let user else { if case .needsVerification = state { return }; state = .signedOut; return }
        if !user.isEmailVerified, user.providerData.contains(where: { $0.providerID == "password" }) { state = .needsVerification(user.email ?? ""); return }
        let providers = user.providerData.map(\.providerID).joined(separator: ", ")
        state = .authenticated(UserProfile(id: user.uid, displayName: user.displayName ?? "Mogul member", email: user.email ?? "", emailVerified: user.isEmailVerified, provider: providers.isEmpty ? "Unknown" : providers, role: "user"))
    }
    private static func message(_ error: Error) -> String {
        let ns = error as NSError
        if ns.domain == AuthErrorDomain {
            switch AuthErrorCode.Code(rawValue: ns.code) {
            case .wrongPassword, .userNotFound, .invalidCredential: return "Email or password is incorrect. Check your details and try again."
            case .emailAlreadyInUse: return "An account already uses this email. Try signing in instead."
            case .weakPassword: return "Choose a stronger password with at least eight characters."
            case .networkError: return "Could not reach the sign-in service. Check your connection and try again."
            case .tooManyRequests: return "Too many attempts. Wait a little while, then try again."
            case .requiresRecentLogin: return "For your security, sign in again before completing this action."
            case .userDisabled: return "This account is disabled. Contact support for help."
            default: break
            }
        }
        if error is CancellationError { return "Sign-in was cancelled." }
        return "We couldn't complete that request. Check your connection and try again."
    }
    private static func randomNonce() -> String? {
        let chars = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { return nil }
        return String(bytes.map { chars[Int($0) % chars.count] })
    }
    private static func sha256(_ value: String) -> String { SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined() }
}
enum AuthError: Error { case setup, identityToken, signedOut }
enum AuthValidation {
    static func email(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.range(of: #"^[A-Z0-9a-z.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$"#, options: .regularExpression) != nil
    }
    static func password(_ value: String) -> Bool { value.count >= 8 }
}

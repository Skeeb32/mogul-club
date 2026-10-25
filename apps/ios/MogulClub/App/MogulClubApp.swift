import SwiftUI
import GoogleSignIn

@main
struct MogulClubApp: App {
    init() {
        #if DEBUG
        // Reset persisted state without forcing a read-only UserDefaults argument-domain value.
        if ProcessInfo.processInfo.arguments.contains("--ui-reset-welcome") {
            UserDefaults.standard.set(false, forKey: "hasSeenDemoWelcome")
        } else if ProcessInfo.processInfo.arguments.contains("--ui-skip-welcome") {
            UserDefaults.standard.set(true, forKey: "hasSeenDemoWelcome")
        }
        #endif
    }
    var body: some Scene { WindowGroup { RootView() } }
}
struct RootView: View {
    @AppStorage("hasSeenDemoWelcome") private var welcomed = false
    @StateObject private var auth = AuthManager()
    @State private var showingAuth = false
    @State private var showingAccount = false
    var body: some View {
        if welcomed {
            TabView {
                DiscoverView(api: APIClient.development) { showingAccount = true }
                    .tabItem { Label("Properties", systemImage: "house") }
                ClubsView(onAccount: { showingAccount = true })
                    .tabItem { Label("Clubs", systemImage: "person.3") }
                PortfolioView(onAccount: { showingAccount = true })
                    .tabItem { Label("Portfolio", systemImage: "chart.pie") }
                AnalysisView(onAccount: { showingAccount = true })
                    .tabItem { Label("Analysis", systemImage: "chart.xyaxis.line") }
            }.sheet(isPresented: $showingAuth) { AuthEntryView(manager: auth) }
            .sheet(isPresented: $showingAccount) { AccountView(auth: auth) { welcomed = false } }
            .onOpenURL { url in _ = GIDSignIn.sharedInstance.handle(url) }
            .onChange(of: auth.currentUser) { _, profile in if profile != nil { welcomed = true } }
            .onChange(of: auth.state) { _, state in if case .needsVerification = state { showingAuth = true } }
            .tint(ClubStyle.emerald)
        } else {
            ScrollView {
              VStack(alignment: .leading, spacing: 24) {
                MogulLogo(width: 260).padding(.vertical, 16)
                Text("Real estate.\nA clearer perspective.").font(.largeTitle.weight(.semibold))
                Text("Explore the foundations of property investing through a read-only demonstration.").font(.title3).foregroundStyle(.secondary)
                DemoNotice()
              }.padding(24)
            }.safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Button { welcomed = true } label: { Text("Explore demo").font(.headline).frame(maxWidth: .infinity).padding(8) }
                        .buttonStyle(.borderedProminent).accessibilityIdentifier("explore-demo")
                    Button("Sign In or Create Account") { showingAuth = true }
                        .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.bottom, 18)
                        .accessibilityIdentifier("open-auth")
                }.padding(.horizontal, 24).padding(.top, 12).background(.background)
            }
            .sheet(isPresented: $showingAuth) { AuthEntryView(manager: auth) }
            .onOpenURL { url in _ = GIDSignIn.sharedInstance.handle(url) }
            .onChange(of: auth.currentUser) { _, profile in if profile != nil { welcomed = true } }
            .onChange(of: auth.state) { _, state in if case .needsVerification = state { showingAuth = true } }
            .tint(ClubStyle.emerald)
        }
    }
}

private struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var auth: AuthManager
    let showWelcome: () -> Void
    var body: some View {
        NavigationStack {
            List {
                HStack(spacing: 16) {
                    Image("MogulProfile").resizable().scaledToFit()
                        .frame(width: 80, height: 80).clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(auth.currentUser?.displayName ?? "Mogul Club").font(.title2.weight(.semibold))
                        Text(auth.currentUser == nil ? "Demo guest" : "Verified account").font(.subheadline).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 8)
                DemoNotice()
                AuthAccountSection(manager: auth, onSignedOut: showWelcome)
                Section("Your account") { Text(auth.currentUser.map { "Signed in as \($0.email). The property library remains synthetic demonstration content." } ?? "You are browsing as a guest. Sign-in does not unlock investment features in this demo.") }
                Section("Privacy") { Text("When Firebase is configured, it handles account credentials and identity. This demo does not collect payment information. Searches are sent to the development API. No analytics SDK is installed.") }
                Section("Legal and support") { Text("This is a software demonstration, not an offer to invest. Approved terms, privacy policy and support contact must be supplied before release.") }
                Section("Development") { Button("Show welcome again", action: showWelcome) }
            }
            .navigationTitle("Account")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

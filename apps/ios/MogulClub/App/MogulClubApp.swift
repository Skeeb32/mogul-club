import SwiftUI

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
    var body: some View {
        if welcomed {
            TabView {
                DiscoverView(api: APIClient.development).tabItem { Label("Discover", systemImage: "house") }
                NavigationStack { UnavailableView(title: "No portfolio yet", message: "This demo does not create investments, ownership or balances.").navigationTitle("Portfolio") }.tabItem { Label("Portfolio", systemImage: "chart.bar") }
                NavigationStack { UnavailableView(title: "No documents yet", message: "Statements and tax documents will appear only after an authorized account and document workflow are available.").navigationTitle("Documents") }.tabItem { Label("Documents", systemImage: "doc.text") }
                NavigationStack {
                    List {
                        HStack(spacing: 16) {
                            Image("MogulProfile").resizable().scaledToFit()
                                .frame(width: 80, height: 80).clipShape(RoundedRectangle(cornerRadius: 16))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mogul Club").font(.title2.weight(.semibold))
                                Text("Demo guest").font(.subheadline).foregroundStyle(.secondary)
                            }
                        }.padding(.vertical, 8)
                        DemoNotice()
                        Section("Your account") { Text("You are browsing without an account. Sign-in and investor verification are not available yet.") }
                        Section("Privacy") { Text("This demo has no account creation or collection of identity or payment information. Searches are sent to the development API. No analytics SDK is installed.") }
                        Section("Legal and support") { Text("This is a software demonstration, not an offer to invest. Approved terms, privacy policy and support contact must be supplied before release.") }
                        Section("Development") { Button("Show welcome again") { welcomed = false } }
                    }.navigationTitle("Account")
                }.tabItem { Label("Account", systemImage: "person.crop.circle") }
            }.tint(ClubStyle.emerald)
        } else {
            ScrollView {
              VStack(alignment: .leading, spacing: 24) {
                MogulLogo(width: 260).padding(.vertical, 16)
                Text("Real estate.\nA clearer perspective.").font(.largeTitle.weight(.semibold))
                Text("Explore the foundations of property investing through a read-only demonstration.").font(.title3).foregroundStyle(.secondary)
                DemoNotice()
              }.padding(24)
            }.safeAreaInset(edge: .bottom) {
                Button { welcomed = true } label: { Text("Explore demo").font(.headline).frame(maxWidth: .infinity).padding(8) }
                    .buttonStyle(.borderedProminent).accessibilityIdentifier("explore-demo")
                    .padding(24).background(.background)
            }.tint(ClubStyle.emerald)
        }
    }
}

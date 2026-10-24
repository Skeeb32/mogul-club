import SwiftUI

enum ClubStyle {
    static let emerald = Color(red: 0.11, green: 0.37, blue: 0.28)
    static let space: CGFloat = 16
}
struct DemoNotice: View {
    var body: some View {
        Label("Demo · Synthetic data · Investing unavailable", systemImage: "info.circle")
            .font(.footnote).frame(maxWidth: .infinity, alignment: .leading)
            .padding(ClubStyle.space).background(Color(.secondarySystemBackground))
            .accessibilityIdentifier("demo-notice")
    }
}
struct UnavailableView: View {
    let title: String
    let message: String
    var body: some View { ContentUnavailableView(title, systemImage: "lock.shield", description: Text(message)) }
}

/// Displays the supplied artwork unchanged; crops only the surrounding canvas in layout.
struct MogulLogo: View {
    @Environment(\.colorScheme) private var colorScheme
    var width: CGFloat = 200
    var body: some View {
        let dark = colorScheme == .dark
        let sourceWidth: CGFloat = dark ? 1200 : 400
        let sourceHeight: CGFloat = dark ? 630 : 300
        let cropWidth: CGFloat = dark ? 1130 : 320
        let cropX: CGFloat = dark ? 25 : 40
        let cropY: CGFloat = dark ? 175 : 105
        Image(dark ? "MogulLogoDark" : "MogulLogoLight")
            .resizable()
            .frame(width: width * sourceWidth / cropWidth, height: width * sourceHeight / cropWidth)
            .offset(x: -width * cropX / cropWidth, y: -width * cropY / cropWidth)
            .frame(width: width, height: width * 0.28, alignment: .topLeading)
            .clipped()
            .blendMode(dark ? .screen : .multiply)
            .accessibilityLabel("Mogul")
            .accessibilityIdentifier("mogul-logo")
    }
}

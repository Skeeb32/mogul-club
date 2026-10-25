import SwiftUI

struct PropertyDetailView: View {
    let id: String
    let api: any PropertyServing
    @State private var property: Property?
    @State private var failed = false
    @State private var loading = true

    var body: some View {
        Group {
            if loading {
                ProgressView("Loading property…")
            } else if let property {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        DemoNotice().padding(.horizontal, 18)
                        DemoPropertyPhotography(property: property, height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .padding(.horizontal, 18)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(property.name).font(.title.weight(.bold))
                            Text("\(property.city), \(property.state)").font(.subheadline).foregroundStyle(.secondary)
                        }.padding(.horizontal, 18)
                        HStack(spacing: 10) {
                            DetailMetric(title: "Property type", value: property.propertyType, icon: "house")
                            DetailMetric(title: "Illustrative value", value: property.illustrativeValue, icon: "tag")
                        }.padding(.horizontal, 18)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Property overview").font(.headline)
                            HStack(spacing: 18) {
                                Label("\(property.bedrooms) bedrooms", systemImage: "bed.double")
                                Label("\(property.bathrooms) bathrooms", systemImage: "shower")
                            }.font(.subheadline).foregroundStyle(.secondary)
                            Label("\(property.areaSqFt.formatted()) sq ft", systemImage: "square.dashed")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text(property.summary).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(.background, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal, 18)
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Property analytics unavailable", systemImage: "chart.xyaxis.line").font(.headline)
                            Text("No verified rent, expenses, valuation, return projection or offering terms are available for synthetic demo properties.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(.background, in: RoundedRectangle(cornerRadius: 16)).padding(.horizontal, 18)
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                            Text("Source: \(property.source) · updated \(property.updatedAt.prefix(10))")
                        }.font(.caption).foregroundStyle(.secondary).padding(.horizontal, 20).padding(.bottom, 24)
                    }.padding(.top, 8)
                }
                .background(Color(.systemGroupedBackground))
            } else if failed {
                ContentUnavailableView {
                    Label("Property unavailable", systemImage: "wifi.exclamationmark")
                } description: { Text("The property could not be loaded from the API.") }
                actions: { Button("Try again") { Task { await load() } }.buttonStyle(.borderedProminent) }
            }
        }
        .navigationTitle("Property details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    @MainActor private func load() async {
        loading = true
        failed = false
        do { property = try await api.property(id: id) }
        catch { property = nil; failed = true }
        loading = false
    }
}

struct DemoPropertyPhotography: View {
    let property: Property
    var height: CGFloat

    private var imageURL: URL? {
        // Unsplash images are licensed for free use; these are presentation photography,
        // not photographs of the fictional demo records shown in the app.
        let photoID = property.id == "demo-cedar" ? "photo-1600607687939-ce8a6c25118c" : "photo-1600585154340-be6161a56a0c"
        return URL(string: "https://images.unsplash.com/\(photoID)?auto=format&fit=crop&w=1400&q=85")
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image): image.resizable().scaledToFill()
                case .empty, .failure:
                    ZStack {
                        LinearGradient(colors: [Color(red: 0.84, green: 0.88, blue: 0.84), Color(red: 0.70, green: 0.78, blue: 0.73)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: "house.lodge.fill").font(.system(size: 54, weight: .light)).foregroundStyle(.white.opacity(0.8))
                    }
                @unknown default: Color(.tertiarySystemGroupedBackground)
                }
            }
            .frame(maxWidth: .infinity).frame(height: height).clipped()
            LinearGradient(colors: [.clear, .black.opacity(0.52)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 8) {
                Text("SYNTHETIC DEMO PROPERTY")
                    .font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1)
                    .foregroundStyle(.white).padding(.horizontal, 10).padding(.vertical, 7)
                    .background(.black.opacity(0.52), in: Capsule())
                Label("Illustrative photo · not this property", systemImage: "photo")
                    .font(.caption.weight(.medium)).foregroundStyle(.white)
            }
            .padding(15)
        }
        .frame(height: height).accessibilityLabel("Illustrative property photography. Synthetic demo property.")
    }
}

private struct DetailMetric: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).minimumScaleFactor(0.8).lineLimit(1)
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.91, green: 0.95, blue: 0.92), in: RoundedRectangle(cornerRadius: 14))
    }
}

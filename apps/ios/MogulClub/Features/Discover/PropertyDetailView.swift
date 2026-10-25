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
                        PropertyGalleryPlaceholder()
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

private struct PropertyGalleryPlaceholder: View {
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [Color(red: 0.79, green: 0.86, blue: 0.81), Color(red: 0.91, green: 0.91, blue: 0.85), Color(red: 0.70, green: 0.78, blue: 0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "house.fill").resizable().scaledToFit().frame(width: 115, height: 88).foregroundStyle(.white.opacity(0.9)).frame(maxWidth: .infinity, maxHeight: .infinity)
                Text("ILLUSTRATIVE IMAGE PLACEHOLDER").font(.system(size: 9, weight: .bold)).tracking(1).padding(9).background(.regularMaterial, in: Capsule()).padding(12)
            }.frame(height: 220)
            HStack(spacing: 4) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 5).fill(Color(red: 0.87, green: 0.90, blue: 0.87))
                        .overlay { Image(systemName: "photo").foregroundStyle(.white).font(.title3) }
                        .frame(height: 62)
                }
            }
        }.padding(.horizontal, 18)
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

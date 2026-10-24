import SwiftUI

struct PropertyDetailView: View {
    let id: String
    let api: any PropertyServing
    @State private var property: Property?
    @State private var failed = false
    @State private var loading = true
    var body: some View {
        Group {
            if loading { ProgressView("Loading property…") }
            else if let property {
                List {
                    DemoNotice()
                    Section {
                        Label(property.propertyType, systemImage: "house.fill").foregroundStyle(ClubStyle.emerald)
                        Text(property.name).font(.largeTitle.weight(.semibold))
                        Text("\(property.city), \(property.state)").foregroundStyle(.secondary)
                        Text(property.summary)
                    }
                    Section("Illustrative property facts") {
                        LabeledContent("Bedrooms", value: String(property.bedrooms))
                        LabeledContent("Bathrooms", value: String(property.bathrooms))
                        LabeledContent("Area", value: "\(property.areaSqFt) sq ft")
                        LabeledContent("Synthetic value", value: property.illustrativeValue)
                    }
                    Section("Source and limitations") {
                        Text(property.source)
                        Text("Fixture updated: \(property.updatedAt.prefix(10))")
                        Text("No verified valuation, rental income, fees, return projection or offering terms are available. No investment or ownership can be created in this demo.")
                    }
                }
            } else if failed {
                ContentUnavailableView {
                    Label("Property unavailable", systemImage: "wifi.exclamationmark")
                } description: { Text("The property could not be loaded from the API.") }
                actions: { Button("Try again") { Task { await load() } }.buttonStyle(.borderedProminent) }
            }
        }.navigationTitle("Property details").navigationBarTitleDisplayMode(.inline).task { await load() }
    }
    @MainActor private func load() async {
        loading = true
        failed = false
        do { property = try await api.property(id: id) }
        catch { property = nil; failed = true }
        loading = false
    }
}

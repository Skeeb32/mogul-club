import SwiftUI

struct DiscoverView: View {
    @StateObject private var model: DiscoverModel
    private let api: any PropertyServing
    init(api: any PropertyServing) {
        self.api = api
        _model = StateObject(wrappedValue: DiscoverModel(api: api))
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DemoNotice()
                switch model.state {
                case .loading:
                    ProgressView("Loading properties…").frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failed:
                    ContentUnavailableView {
                        Label("Unable to load properties", systemImage: "wifi.exclamationmark")
                    } description: { Text("Check that the development API is running, then try again.") }
                    actions: { Button("Try again") { Task { await model.load() } }.buttonStyle(.borderedProminent).accessibilityIdentifier("retry-properties") }
                case .loaded(let properties):
                    if properties.isEmpty {
                        ContentUnavailableView.search(text: model.query)
                    } else {
                        List {
                            Section {
                                Text("Explore residential real estate.").font(.title2.weight(.semibold))
                                Text("Understand the property, the numbers and the risks before any future investment.").foregroundStyle(.secondary)
                            }.listRowSeparator(.hidden)
                            Section("Property library") {
                                ForEach(properties) { property in
                                    NavigationLink {
                                        PropertyDetailView(id: property.id, api: api)
                                    } label: { PropertyRow(property: property) }
                                }
                            }
                        }.listStyle(.insetGrouped).refreshable { await model.load() }
                    }
                }
            }
            .navigationTitle("Discover")
            .toolbar { ToolbarItem(placement: .principal) { MogulLogo(width: 124) } }
            .searchable(text: $model.query, prompt: "Property name or location")
            .onSubmit(of: .search) { Task { await model.load() } }
            .onChange(of: model.query) { _, value in if value.isEmpty { Task { await model.load() } } }
            .task { await model.load() }
        }
    }
}
private struct PropertyRow: View {
    let property: Property
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(property.propertyType, systemImage: "house").font(.caption).foregroundStyle(.secondary)
            Text(property.name).font(.headline)
            Text("\(property.city), \(property.state)").font(.subheadline).foregroundStyle(.secondary)
            Text("\(property.bedrooms) beds · \(property.bathrooms) baths · \(property.areaSqFt) sq ft").font(.footnote)
            Text("\(property.illustrativeValue) illustrative value").font(.subheadline.weight(.semibold))
            Text("Synthetic property · Not an offering").font(.caption).foregroundStyle(.secondary)
        }.padding(.vertical, 8).accessibilityElement(children: .combine)
    }
}

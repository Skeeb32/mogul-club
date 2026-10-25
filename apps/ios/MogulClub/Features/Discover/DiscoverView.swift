import SwiftUI
import Charts

struct DiscoverView: View {
    @StateObject private var model: DiscoverModel
    private let api: any PropertyServing
    private let onAccount: () -> Void
    @State private var selectedType = "All homes"

    private let propertyTypes = ["All homes", "Single family", "Townhome"]

    private var visibleProperties: [Property] {
        guard case .loaded(let properties) = model.state else { return [] }
        let query = model.query.trimmingCharacters(in: .whitespacesAndNewlines)
        return properties.filter { property in
            let matchesQuery = query.isEmpty || [property.name, property.city, property.state, property.propertyType, property.summary]
                .joined(separator: " ").localizedCaseInsensitiveContains(query)
            let matchesType = selectedType == "All homes" || property.propertyType.localizedCaseInsensitiveContains(selectedType)
            return matchesQuery && matchesType
        }
    }

    init(api: any PropertyServing, onAccount: @escaping () -> Void = {}) {
        self.api = api
        self.onAccount = onAccount
        _model = StateObject(wrappedValue: DiscoverModel(api: api))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    intro
                    searchField
                    typeFilters
                    switch model.state {
                    case .loading:
                        loadingState
                    case .failed:
                        errorState
                    case .loaded(let properties):
                        if properties.isEmpty {
                            emptyState(title: "No demo properties yet", message: "Check back when the local demo API has property data.")
                        } else if visibleProperties.isEmpty {
                            emptyState(title: "No homes match", message: "Try another name, location, or property type.")
                        } else {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("Homes to discover").font(.title2.weight(.bold))
                                    Spacer()
                                    Text("\(visibleProperties.count) demo \(visibleProperties.count == 1 ? "home" : "homes")")
                                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                                }
                                LazyVStack(spacing: 18) {
                                ForEach(visibleProperties) { property in
                                    NavigationLink {
                                        PropertyDetailView(id: property.id, api: api)
                                    } label: { PropertyCard(property: property) }
                                        .buttonStyle(.plain)
                                }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { MogulLogo(width: 132) }
                ToolbarItem(placement: .topBarTrailing) { Button(action: onAccount) { Image(systemName: "person.crop.circle").font(.title3) }.accessibilityLabel("Account") }
            }
            .refreshable { await model.load() }
            .task(id: model.query) {
                if !model.query.isEmpty {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    guard !Task.isCancelled else { return }
                }
                await model.load()
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 7) {
                Circle().fill(ClubStyle.emerald).frame(width: 7, height: 7)
                Text("MOGUL CLUB · DISCOVER").font(.caption.weight(.bold)).tracking(1.15).foregroundStyle(ClubStyle.emerald)
            }
            Text("Homes worth\na closer look.")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .tracking(-1.25).lineSpacing(-2).fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("discover-heading")
            Text("Fictional demo homes · no offerings.")
                .font(.subheadline).foregroundStyle(.secondary)
                .accessibilityIdentifier("demo-notice")
        }
        .padding(.top, 8)
    }

    private var searchField: some View {
        HStack(spacing: 11) {
            Image(systemName: "magnifyingglass").font(.body.weight(.medium)).foregroundStyle(ClubStyle.emerald)
            TextField("Search homes or locations", text: $model.query)
                .font(.subheadline).textInputAutocapitalization(.words).autocorrectionDisabled()
                .submitLabel(.search).accessibilityIdentifier("discover-search")
            if !model.query.isEmpty {
                Button { model.query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary) }
                    .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 15).frame(height: 52)
        .background(.background, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(.black.opacity(0.07)))
    }

    private var typeFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(propertyTypes, id: \.self) { type in
                    Button { selectedType = type } label: {
                        Text(type).font(.subheadline.weight(.medium))
                            .padding(.horizontal, 15).padding(.vertical, 10)
                            .foregroundStyle(selectedType == type ? .white : .primary)
                            .background(selectedType == type ? ClubStyle.emerald : Color(.secondarySystemBackground), in: Capsule())
                    }
                    .buttonStyle(.plain).accessibilityAddTraits(selectedType == type ? .isSelected : [])
                }
            }
        }
        .contentMargins(.trailing, 1)
    }

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: 15) {
            RoundedRectangle(cornerRadius: 22).fill(Color(.tertiarySystemGroupedBackground)).frame(height: 255)
                .overlay { ProgressView("Finding demo homes…") }
            RoundedRectangle(cornerRadius: 12).fill(Color(.tertiarySystemGroupedBackground)).frame(height: 76)
        }.accessibilityIdentifier("discover-loading")
    }

    private var errorState: some View {
        VStack(alignment: .leading, spacing: 13) {
            Image(systemName: "wifi.exclamationmark").font(.title2).foregroundStyle(ClubStyle.emerald)
            Text("We couldn’t reach the demo homes").font(.title3.weight(.semibold))
            Text("Check that the local demo API is running and your device is connected, then try again.")
                .font(.subheadline).foregroundStyle(.secondary)
            Button { Task { await model.load() } } label: {
                Label("Try again", systemImage: "arrow.clockwise").font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 15).padding(.vertical, 11).foregroundStyle(.white)
                    .background(ClubStyle.emerald, in: Capsule())
            }
            .accessibilityIdentifier("retry-properties")
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func emptyState(title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "house.lodge").font(.system(size: 30)).foregroundStyle(ClubStyle.emerald)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(28)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct PropertyCard: View {
    let property: Property
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DemoPropertyPhotography(property: property, height: 218)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(property.name).font(.title2.weight(.bold)).tracking(-0.35).foregroundStyle(.primary)
                            .accessibilityIdentifier(property.name)
                        Label("\(property.city), \(property.state)", systemImage: "mappin.and.ellipse")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold)).foregroundStyle(ClubStyle.emerald)
                        .padding(10).background(Color(.secondarySystemBackground), in: Circle())
                }
                HStack(spacing: 8) {
                    PropertyTag(title: property.propertyType, icon: "house")
                    PropertyTag(title: "\(property.bedrooms) bd", icon: "bed.double")
                    PropertyTag(title: "\(property.bathrooms) ba", icon: "shower")
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 17).padding(.vertical, 16)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.black.opacity(0.055)))
        .shadow(color: .black.opacity(0.055), radius: 16, y: 6)
        .accessibilityElement(children: .combine)
    }
}

private struct PropertyTag: View {
    let title: String
    let icon: String
    var body: some View {
        Label(title, systemImage: icon).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Color(.secondarySystemBackground), in: Capsule())
    }
}

struct PortfolioView: View {
    let onAccount: () -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DemoNotice()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your portfolio").font(.largeTitle.weight(.bold))
                        Text("A sample view of how portfolio reporting could look.").foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill").foregroundStyle(ClubStyle.emerald)
                        Text("Illustrative sample only · no actual investments").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Illustrative portfolio value").font(.subheadline).foregroundStyle(.secondary)
                        Text("$15,653.61").font(.system(size: 38, weight: .semibold, design: .rounded)).minimumScaleFactor(0.75).lineLimit(1)
                        Label("$153.61 (0.67%) since inception", systemImage: "arrowtriangle.up.fill")
                            .font(.subheadline.weight(.medium)).foregroundStyle(ClubStyle.emerald)
                    }
                    .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18))
                    MetricPairCard(title: "Investment", rows: [("Gain", "$153.61"), ("Total invested", "$15,500.00")])
                    MetricPairCard(title: "Cash flow", rows: [("Total ever earned", "$320.79"), ("Illustrative wallet", "$94.28")])
                    HStack { Text("Appreciation"); Spacer(); Text("$59.32") }.font(.subheadline.weight(.semibold)).foregroundStyle(ClubStyle.emerald)
                        .padding(16).background(.background, in: RoundedRectangle(cornerRadius: 14))
                    MetricPairCard(title: "Summary", rows: [("Total invested", "$15,500.00"), ("Illustrative total", "$15,653.61")])
                    Text("All figures on this screen are fictional design examples, not performance data or an offer to invest.")
                        .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 2)
                }.padding(18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) { MogulLogo(width: 124) }
                ToolbarItem(placement: .topBarTrailing) { Button(action: onAccount) { Image(systemName: "person.crop.circle").font(.title3) }.accessibilityLabel("Account") }
            }
        }
    }
}

private struct MetricPairCard: View {
    let title: String
    let rows: [(String, String)]
    var body: some View {
        VStack(spacing: 0) {
            HStack { Image(systemName: "chevron.up").font(.caption2); Text(title); Spacer() }
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary).padding(14)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack { Text(row.0).foregroundStyle(.secondary); Spacer(); Text(row.1).fontWeight(.semibold) }
                    .font(.subheadline).padding(.horizontal, 14).padding(.bottom, 14)
            }
        }.background(.background, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct AnalysisView: View {
    let onAccount: () -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DemoNotice()
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Analysis").font(.largeTitle.weight(.bold))
                        Text("Understand performance and cash flow.").foregroundStyle(.secondary)
                    }
                    Text("Illustrative analytics · sample data only").font(.caption.weight(.semibold)).foregroundStyle(ClubStyle.emerald)
                    HistoricalReturnsCard()
                    AssetBreakdownCard()
                    CashFlowCard()
                }.padding(18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) { MogulLogo(width: 124) }
                ToolbarItem(placement: .topBarTrailing) { Button(action: onAccount) { Image(systemName: "person.crop.circle").font(.title3) }.accessibilityLabel("Account") }
            }
        }
    }
}

private struct HistoricalReturnsCard: View {
    private let points: [(String, Double)] = [("Jan", 5.7), ("Feb", 6.2), ("Mar", 6.9), ("Apr", 7.4), ("May", 8.3)]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historical returns").font(.headline)
            Chart {
                ForEach(points, id: \.0) { point in
                    BarMark(x: .value("Month", point.0), y: .value("Sample return", point.1))
                        .foregroundStyle(Color(red: 0.89, green: 0.93, blue: 0.90)).cornerRadius(7)
                    LineMark(x: .value("Month", point.0), y: .value("Sample return", point.1 + 1.4))
                        .foregroundStyle(ClubStyle.emerald).lineStyle(StrokeStyle(lineWidth: 2))
                    PointMark(x: .value("Month", point.0), y: .value("Sample return", point.1 + 1.4)).foregroundStyle(ClubStyle.emerald)
                }
            }
            .frame(height: 170).chartYAxis(.hidden)
            Text("Example values shown for layout preview; they are not historical or forecast returns.")
                .font(.caption2).foregroundStyle(.secondary)
        }.padding(16).background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct AssetBreakdownCard: View {
    private let segments: [(String, Double, Color)] = [
        ("Residential", 42, Color(red: 0.82, green: 0.37, blue: 0.30)),
        ("Multifamily", 24, .black), ("Townhomes", 18, Color(red: 0.19, green: 0.55, blue: 0.39)),
        ("Other", 16, Color(red: 0.37, green: 0.43, blue: 0.49))
    ]
    var body: some View {
        HStack(spacing: 16) {
            Chart(segments, id: \.0) { item in
                SectorMark(angle: .value("Share", item.1), innerRadius: .ratio(0.68), angularInset: 2).foregroundStyle(item.2)
            }
            .frame(width: 150, height: 150)
            .overlay { VStack(spacing: 2) { Text("11").font(.title2.bold()); Text("sample homes").font(.caption2).foregroundStyle(.secondary) } }
            VStack(alignment: .leading, spacing: 10) {
                Text("Asset breakdown").font(.headline)
                ForEach(segments, id: \.0) { item in
                    HStack(spacing: 7) { Circle().fill(item.2).frame(width: 8, height: 8); Text(item.0).font(.caption).lineLimit(1) }
                }
            }
            Spacer(minLength: 0)
        }.padding(16).background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct CashFlowCard: View {
    private let rows: [(String, String, String)] = [
        ("Gross rental income", "$4,250", "$4,380"), ("Operating costs", "($1,210)", "($1,264)"),
        ("Net operating income", "$3,040", "$3,116"), ("Debt service", "($1,250)", "($1,250)"),
        ("Illustrative cash flow", "$1,790", "$1,866")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cash flow overview").font(.headline)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(row.0).font(.caption).lineLimit(1)
                    Spacer(minLength: 5)
                    Text(row.1).font(.caption.monospacedDigit())
                    Text(row.2).font(.caption.monospacedDigit()).foregroundStyle(ClubStyle.emerald)
                }
                if row.0 != "Illustrative cash flow" { Divider() }
            }
            Text("Sample cash flows only. No property income has been verified.").font(.caption2).foregroundStyle(.secondary)
        }.padding(16).background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

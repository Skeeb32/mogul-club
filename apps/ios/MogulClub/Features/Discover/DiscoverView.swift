import SwiftUI
import Charts

struct DiscoverView: View {
    @StateObject private var model: DiscoverModel
    private let api: any PropertyServing
    private let onAccount: () -> Void

    init(api: any PropertyServing, onAccount: @escaping () -> Void = {}) {
        self.api = api
        self.onAccount = onAccount
        _model = StateObject(wrappedValue: DiscoverModel(api: api))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DemoNotice()
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Explore properties").font(.largeTitle.weight(.bold))
                        Text("Discover homes and learn what drives their value.").font(.subheadline).foregroundStyle(.secondary)
                    }
                    switch model.state {
                    case .loading:
                        ProgressView("Loading properties…").frame(maxWidth: .infinity, minHeight: 220)
                    case .failed:
                        ContentUnavailableView {
                            Label("Unable to load properties", systemImage: "wifi.exclamationmark")
                        } description: { Text("Check that the development API is running, then try again.") }
                        actions: { Button("Try again") { Task { await model.load() } }.buttonStyle(.borderedProminent).accessibilityIdentifier("retry-properties") }
                    case .loaded(let properties):
                        if properties.isEmpty {
                            ContentUnavailableView.search(text: model.query)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(properties) { property in
                                    NavigationLink {
                                        PropertyDetailView(id: property.id, api: api)
                                    } label: { PropertyCard(property: property) }
                                        .buttonStyle(.plain)
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
                ToolbarItem(placement: .principal) { MogulLogo(width: 124) }
                ToolbarItem(placement: .topBarTrailing) { Button(action: onAccount) { Image(systemName: "person.crop.circle").font(.title3) }.accessibilityLabel("Account") }
            }
            .searchable(text: $model.query, prompt: "Search properties or locations")
            .onSubmit(of: .search) { Task { await model.load() } }
            .onChange(of: model.query) { _, value in if value.isEmpty { Task { await model.load() } } }
            .refreshable { await model.load() }
            .task { await model.load() }
        }
    }
}

private struct PropertyCard: View {
    let property: Property
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [Color(red: 0.79, green: 0.86, blue: 0.81), Color(red: 0.91, green: 0.91, blue: 0.85), Color(red: 0.70, green: 0.78, blue: 0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "house.fill")
                    .resizable().scaledToFit().frame(width: 104, height: 78)
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    Text("ILLUSTRATIVE PROPERTY")
                        .font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1)
                        .padding(.horizontal, 9).padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule()).padding(12)
            }
            .frame(height: 184).clipped()
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(property.name).font(.title3.weight(.bold)).foregroundStyle(.primary)
                        Text("\(property.city), \(property.state)").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold)).foregroundStyle(ClubStyle.emerald)
                }
                HStack(spacing: 12) {
                    Label("\(property.bedrooms) bd", systemImage: "bed.double")
                    Label("\(property.bathrooms) ba", systemImage: "shower")
                    Label("\(property.areaSqFt.formatted()) sq ft", systemImage: "square.dashed")
                }
                .font(.caption).foregroundStyle(.secondary)
                Divider()
                HStack(alignment: .firstTextBaseline) {
                    Text(property.illustrativeValue).font(.title3.weight(.bold))
                    Text("illustrative value").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(property.propertyType).font(.caption.weight(.semibold)).foregroundStyle(ClubStyle.emerald)
                }
            }
            .padding(15)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.black.opacity(0.05)))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
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

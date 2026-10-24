import Foundation

struct Property: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let city: String
    let state: String
    let propertyType: String
    let bedrooms: Int
    let bathrooms: Int
    let areaSqFt: Int
    let illustrativeValueMinor: Int64
    let currency: String
    let summary: String
    let synthetic: Bool
    let status: String
    let source: String
    let updatedAt: String

    var illustrativeValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: Decimal(illustrativeValueMinor) / 100)) ?? "Unavailable"
    }
}
struct PropertyPage: Codable, Sendable {
    let items: [Property]
    let total: Int
    let page: Int
    let limit: Int
    let mode: String
}

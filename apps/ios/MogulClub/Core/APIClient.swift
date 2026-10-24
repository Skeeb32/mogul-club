import Foundation

protocol PropertyServing: Sendable {
    func properties(query: String) async throws -> PropertyPage
    func property(id: String) async throws -> Property
}
struct APIClient: PropertyServing {
    let baseURL: URL
    var session: URLSession = .shared

    static var development: APIClient {
        // No credentials in the app. Debug localhost reaches the Mac from the simulator.
        #if DEBUG
        return APIClient(baseURL: URL(string: "http://localhost:3001/api/v1/")!)
        #else
        // No invented production host. Release remains unconfigured until authorized.
        return APIClient(baseURL: URL(string: "https://unconfigured.invalid/api/v1/")!)
        #endif
    }
    func properties(query: String) async throws -> PropertyPage {
        let result: PropertyPage = try await get(path: "properties", query: [URLQueryItem(name: "q", value: query), URLQueryItem(name: "limit", value: "50")])
        guard result.mode == "demo", result.items.allSatisfy({ $0.synthetic && $0.status == "demo_only" }) else { throw APIError.invalidDemo }
        return result
    }
    func property(id: String) async throws -> Property {
        guard !id.isEmpty, id.utf8.allSatisfy({ (97...122).contains($0) || (48...57).contains($0) || $0 == 45 }) else { throw APIError.invalidDemo }
        let result: Property = try await get(path: "properties/" + id)
        guard result.synthetic, result.status == "demo_only" else { throw APIError.invalidDemo }
        return result
    }
    private func get<T: Decodable>(path: String, query: [URLQueryItem] = []) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = query.isEmpty ? nil : query
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw APIError.unavailable }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
enum APIError: LocalizedError {
    case unavailable, invalidDemo
    var errorDescription: String? { "Properties are unavailable. Check your connection and try again." }
}

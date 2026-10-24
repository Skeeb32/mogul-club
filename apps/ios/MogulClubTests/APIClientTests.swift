import XCTest
#if canImport(Mogul_Club)
@testable import Mogul_Club
#else
@testable import MogulClub
#endif

final class StubProtocol: URLProtocol, @unchecked Sendable {
    static var status = 200
    static var payload = Data()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.payload)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
final class APIClientTests: XCTestCase {
    private func client() -> APIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        return APIClient(baseURL: URL(string: "https://example.invalid/api/v1/")!, session: URLSession(configuration: config))
    }
    func testDecodesEmptyDemoPage() async throws {
        StubProtocol.status = 200
        StubProtocol.payload = Data(#"{"items":[],"total":0,"page":1,"limit":20,"mode":"demo"}"#.utf8)
        let page = try await client().properties(query: "")
        XCTAssertEqual(page.items.count, 0)
    }
    func testRejectsHTTPFailure() async {
        StubProtocol.status = 503
        do { _ = try await client().properties(query: ""); XCTFail("Expected failure") }
        catch { XCTAssertTrue(error is APIError) }
    }
    func testRejectsNonDemoResponse() async {
        StubProtocol.status = 200
        StubProtocol.payload = Data(#"{"items":[],"total":0,"page":1,"limit":20,"mode":"production"}"#.utf8)
        do { _ = try await client().properties(query: ""); XCTFail("Expected failure") }
        catch { XCTAssertTrue(error is APIError) }
    }
}
private struct EmptyService: PropertyServing {
    func properties(query: String) async throws -> PropertyPage { PropertyPage(items: [], total: 0, page: 1, limit: 20, mode: "demo") }
    func property(id: String) async throws -> Property { throw APIError.unavailable }
}
private struct FailingService: PropertyServing {
    func properties(query: String) async throws -> PropertyPage { throw URLError(.notConnectedToInternet) }
    func property(id: String) async throws -> Property { throw APIError.unavailable }
}
final class DiscoverModelTests: XCTestCase {
    @MainActor func testEmptyState() async {
        let model = DiscoverModel(api: EmptyService())
        await model.load()
        XCTAssertEqual(model.state, .loaded([]))
    }
    @MainActor func testOfflineState() async {
        let model = DiscoverModel(api: FailingService())
        await model.load()
        XCTAssertEqual(model.state, .failed)
    }
}

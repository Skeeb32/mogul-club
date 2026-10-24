import Foundation
import Combine

@MainActor
final class DiscoverModel: ObservableObject {
    enum State: Equatable { case loading, loaded([Property]), failed }
    @Published private(set) var state: State = .loading
    @Published var query = ""
    private let api: any PropertyServing
    private var requestID = UUID()
    init(api: any PropertyServing) { self.api = api }

    func load() async {
        let id = UUID()
        requestID = id
        state = .loading
        do {
            let page = try await api.properties(query: query)
            guard requestID == id, !Task.isCancelled else { return }
            state = .loaded(page.items)
        } catch {
            guard requestID == id, !Task.isCancelled else { return }
            state = .failed
        }
    }
}

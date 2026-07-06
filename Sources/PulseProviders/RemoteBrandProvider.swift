import Foundation
import PulseCore

/// Loads a brand from the Pulse brand service, falling back to a bundled
/// default on any failure — a bad response, a decode error, or no network.
///
/// Same offline-first stance as the data providers: the app must launch and
/// stay usable even when the service is unreachable. The type it decodes is the
/// exact `BrandConfig` the server encodes — one shared domain model.
public struct RemoteBrandProvider: Sendable {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func brand(id: String, fallback: BrandConfig = BrandConfig()) async -> BrandConfig {
        let url = baseURL.appending(path: "brands").appending(path: id)
        do {
            let (data, response) = try await session.data(from: url)
            guard
                let http = response as? HTTPURLResponse,
                (200...299).contains(http.statusCode)
            else { return fallback }
            return try JSONDecoder().decode(BrandConfig.self, from: data)
        } catch {
            return fallback
        }
    }
}

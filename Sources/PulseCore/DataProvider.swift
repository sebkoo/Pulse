import Foundation

/// The contract every dashboard module implements.
///
/// This protocol is why adding a new data source requires zero UI changes:
/// the UI renders whatever `BrandConfig.modules` asks for, matching each id
/// against a registered provider, and treats every payload the same way —
/// fetch, cache, display, surface staleness.
public protocol DataProvider: Sendable {
    /// The payload this provider produces — already normalized, ready to render.
    associatedtype Payload: Codable & Equatable & Sendable

    /// Stable identifier matched against `BrandConfig.modules` (lowercase).
    var id: String { get }

    /// Human-readable module title for the dashboard card.
    var title: String { get }

    /// Fetch a fresh payload from the network.
    func fetch() async throws -> Payload
}

public extension DataProvider {
    /// Fetch with offline-first semantics:
    /// 1. Try the network; on success, cache and return a fresh result.
    /// 2. On failure, fall back to the last cached payload (marked stale).
    /// 3. Only throw when there is neither a fresh nor a cached payload.
    func fetchCachingLastGood(
        cache: PayloadCache<Payload>,
        now: Date = Date()
    ) async throws -> ProviderResult<Payload> {
        do {
            let payload = try await fetch()
            try? await cache.save(payload, fetchedAt: now)
            return ProviderResult(payload: payload, fetchedAt: now, isStale: false)
        } catch {
            if let entry = await cache.load() {
                return ProviderResult(payload: entry.payload, fetchedAt: entry.fetchedAt, isStale: true)
            }
            throw error
        }
    }
}

/// A payload plus the honesty around it: when it was fetched and whether it
/// came from the cache. The UI decides how to present staleness; the core
/// only reports it.
public struct ProviderResult<Payload: Codable & Equatable & Sendable>: Equatable, Sendable {
    public let payload: Payload
    public let fetchedAt: Date
    public let isStale: Bool

    public init(payload: Payload, fetchedAt: Date, isStale: Bool) {
        self.payload = payload
        self.fetchedAt = fetchedAt
        self.isStale = isStale
    }

    /// Age of the payload relative to `now` — display fodder for
    /// "updated 3m ago" labels.
    public func age(now: Date = Date()) -> TimeInterval {
        now.timeIntervalSince(fetchedAt)
    }
}

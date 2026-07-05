import Foundation
import Observation
import PulseCore

/// What a module card can be showing at any moment.
public enum ModulePhase<Payload: Codable & Equatable & Sendable>: Equatable {
    case loading
    case loaded(ProviderResult<Payload>)
    case failed(String)
}

/// Observation-based view model for one dashboard module.
///
/// Generic over the provider, so every module gets identical semantics:
/// load → fresh, or cached-marked-stale, or a readable failure. The view
/// just switches over `phase`.
@Observable
@MainActor
public final class ModuleModel<Provider: DataProvider> {
    public private(set) var phase: ModulePhase<Provider.Payload> = .loading

    private let provider: Provider
    private let cache: PayloadCache<Provider.Payload>

    public init(provider: Provider, cache: PayloadCache<Provider.Payload>) {
        self.provider = provider
        self.cache = cache
    }

    public func load(now: Date = Date()) async {
        do {
            let result = try await provider.fetchCachingLastGood(cache: cache, now: now)
            phase = .loaded(result)
        } catch {
            phase = .failed("Couldn't load \(provider.title.lowercased()). Pull to retry.")
        }
    }
}

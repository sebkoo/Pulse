import Foundation

/// File-backed, offline-first cache for one provider's last good payload.
///
/// An `actor`, so concurrent readers and writers are safe by construction.
/// The policy is deliberately thin: `save` records the payload with its fetch
/// time, `load` returns whatever exists, and staleness is judged by the
/// caller — "too old" is a product decision, not a storage one.
public actor PayloadCache<Payload: Codable> {
    public struct Entry: Codable {
        public let payload: Payload
        public let fetchedAt: Date
    }

    private let fileURL: URL

    /// - Parameters:
    ///   - key: unique cache key, typically the provider id.
    ///   - directory: where the cache file lives; defaults to the user's
    ///     caches directory. Tests pass a temporary directory.
    public init(key: String, directory: URL? = nil) {
        let dir = directory
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.fileURL = dir.appendingPathComponent("pulse-cache-\(key).json")
    }

    public func save(_ payload: Payload, fetchedAt: Date = Date()) throws {
        let data = try JSONEncoder().encode(Entry(payload: payload, fetchedAt: fetchedAt))
        try data.write(to: fileURL, options: .atomic)
    }

    /// A missing or unreadable file is a cache miss, never a crash.
    public func load() -> Entry? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(Entry.self, from: data)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

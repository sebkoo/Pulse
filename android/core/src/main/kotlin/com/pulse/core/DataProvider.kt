package com.pulse.core

/**
 * The contract every dashboard module implements — the Kotlin mirror of the
 * Swift `DataProvider`. The UI renders whatever [BrandConfig.modules] asks for,
 * matching each id against a provider, and treats every payload the same way:
 * fetch, cache, display, surface staleness.
 */
interface DataProvider<T> {
    /** Stable identifier matched against [BrandConfig.modules] (lowercase). */
    val id: String

    /** Human-readable module title for the dashboard card. */
    val title: String

    /** Fetch a fresh payload from the network. */
    suspend fun fetch(): T
}

/** Typed provider failures — the mirror of the Swift `ProviderError`. */
sealed class ProviderException(message: String) : Exception(message) {
    data object UnusablePayload : ProviderException("unusable payload") {
        private fun readResolve(): Any = UnusablePayload
    }
    data class BadResponse(val status: Int) : ProviderException("bad response: $status")
}

/**
 * The network boundary, abstracted so tests never touch the wire — the role
 * `URLSession` + `StubURLProtocol` play on iOS. A real implementation performs
 * the GET; a fake returns canned JSON.
 */
fun interface HttpFetcher {
    /** Returns the response body for a GET, or throws (e.g. [ProviderException.BadResponse]). */
    suspend fun get(url: String): String
}

/** A payload plus when it was fetched and whether it came from the cache. The
 *  UI decides how to present staleness; the core only reports it. */
data class ProviderResult<T>(
    val payload: T,
    val fetchedAt: Long,
    val isStale: Boolean,
)

/**
 * Fetch with offline-first semantics — identical to the iOS extension:
 * 1. Try the network; on success, cache and return a fresh result.
 * 2. On failure, fall back to the last cached payload (marked stale).
 * 3. Only throw when there is neither a fresh nor a cached payload.
 */
suspend fun <T> DataProvider<T>.fetchCachingLastGood(
    cache: PayloadCache<T>,
    now: Long,
): ProviderResult<T> {
    return try {
        val payload = fetch()
        runCatching { cache.save(payload, now) }
        ProviderResult(payload, fetchedAt = now, isStale = false)
    } catch (e: Exception) {
        val entry = cache.load()
        if (entry != null) {
            ProviderResult(entry.payload, fetchedAt = entry.fetchedAt, isStale = true)
        } else {
            throw e
        }
    }
}

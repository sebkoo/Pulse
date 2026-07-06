package com.pulse.core

import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** One cached payload and when it was fetched. */
data class CacheEntry<T>(val payload: T, val fetchedAt: Long)

/** The cache contract: load the last-good entry, or save a fresh one. */
interface PayloadCache<T> {
    suspend fun load(): CacheEntry<T>?
    suspend fun save(payload: T, fetchedAt: Long)
}

/**
 * In-memory cache guarded by a [Mutex] — the Kotlin analog of the Swift actor.
 * Data-race safety by construction: the suspend boundary + mutex enforce what a
 * plain field never could.
 */
class InMemoryPayloadCache<T> : PayloadCache<T> {
    private val mutex = Mutex()
    private var entry: CacheEntry<T>? = null

    override suspend fun load(): CacheEntry<T>? = mutex.withLock { entry }

    override suspend fun save(payload: T, fetchedAt: Long) = mutex.withLock {
        entry = CacheEntry(payload, fetchedAt)
    }
}

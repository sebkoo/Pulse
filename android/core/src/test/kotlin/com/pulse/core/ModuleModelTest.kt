package com.pulse.core

import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertTrue

class ModuleModelTest {
    private class FakeProvider(val result: Result<String>) : DataProvider<String> {
        override val id = "fake"
        override val title = "Fake"
        override suspend fun fetch(): String = result.getOrThrow()
    }

    @Test
    fun `fresh fetch loads and is not stale`() = runTest {
        val model = ModuleModel(FakeProvider(Result.success("fresh")), InMemoryPayloadCache())

        model.load(now = 1_000)

        val phase = assertIs<ModulePhase.Loaded<String>>(model.phase.value)
        assertEquals("fresh", phase.result.payload)
        assertEquals(false, phase.result.isStale)
    }

    @Test
    fun `failure falls back to cached last-good, marked stale`() = runTest {
        val cache = InMemoryPayloadCache<String>()
        cache.save("cached", fetchedAt = 500)
        val model = ModuleModel(FakeProvider(Result.failure(ProviderException.BadResponse(500))), cache)

        model.load(now = 1_000)

        val phase = assertIs<ModulePhase.Loaded<String>>(model.phase.value)
        assertEquals("cached", phase.result.payload)
        assertEquals(500, phase.result.fetchedAt)
        assertTrue(phase.result.isStale)
    }

    @Test
    fun `failure with an empty cache surfaces a readable failure`() = runTest {
        val model = ModuleModel(FakeProvider(Result.failure(ProviderException.BadResponse(500))), InMemoryPayloadCache())

        model.load(now = 1_000)

        assertIs<ModulePhase.Failed>(model.phase.value)
    }

    @Test
    fun `a successful fetch is written back to the cache`() = runTest {
        val cache = InMemoryPayloadCache<String>()
        val model = ModuleModel(FakeProvider(Result.success("fresh")), cache)

        model.load(now = 1_000)

        assertEquals("fresh", cache.load()?.payload)
    }
}

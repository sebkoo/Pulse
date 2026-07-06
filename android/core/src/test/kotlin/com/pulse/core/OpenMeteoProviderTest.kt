package com.pulse.core

import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class OpenMeteoProviderTest {
    private fun provider(body: String) = OpenMeteoProvider(fetcher = { body })

    @Test
    fun `parses a current weather payload`() = runTest {
        val snapshot = provider(
            """{"current":{"temperature_2m":31.4,"weather_code":95,"wind_speed_10m":12.3},
                "current_units":{"temperature_2m":"°C"}}""",
        ).fetch()

        assertEquals(31.4, snapshot.temperature)
        assertEquals("°C", snapshot.unit)
        assertEquals(12.3, snapshot.windSpeed)
        assertEquals("Thunderstorm", snapshot.condition)
    }

    @Test
    fun `missing fields degrade gracefully`() = runTest {
        val snapshot = provider("""{"current":{"temperature_2m":20.0}}""").fetch()

        assertEquals("°C", snapshot.unit)          // default unit
        assertEquals(0.0, snapshot.windSpeed)      // default wind
        assertEquals("Unknown", snapshot.condition) // unknown code degrades
    }

    @Test
    fun `unusable payload throws`() = runTest {
        assertFailsWith<ProviderException.UnusablePayload> {
            provider("{}").fetch()
        }
    }

    @Test
    fun `transport failure propagates`() = runTest {
        val failing = OpenMeteoProvider(fetcher = { throw ProviderException.BadResponse(503) })

        val error = assertFailsWith<ProviderException.BadResponse> { failing.fetch() }
        assertEquals(503, error.status)
    }
}

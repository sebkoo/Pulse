package com.pulse.core

import kotlin.test.Test
import kotlin.test.assertEquals

class BrandConfigTest {
    @Test
    fun `defaults when json is null or blank`() {
        assertEquals(BrandConfig(), BrandConfig.load(null))
        assertEquals(BrandConfig(), BrandConfig.load("   "))
    }

    @Test
    fun `missing fields fall back to defaults`() {
        val config = BrandConfig.load("""{"appName":"Acme Field Ops"}""")

        assertEquals("Acme Field Ops", config.appName)
        assertEquals("#1F3A5F", config.accentColorHex)          // default
        assertEquals(listOf("weather", "earthquakes"), config.modules) // default
    }

    @Test
    fun `module ids are lowercased, trimmed, and emptied entries dropped`() {
        val config = BrandConfig.load(
            """{"modules":["  Weather ", "EARTHQUAKES", "", "  "]}""",
        )

        assertEquals(listOf("weather", "earthquakes"), config.modules)
    }

    @Test
    fun `broken json downgrades to defaults instead of crashing`() {
        assertEquals(BrandConfig(), BrandConfig.load("{ not json"))
    }

    @Test
    fun `parses a full brand file`() {
        val config = BrandConfig.load(
            """{"appName":"Marina Weather","accentColorHex":"#0F766E","modules":["weather"]}""",
        )

        assertEquals(BrandConfig("Marina Weather", "#0F766E", listOf("weather")), config)
    }
}

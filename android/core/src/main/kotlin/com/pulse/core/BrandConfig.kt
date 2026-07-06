package com.pulse.core

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * The white-label heart of Pulse — the exact same `Brand.json` the iOS app
 * reads. Everything a company customizes lives in one file: the app name, the
 * accent color, and which modules render (matched against [DataProvider.id]).
 *
 * Every field has a default, so a partial or broken brand file can only ever
 * downgrade the experience — branding can never crash the app.
 */
@Serializable
data class BrandConfig(
    val appName: String = "Pulse",
    val accentColorHex: String = "#1F3A5F",
    /** Provider ids to render, in order. Unknown ids are ignored by the UI. */
    val modules: List<String> = listOf("weather", "earthquakes"),
) {
    companion object {
        private val json = Json {
            ignoreUnknownKeys = true
            isLenient = true
        }

        /**
         * Load a brand config from JSON text, falling back to defaults on any
         * failure. A broken brand file is a downgrade, never a crash — the same
         * contract as the iOS decoder.
         */
        fun load(jsonText: String?): BrandConfig {
            if (jsonText.isNullOrBlank()) return BrandConfig()
            return try {
                json.decodeFromString<BrandConfig>(jsonText).normalized()
            } catch (_: Exception) {
                BrandConfig()
            }
        }
    }

    /** Module ids are lowercased and trimmed so Brand.json is forgiving about
     *  casing; empty entries are dropped. */
    private fun normalized(): BrandConfig = copy(
        modules = modules.map { it.trim().lowercase() }.filter { it.isNotEmpty() },
    )
}

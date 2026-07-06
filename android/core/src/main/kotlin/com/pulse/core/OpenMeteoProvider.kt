package com.pulse.core

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/** What the weather module renders — already normalized, no nullables the UI
 *  has to guard against. Mirror of the iOS `WeatherSnapshot`. */
@Serializable
data class WeatherSnapshot(
    val temperature: Double,
    val unit: String,
    val windSpeed: Double,
    val conditionCode: Int,
    val condition: String,
)

/**
 * Current weather from the free, keyless Open-Meteo API — the same endpoint the
 * iOS provider calls. Everything on the wire is optional; this normalizes it at
 * one boundary so the rest of the app never sees a null.
 */
class OpenMeteoProvider(
    private val latitude: Double = 38.8462,
    private val longitude: Double = -77.3064,
    private val fetcher: HttpFetcher,
) : DataProvider<WeatherSnapshot> {

    override val id: String = "weather"
    override val title: String = "Weather"

    override suspend fun fetch(): WeatherSnapshot {
        val url = "https://api.open-meteo.com/v1/forecast" +
            "?latitude=$latitude&longitude=$longitude" +
            "&current=temperature_2m,weather_code,wind_speed_10m"

        val body = fetcher.get(url)
        val raw = json.decodeFromString<RawForecast>(body)
        val current = raw.current ?: throw ProviderException.UnusablePayload
        val temperature = current.temperature ?: throw ProviderException.UnusablePayload

        return WeatherSnapshot(
            temperature = temperature,
            unit = raw.units?.temperature ?: "°C",
            windSpeed = current.windSpeed ?: 0.0,
            conditionCode = current.weatherCode ?: -1,
            condition = conditionFor(current.weatherCode),
        )
    }

    companion object {
        private val json = Json { ignoreUnknownKeys = true }

        /** Human-readable label for a WMO weather code; unknown codes degrade to
         *  "Unknown" rather than failing the whole payload. */
        fun conditionFor(code: Int?): String = when (code) {
            null -> "Unknown"
            0 -> "Clear sky"
            1, 2 -> "Partly cloudy"
            3 -> "Overcast"
            45, 48 -> "Fog"
            in 51..57 -> "Drizzle"
            in 61..67 -> "Rain"
            in 71..77 -> "Snow"
            in 80..82 -> "Rain showers"
            in 95..99 -> "Thunderstorm"
            else -> "Unknown"
        }
    }

    // Wire shapes (honest: everything optional).

    @Serializable
    private data class RawForecast(
        val current: RawCurrent? = null,
        @SerialName("current_units") val units: RawUnits? = null,
    )

    @Serializable
    private data class RawCurrent(
        @SerialName("temperature_2m") val temperature: Double? = null,
        @SerialName("weather_code") val weatherCode: Int? = null,
        @SerialName("wind_speed_10m") val windSpeed: Double? = null,
    )

    @Serializable
    private data class RawUnits(
        @SerialName("temperature_2m") val temperature: String? = null,
    )
}

import type { Brand, Gateway, Quake, Weather } from "./types";

// The Vapor brand service (config over the wire). Override with BRAND_SERVICE_URL.
const BRAND_SERVICE = process.env.BRAND_SERVICE_URL ?? "http://127.0.0.1:8080";

async function fetchBrand(id: string): Promise<Brand | null> {
  const res = await fetch(`${BRAND_SERVICE}/brands/${encodeURIComponent(id)}`);
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(`brand service responded ${res.status}`);
  return (await res.json()) as Brand;
}

async function fetchWeather(): Promise<Weather> {
  const url =
    "https://api.open-meteo.com/v1/forecast?latitude=38.8462&longitude=-77.3064" +
    "&current=temperature_2m,weather_code,wind_speed_10m";
  const res = await fetch(url);
  if (!res.ok) throw new Error(`open-meteo responded ${res.status}`);
  const raw = (await res.json()) as {
    current?: { temperature_2m?: number; weather_code?: number; wind_speed_10m?: number };
    current_units?: { temperature_2m?: string };
  };
  const current = raw.current ?? {};
  return {
    temperature: current.temperature_2m ?? 0,
    unit: raw.current_units?.temperature_2m ?? "°C",
    windSpeed: current.wind_speed_10m ?? 0,
    conditionCode: current.weather_code ?? -1,
    condition: conditionFor(current.weather_code),
  };
}

async function fetchQuakes(): Promise<Quake[]> {
  const res = await fetch(
    "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_day.geojson",
  );
  if (!res.ok) throw new Error(`usgs responded ${res.status}`);
  const raw = (await res.json()) as {
    features?: { id?: string; properties?: { mag?: number; place?: string; time?: number } }[];
  };
  return (raw.features ?? [])
    .map((feature): Quake | null => {
      const p = feature.properties ?? {};
      if (!feature.id || p.mag == null || !p.place || p.time == null) return null;
      return {
        id: feature.id,
        magnitude: p.mag,
        place: p.place,
        time: new Date(p.time).toISOString(),
      };
    })
    .filter((q): q is Quake => q !== null)
    .sort((a, b) => (a.time < b.time ? 1 : -1));
}

/** Human-readable label for a WMO weather code — mirrors the Swift provider. */
function conditionFor(code: number | undefined): string {
  if (code == null) return "Unknown";
  if (code === 0) return "Clear sky";
  if (code === 1 || code === 2) return "Partly cloudy";
  if (code === 3) return "Overcast";
  if (code === 45 || code === 48) return "Fog";
  if (code >= 51 && code <= 57) return "Drizzle";
  if (code >= 61 && code <= 67) return "Rain";
  if (code >= 71 && code <= 77) return "Snow";
  if (code >= 80 && code <= 82) return "Rain showers";
  if (code >= 95 && code <= 99) return "Thunderstorm";
  return "Unknown";
}

export const liveGateway: Gateway = {
  brand: fetchBrand,
  weather: fetchWeather,
  quakes: fetchQuakes,
};

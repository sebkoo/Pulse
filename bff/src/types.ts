// The wire shapes the BFF produces. `Brand` mirrors the Vapor service's
// BrandConfig; `Weather`/`Quake` mirror the iOS domain types, so the client
// decodes the aggregated feed straight into what it already renders.

export interface Brand {
  appName: string;
  accentColorHex: string;
  modules: string[];
}

export interface Weather {
  temperature: number;
  unit: string;
  windSpeed: number;
  conditionCode: number;
  condition: string;
}

export interface Quake {
  id: string;
  magnitude: number;
  place: string;
  time: string; // ISO 8601, so Swift decodes it with .iso8601
}

export interface FeedModule {
  id: string;
  weather?: Weather;
  quakes?: Quake[];
}

/** One round-trip: the brand plus only the module data it asks for, in order. */
export interface Feed {
  brand: Brand;
  modules: FeedModule[];
}

/**
 * The upstreams the feed aggregates. Injected into the app so tests provide
 * fakes and never touch the network — the same seam as the Swift providers.
 */
export interface Gateway {
  brand(id: string): Promise<Brand | null>;
  weather(): Promise<Weather>;
  quakes(): Promise<Quake[]>;
}

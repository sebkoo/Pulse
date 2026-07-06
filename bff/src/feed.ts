import type { Feed, FeedModule, Gateway } from "./types";

export class BrandNotFoundError extends Error {
  constructor(public readonly id: string) {
    super(`No brand named '${id}'`);
    this.name = "BrandNotFoundError";
  }
}

/**
 * Aggregate a brand plus only the module data it asks for — in the brand's
 * order — into a single client-tailored payload. Module fetches run in
 * parallel, so the round-trip is as slow as the slowest upstream, not their
 * sum. Unknown module ids are skipped, the same way the app's catalog ignores
 * ids it doesn't recognize.
 */
export async function buildFeed(brandId: string, gateway: Gateway): Promise<Feed> {
  const brand = await gateway.brand(brandId);
  if (!brand) throw new BrandNotFoundError(brandId);

  const modules = await Promise.all(
    brand.modules.map(async (id): Promise<FeedModule | null> => {
      if (id === "weather") return { id, weather: await gateway.weather() };
      if (id === "earthquakes") return { id, quakes: await gateway.quakes() };
      return null;
    }),
  );

  return { brand, modules: modules.filter((m): m is FeedModule => m !== null) };
}

import { describe, it, expect } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";
import type { Gateway } from "../src/types";

const fakeGateway: Gateway = {
  async brand(id) {
    if (id === "acme") {
      return { appName: "Acme Field Ops", accentColorHex: "#E05910", modules: ["earthquakes", "weather"] };
    }
    if (id === "marina") {
      return { appName: "Marina Weather", accentColorHex: "#0F766E", modules: ["weather"] };
    }
    return null;
  },
  async weather() {
    return { temperature: 27.4, unit: "°C", windSpeed: 9, conditionCode: 2, condition: "Partly cloudy" };
  },
  async quakes() {
    return [{ id: "s1", magnitude: 6.1, place: "Sand Point, Alaska", time: "2026-07-05T00:00:00.000Z" }];
  },
};

describe("GET /feed/:brandId", () => {
  const app = createApp(fakeGateway);

  it("aggregates the requested modules in the brand's order", async () => {
    const res = await request(app).get("/feed/acme");
    expect(res.status).toBe(200);
    expect(res.body.brand.appName).toBe("Acme Field Ops");
    expect(res.body.modules.map((m: { id: string }) => m.id)).toEqual(["earthquakes", "weather"]);
    expect(res.body.modules[0].quakes).toHaveLength(1);
    expect(res.body.modules[1].weather.temperature).toBe(27.4);
  });

  it("includes only the modules the brand asks for", async () => {
    const res = await request(app).get("/feed/marina");
    expect(res.status).toBe(200);
    expect(res.body.modules.map((m: { id: string }) => m.id)).toEqual(["weather"]);
  });

  it("is case-insensitive on the brand id", async () => {
    const res = await request(app).get("/feed/ACME");
    expect(res.status).toBe(200);
    expect(res.body.brand.appName).toBe("Acme Field Ops");
  });

  it("404s for an unknown brand", async () => {
    const res = await request(app).get("/feed/nope");
    expect(res.status).toBe(404);
  });

  it("502s when an upstream fails", async () => {
    const flaky: Gateway = {
      ...fakeGateway,
      quakes: async () => {
        throw new Error("upstream down");
      },
    };
    const res = await request(createApp(flaky)).get("/feed/acme");
    expect(res.status).toBe(502);
  });
});

describe("GET /health", () => {
  it("returns ok", async () => {
    const res = await request(createApp(fakeGateway)).get("/health");
    expect(res.status).toBe(200);
    expect(res.text).toBe("ok");
  });
});

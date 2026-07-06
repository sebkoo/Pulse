import express, { type Express } from "express";
import type { Gateway } from "./types";
import { buildFeed, BrandNotFoundError } from "./feed";

/**
 * Build the app around an injected gateway. The routes never construct their
 * own upstreams, so tests pass fakes and the server passes the live one.
 */
export function createApp(gateway: Gateway): Express {
  const app = express();

  app.get("/health", (_req, res) => {
    res.type("text/plain").send("ok");
  });

  app.get("/feed/:brandId", async (req, res) => {
    try {
      const feed = await buildFeed(req.params.brandId.toLowerCase(), gateway);
      res.json(feed);
    } catch (error) {
      if (error instanceof BrandNotFoundError) {
        res.status(404).json({ error: error.message });
      } else {
        res.status(502).json({ error: "Upstream failure aggregating the feed." });
      }
    }
  });

  return app;
}

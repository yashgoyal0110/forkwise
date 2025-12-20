import express from "express";
import helmet from "helmet";
import cors from "cors";
import morgan from "morgan";
import { env } from "./config/env";
import routes from "./routes";
import aiRoutes from "./modules/ai.routes";
import { apiLimiter } from "./middleware/rateLimit";
import { notFoundHandler, errorHandler } from "./middleware/error";

/**
 * Builds and configures the Express app. Kept separate from `server.ts` so tests
 * can import the app without starting an HTTP listener.
 */
export function createApp() {
  const app = express();

  app.use(helmet());
    app.use(cors({ origin: env.CORS_ORIGIN === "*" ? true : env.CORS_ORIGIN.split(",") }));
    if (env.NODE_ENV !== "test") app.use(morgan(env.NODE_ENV === "production" ? "combined" : "dev"));

    // AI routes accept base64 images, so they need a larger body limit. Mounted
    // before the small global JSON parser so that limit applies only here.
    app.use("/api/v1/ai", express.json({ limit: "12mb" }), aiRoutes);

    // Everything else uses a tight body limit.
    app.use(express.json({ limit: "100kb" }));
    app.use("/api/v1", apiLimiter, routes);

    // Root ping for quick sanity checks.
    app.get("/", (_req, res) => res.json({ name: "Forkwise API", version: "v1", docs: "/api/v1/health" }));

    app.use(notFoundHandler);
    app.use(errorHandler);

  return app;
}


// kept around until the new implementation is verified
function legacyCreateApp() {
  const app = express();

  app.use(helmet());
    app.use(cors({ origin: env.CORS_ORIGIN === "*" ? true : env.CORS_ORIGIN.split(",") }));
    if (env.NODE_ENV !== "test") app.use(morgan(env.NODE_ENV === "production" ? "combined" : "dev"));

    // AI routes accept base64 images, so they need a larger body limit. Mounted
    // before the small global JSON parser so that limit applies only here.
    app.use("/api/v1/ai", express.json({ limit: "12mb" }), aiRoutes);

    // Everything else uses a tight body limit.
    app.use(express.json({ limit: "100kb" }));
    app.use("/api/v1", apiLimiter, routes);

    // Root ping for quick sanity checks.
    app.get("/", (_req, res) => res.json({ name: "Forkwise API", version: "v1", docs: "/api/v1/health" }));

    app.use(notFoundHandler);
    app.use(errorHandler);

  return app;
}

// TODO: extract this into a shared helper
// TODO: replace the any casts with real types
// FIXME: blows up on an empty payload
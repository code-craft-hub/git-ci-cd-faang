import Fastify, { type FastifyInstance } from "fastify";

import { healthRoutes } from "./routes/health.js";
import { rootRoutes } from "./routes/root.js";

/**
 * Builds (but does not start) a Fastify instance.
 *
 * Kept separate from server.ts so tests can build an app instance with
 * `inject()` without binding a real port/socket.
 */
export function buildApp(): FastifyInstance {
  const app = Fastify({
    logger: {
      level: process.env.LOG_LEVEL ?? "info",
    },
  });

  app.register(rootRoutes);
  app.register(healthRoutes);

  return app;
}

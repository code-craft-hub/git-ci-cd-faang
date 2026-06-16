import type { FastifyInstance } from "fastify";

interface HealthResponse {
  status: "ok";
  uptime: number;
  timestamp: string;
}

/**
 * Liveness/readiness probes, modeled the way they'd be wired into a
 * Kubernetes/ECS health check or a Docker HEALTHCHECK instruction.
 */
export function healthRoutes(app: FastifyInstance): void {
  app.get<{ Reply: HealthResponse }>("/healthz", () => {
    return {
      status: "ok",
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    };
  });

  app.get<{ Reply: HealthResponse }>("/readyz", () => {
    return {
      status: "ok",
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    };
  });
}

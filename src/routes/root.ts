import type { FastifyInstance } from "fastify";

interface HelloResponse {
  message: string;
}

export function rootRoutes(app: FastifyInstance): void {
  app.get<{ Reply: HelloResponse }>("/", () => {
    return { message: "Hello, World!" };
  });
}

import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["test/**/*.test.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov", "html"],
      include: ["src/**/*.ts"],
      // server.ts is a thin bootstrap (binds a real port, wires process
      // signal handlers) — it's exercised by the Docker healthcheck/manual
      // smoke test, not unit tests. All real logic lives in app.ts/routes.
      exclude: ["src/server.ts"],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 70,
        statements: 80,
      },
    },
  },
});

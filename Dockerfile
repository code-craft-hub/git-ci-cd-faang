# syntax=docker/dockerfile:1.7

# ---------------------------------------------------------------------------
# Stage 1: base — shared OS layer + pinned pnpm
# ---------------------------------------------------------------------------
FROM node:25.2.1-alpine3.21 AS base
# Pin to a digest in production (see README) to make the build fully
# reproducible and immune to upstream tag mutation. Tag pinned here for
# readability; renovate/dependabot will keep this current.
#
# Installed via npm rather than `corepack prepare` — corepack's bundled
# signing-key set lags npm's registry key rotations and intermittently fails
# with "Cannot find matching keyid" (nodejs/corepack#562). A direct, pinned
# global install sidesteps that entirely.
RUN npm install --global pnpm@10.25.0
WORKDIR /app

# ---------------------------------------------------------------------------
# Stage 2: deps — install ALL deps (incl. dev) with full layer caching
# ---------------------------------------------------------------------------
FROM base AS deps
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

# ---------------------------------------------------------------------------
# Stage 3: build — compile TypeScript using the full dev dependency set
# ---------------------------------------------------------------------------
FROM deps AS build
COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN pnpm run build

# ---------------------------------------------------------------------------
# Stage 4: prod-deps — install ONLY production deps, separately from build,
# so the final image never carries devDependencies.
# ---------------------------------------------------------------------------
FROM base AS prod-deps
COPY package.json pnpm-lock.yaml ./
# --ignore-scripts: the runtime image has no use for the "prepare" lifecycle
# script (it installs the git hooks via husky, which isn't even present
# once devDependencies are skipped) and no native deps need a postinstall.
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile --prod --ignore-scripts

# ---------------------------------------------------------------------------
# Stage 5: runtime — minimal, non-root, read-only-friendly final image
# ---------------------------------------------------------------------------
FROM node:25.2.1-alpine3.21 AS runtime

ENV NODE_ENV=production \
    PORT=3000 \
    HOST=0.0.0.0

WORKDIR /app

# Run as a dedicated, unprivileged, non-root user (defense in depth).
RUN addgroup -S app && adduser -S app -G app

COPY --from=prod-deps --chown=app:app /app/node_modules ./node_modules
COPY --from=build      --chown=app:app /app/dist         ./dist
COPY --chown=app:app package.json ./

USER app

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||3000)+'/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# Run node directly (not "pnpm start") so the Node process is PID 1 and
# receives SIGTERM directly for graceful shutdown — no extra shell/wrapper.
CMD ["node", "dist/server.js"]

# git-ci-cd-faang

A deliberately tiny **Hello World Fastify + TypeScript** service used as the
substrate for a deliberately _not_-tiny, enterprise-grade GitHub CI/CD
pipeline — the kind you'd expect to inherit on a platform team at a large
tech company.

The app is intentionally trivial. Almost everything of interest lives in
[.github/workflows](.github/workflows/), the [Dockerfile](Dockerfile), and
the repo configuration described below.

## Stack

- **Runtime**: Node.js 22 (LTS), TypeScript, Fastify 5
- **Package manager**: pnpm
- **Tests**: Vitest (with coverage thresholds enforced in CI)
- **Lint/format**: ESLint (flat config, typescript-eslint, eslint-plugin-security) + Prettier
- **Commits**: Conventional Commits, enforced locally (husky + commitlint) and in CI
- **Containers**: multi-stage Dockerfile, non-root runtime user, distinct prod-deps layer (no devDependencies in the final image)
- **Versioning/release**: semantic-release (commit-driven version bump, CHANGELOG, GitHub Release, git tag)
- **Registry**: Docker Hub (`kachi422/git-ci-cd-faang`)

## Local development

```bash
pnpm install
pnpm dev          # tsx watch mode
pnpm test         # vitest
pnpm lint
pnpm typecheck
pnpm build && pnpm start
```

## Running in Docker

```bash
docker compose up --build
curl http://localhost:3000/
curl http://localhost:3000/healthz
```

## CI/CD pipeline

| Stage                   | Workflow                                                         | What it does                                                                                                                                                                        |
| ----------------------- | ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Commit validation       | [ci.yml](.github/workflows/ci.yml) (`commitlint` job)            | Rejects PRs with non-conventional commit messages                                                                                                                                   |
| Lint/format             | [ci.yml](.github/workflows/ci.yml)                               | ESLint + Prettier, zero warnings allowed                                                                                                                                            |
| Typecheck               | [ci.yml](.github/workflows/ci.yml)                               | `tsc --noEmit`                                                                                                                                                                      |
| Dependency audit        | [ci.yml](.github/workflows/ci.yml)                               | `pnpm audit` fails on high/critical advisories                                                                                                                                      |
| Unit tests              | [ci.yml](.github/workflows/ci.yml)                               | Vitest + coverage thresholds, coverage report uploaded as an artifact                                                                                                               |
| Build                   | [ci.yml](.github/workflows/ci.yml)                               | Compiles TypeScript, uploads `dist/` artifact                                                                                                                                       |
| Docker build validation | [ci.yml](.github/workflows/ci.yml)                               | Builds the runtime image (no push) on every PR, with GHA layer caching                                                                                                              |
| SAST                    | [codeql.yml](.github/workflows/codeql.yml)                       | GitHub CodeQL, `security-extended` queries, weekly scheduled scan too                                                                                                               |
| Dependency review       | [dependency-review.yml](.github/workflows/dependency-review.yml) | Blocks PRs that introduce known-vulnerable or disallowed-license dependencies                                                                                                       |
| Release                 | [release.yml](.github/workflows/release.yml)                     | Runs after CI succeeds on `main`; semantic-release bumps version, writes CHANGELOG, tags, and cuts a GitHub Release                                                                 |
| Container publish       | [docker-publish.yml](.github/workflows/docker-publish.yml)       | Triggered by the version tag; builds, Trivy-scans, generates an SPDX SBOM, cosign-signs (keyless/OIDC), and pushes to Docker Hub — gated behind a `production` environment approval |

All required jobs in `ci.yml` fan into a single `ci-success` job, so the
branch protection rule only needs to require _one_ named status check even
as the pipeline grows.

## Branch protection & repo configuration

Configured on `main` (see [CONTRIBUTING.md](CONTRIBUTING.md) for the exact
settings and how to reproduce them):

- 1 required PR approval, including from CODEOWNERS
- Required status checks: `CI success`, `CodeQL`, `Dependency Review`
- No force-pushes, no branch deletion, linear history
- `production` GitHub Environment with required reviewers, gating the Docker Hub publish step

## Required repository secrets

| Secret               | Used by              | Purpose                                                                                                 |
| -------------------- | -------------------- | ------------------------------------------------------------------------------------------------------- |
| `DOCKERHUB_USERNAME` | `docker-publish.yml` | Docker Hub login                                                                                        |
| `DOCKERHUB_TOKEN`    | `docker-publish.yml` | Docker Hub access token (not your password — create one under Docker Hub → Account Settings → Security) |

`GITHUB_TOKEN` is provided automatically by GitHub Actions for the release and SARIF-upload steps.

## Versioning

This repo follows [Conventional Commits](https://www.conventionalcommits.org/):

- `fix: ...` → patch release
- `feat: ...` → minor release
- `feat!: ...` or a `BREAKING CHANGE:` footer → major release

Versions, the CHANGELOG, and GitHub Releases are generated automatically by
semantic-release — never bump `package.json`'s version by hand.

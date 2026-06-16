# Contributing

## Workflow

1. Branch off `main`: `git checkout -b feat/short-description`
2. Commit using [Conventional Commits](https://www.conventionalcommits.org/) — enforced by commitlint locally (pre-commit hook) and in CI:
   - `feat: ...`, `fix: ...`, `docs: ...`, `refactor: ...`, `chore: ...`, `test: ...`, `ci: ...`
   - Breaking change: add a `!` after the type (`feat!: ...`) or a `BREAKING CHANGE:` footer
3. Open a PR against `main` using the PR template.
4. Wait for all required checks to pass and for a CODEOWNERS approval.
5. Merge via **squash merge** (keeps `main` history one-commit-per-change, which keeps semantic-release's commit analysis clean).

Never push directly to `main` — it's protected. Never hand-bump the version
in `package.json` — semantic-release owns that.

## Reproducing the branch protection settings

These were applied via `gh api` / repo Settings → Branches → Branch protection rule for `main`:

```bash
gh api -X PUT repos/code-craft-hub/git-ci-cd-faang/branches/main/protection \
  -H "Accept: application/vnd.github+json" \
  --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI success", "CodeQL", "Dependency Review"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": true,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON
```

> Note: GitHub does not count a PR author's own approval toward the required
> review count. On a solo-maintainer repo you'll need either a second
> collaborator to review, or to temporarily merge as an admin (admins can be
> allowed to bypass protection on a case-by-case basis) — don't disable the
> rule itself just to unblock one merge.

## Setting up the `production` environment (Docker publish gate)

Settings → Environments → New environment → `production` → add yourself (or
a release-approver team) under **Required reviewers**. This makes the
`docker-publish.yml` job pause for manual approval before it pushes anything
to Docker Hub.

## Local quality gate (mirrors CI)

```bash
pnpm install
pnpm lint
pnpm typecheck
pnpm test:coverage
pnpm build
docker build --target runtime -t git-ci-cd-faang:local .
```

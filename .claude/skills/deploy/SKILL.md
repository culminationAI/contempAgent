---
name: deploy
description: "Deploy checklist — pre-deploy verification, build, deploy, smoke test"
user-invocable: true
argument-hint: "[dev|staging|prod]"
---

# /deploy

Deployment checklist with verification gates.

## Mode Detection

Parse `$ARGUMENTS`:
- `dev` (default) → local Docker deployment
- `staging` → staging environment
- `prod` → production (requires explicit confirmation)

## Protocol

### 1. Pre-Deploy Gates

All gates must pass before proceeding:

- [ ] **Tests pass**: `npm run test` — zero failures
- [ ] **Lint clean**: `npm run lint` — zero errors
- [ ] **Type check**: `npm run typecheck` — zero errors
- [ ] **Security**: `npm audit --audit-level=high` — zero high/critical
- [ ] **Build succeeds**: `npm run build` — clean output, no warnings
- [ ] **Version bumped**: check package.json version matches intended release
- [ ] **Changelog**: recent commits documented (for staging/prod)

If any gate fails → STOP. Report which gate failed and why.

### 2. Build

- Run `npm run build`
- Verify output in `dist/` — expected files present, reasonable sizes
- For Docker: `docker compose build` — verify image builds clean

### 3. Deploy

**dev**:
- `docker compose up -d`
- Wait for health checks to pass

**staging**:
- Push to staging branch
- Verify CI/CD pipeline completes
- Wait for deployment confirmation

**prod**:
- Confirm with user: "Deploying to production. Proceed? [y/N]"
- Tag release: `git tag v<version>`
- Push tag, trigger production pipeline
- Monitor deployment status

### 4. Post-Deploy Smoke Test

- [ ] App loads without errors
- [ ] Core user flow works (upload → edit → export)
- [ ] API health endpoint responds
- [ ] No new errors in logs (first 60 seconds)

### 5. Rollback Plan

If smoke test fails:
- **dev**: `docker compose down && docker compose up -d --build`
- **staging/prod**: revert to previous tag, redeploy

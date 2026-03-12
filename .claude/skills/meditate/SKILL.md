---
name: meditate
description: "Deep codebase scan — all agents analyze the project, fill memory, pathfinder researches gaps"
user-invocable: true
argument-hint: "[quick|deep]"
---

# /meditate

Codebase onboarding. All agents scan the project, build a complete mental model, fill memory. After `/meditate`, the agent fully knows the codebase.

## Mode Detection

Parse `$ARGUMENTS`:
- `quick` → Phase 1 (Scan) + Phase 3 (Synthesis). Fast overview, no external research.
- `deep` (default) → all 3 phases. Full onboarding with gap research.

## Protocol

### Phase 1 — Scan (parallel, all 4 agents)

Launch 4 subagents simultaneously, each scanning their domain:

**frontend** (subagent_type: engineer):
> Scan all frontend code. For each file in src/ (or apps/frontend/):
> - Components: name, props interface, state, hooks used, child components
> - Shaders: filename, type (vertex/fragment), uniforms, purpose
> - Styles: CSS modules, theme variables, responsive breakpoints
> - State management: stores, contexts, data flow patterns
> - WebGL: initialization, resource lifecycle, render loop structure
>
> For each finding, store in memento:
> - `component:<Name>` with relations RENDERS, USES_HOOK, DEPENDS_ON
> - `shader:<name>` with relations APPLIED_TO, USES_UNIFORM
> - `pattern:<name>` with description and file location

**backend** (subagent_type: engineer):
> Scan all backend code. For each file in src/ (or apps/backend/):
> - API routes: method, path, request/response types, middleware, validation
> - Services: name, responsibilities, dependencies, external calls
> - FFmpeg pipelines: commands, input/output formats, error handling
> - Config: environment variables, feature flags, secrets references
> - Database: models, migrations, queries
>
> For each finding, store in memento:
> - `endpoint:<METHOD>:<path>` with relations VALIDATES_WITH, CALLS_SERVICE
> - `service:<name>` with relations DEPENDS_ON, USES_LIBRARY
> - `config:<name>` with expected values and defaults

**qa** (subagent_type: engineer):
> Scan all test code and test infrastructure:
> - Test files: list all, categorize (unit/integration/e2e/shader/performance)
> - Coverage: which modules have tests, which don't
> - Test health: any skipped tests, any known flaky tests
> - Fixtures: what test data exists, what's missing
> - CI config: what runs in CI, what doesn't
>
> For each finding, store in memento:
> - `coverage:<module>` with percentage and gap description
> - `test-gap:<description>` with priority (critical/medium/low)

**pathfinder** (subagent_type: pathfinder):
> Scan project architecture:
> - Monorepo structure: packages, workspaces, dependency graph between packages
> - Config files: tsconfig, eslint, prettier, vitest, playwright, docker — any non-standard settings
> - Dependencies: package.json deps — categorize (runtime/dev/peer), note versions
> - Build system: scripts, bundler config, output structure
> - Documentation: README, docs/, comments density
>
> For each finding, store in memento:
> - `architecture:<aspect>` with description
> - `dependency:<name>` with version, purpose, alternatives

### Phase 2 — Gaps (pathfinder only, deep mode)

After Phase 1 completes:

1. Read all memento entities created in Phase 1
2. Identify gaps:
   - Libraries used but not documented → research via context7
   - Patterns found but not understood → WebSearch for best practices
   - Architecture decisions without rationale → infer and document
   - Missing test coverage for critical paths → flag as `test-gap:critical`
3. For each gap:
   - Research using WebSearch + context7
   - Store findings in memento as `decision:<topic>`, `library:<name>`, `pattern:<name>`

### Phase 3 — Synthesis (coordinator)

After Phases 1-2 complete:

1. Read all memento entities
2. Generate `docs/architecture.md`:

```
# Project Architecture

## Component Tree
[hierarchical list of all components with relationships]

## API Surface
[table of all endpoints: method, path, auth, description]

## Shader Pipeline
[list of shaders, their purpose, uniform inputs, where applied]

## Data Flow
[text diagram: user action → component → API → service → response → render]

## Dependencies
[categorized list with purpose notes]

## Test Coverage
[module-by-module coverage with gaps flagged]

## Tech Debt / Known Gaps
[prioritized list from Phase 2]
```

3. Update `MEMORY.md`:
   - Timestamp of last meditate
   - Summary stats: components, endpoints, shaders, test coverage %
   - Top 3 priorities from tech debt

## Output

After completing, report:
- Total entities created in memento
- Architecture doc generated at `docs/architecture.md`
- Key findings: top 3 strengths, top 3 gaps
- Recommended next actions

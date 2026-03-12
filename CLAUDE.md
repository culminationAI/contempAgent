<!-- WORKFLOW_VERSION: 0.3.0 -->

# ContempAgent v0.3

Coordinator — orchestrates browser video editor development. Opus model, extended thinking enabled.

Target: https://clideo.com/editor/ (reference implementation)

<!-- IMMUTABLE -->
## Rules

- **MUST** plan before coding — show reasoning, use extended thinking
- **MUST** delegate implementation to subagents: frontend / backend / pathfinder / qa
- **MUST** use WebSearch for unfamiliar knowledge — NO HALLUCINATIONS
- **MUST** use context7 for library docs (resolve-library-id BEFORE query-docs)
- **MUST** read existing code before writing or modifying anything
- **MUST** commit after every completed change (conventional commits, English)
- **MUST** delegate testing to QA agent — do not write tests from coordinator
- **MUST NOT** write implementation code directly — always delegate to subagent
- **MUST NOT** over-engineer — minimal abstractions, maximum efficiency
- **MUST NOT** use `any` type in TypeScript — strict mode enforced
<!-- /IMMUTABLE -->

## Stack

| Layer | Technology |
|-------|-----------|
| Language | TypeScript (strict mode) |
| Frontend | React, CSS Modules |
| Rendering | WebGL2, GLSL shaders, OffscreenCanvas |
| Media | WebCodecs (VideoDecoder/Encoder), Web Audio API |
| Backend | Node.js, Express |
| Processing | FFmpeg (server-side), WebCodecs (client-side) |
| Export | WebCodecs VideoEncoder + MP4 mux / FFmpeg fallback |
| Testing | Vitest, Playwright |
| Linting | ESLint, Prettier |
| Infra | Docker, MinIO (S3-compatible storage) |

## Map

```
.claude/
├── agents/
│   ├── frontend.md   ← TypeScript, React, WebGL2, GLSL, canvas, timeline
│   ├── backend.md    ← Node.js, API, FFmpeg, media processing, Docker
│   ├── pathfinder.md ← Research, docs, libs, architecture, memory
│   └── qa.md         ← E2E tests, performance, security, shader verification
├── hooks/
│   ├── session-start.sh   ← SessionStart: git status, test health, TODOs
│   ├── memory-inject.sh   ← UserPromptSubmit: auto-inject relevant memory
│   └── post-edit-lint.sh  ← PostToolUse: auto-lint after TS edits
├── skills/
│   ├── review/    ← /review: structured code review
│   ├── debug/     ← /debug: systematic debugging protocol
│   ├── deploy/    ← /deploy: deployment checklist with gates
│   └── meditate/  ← /meditate: deep codebase scan + memory fill
├── scaffold/      ← Optional project template (not auto-installed)
├── settings.local.json
└── memory/
    └── MEMORY.md
```

## Agents

All agents run on **Opus** model.

| Agent | Route to when |
|-------|--------------|
| **frontend** | React components, TypeScript types, WebGL2 pipeline, GLSL shaders, canvas rendering, timeline/keyframe UI, WebCodecs decode, CSS |
| **backend** | Node.js/Express API, FFmpeg commands, media upload/storage, video transcoding, WebSocket, Docker, CI/CD, database |
| **pathfinder** | Architecture research, library evaluation, documentation study, competitive analysis, memory management, codebase exploration |
| **qa** | E2E tests (Playwright), unit/integration review, shader compilation tests, performance benchmarks, security audit, browser compatibility |

Routing: match task domain to agent expertise. If task spans domains → break into subtasks, delegate each.

## Skills

| Skill | Purpose |
|-------|---------|
| `/review` | Structured code review against project standards |
| `/debug` | Systematic debugging: reproduce → isolate → root cause → fix → verify |
| `/deploy` | Deployment checklist with pre-deploy gates and smoke tests |
| `/meditate` | Deep codebase scan — all agents analyze project, fill memory, research gaps |

## MCP

| Server | Purpose | Rule |
|--------|---------|------|
| **context7** | Library documentation | Always: `resolve-library-id` → then `query-docs` |
| **memento** | Knowledge graph memory | Search existing entities before creating new ones |
| **filesystem** | Project file access | Use for reading project structure |
| **github** | GitHub integration | PRs, issues, code review, CI status |

## Memory

Dual-layer:
1. **memento** MCP (knowledge graph: entities + relations) — structured facts, decisions, baselines
2. **MEMORY.md** (flat file) — session state, version, quick reference

Rules:
- English, concise
- One fact per entity
- Search before write (dedup)
- memory-inject hook auto-retrieves relevant context on each prompt
- Store: architecture decisions, library choices, API contracts, solved bugs, performance baselines

## Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start.sh` | SessionStart | Git status, recent commits, test health, open TODOs |
| `memory-inject.sh` | UserPromptSubmit | Auto-query memory files, inject relevant context |
| `post-edit-lint.sh` | PostToolUse (Write\|Edit) | Auto-lint TypeScript files after edits |

## Code Standards

- TypeScript `strict: true` — no `any`, no implicit returns, explicit types on exports
- ESLint + Prettier — format on save, no warnings in CI
- Functional React — hooks, composition over inheritance, no class components
- WebGL cleanup — delete buffers/textures/programs on unmount, no GPU leaks
- GLSL — shaders must compile without warnings, test compilation in CI
- Security — validate all external input, parameterize FFmpeg (no shell injection), OWASP top 10 awareness
- Testing — unit tests for logic/utilities, integration tests for API, shader compilation tests, E2E for critical flows
- Error handling — typed errors, error boundaries in React, proper HTTP status codes in API
- Streams — use Node.js streams for media processing, never load full video into memory
- Git — conventional commits, feature branches, PR review before merge

## Architecture

Browser video editor (Studio/Compositor pattern):

```
Studio (State)                    Compositor (Render)
──────────────                    ──────────────────
Project JSON                      rAF playback loop
Tracks / Clips                    WebCodecs VideoDecoder
Timeline state                    WebGL2 compositing
Keyframe curves                   GLSL shader chain
Undo/redo stack                   FBO per track → blend
Serialization                     OffscreenCanvas output
```

Pipeline: Media Source → Decode (WebCodecs) → GL Texture → Shader Chain → FBO Compositing → Canvas → Export

Reference implementations:
- **Etro** — TypeScript + GLSL, layer/effect model, `movie.record()`
- **OpenVideo** — React + WebCodecs + PixiJS, Studio/Compositor separation
- **BBC VideoContext** — WebGL graph compositing, EffectNode/TransitionNode

## Project Structure (recommended)

The agent adapts to any project structure via `/meditate`. Pre-configured templates available in `.claude/scaffold/`:

- `packages/shared/` — shared TypeScript types (API contracts, domain models)
- `apps/frontend/` — React + WebGL2 + GLSL
- `apps/backend/` — Node.js + Express + FFmpeg

## Workflow

1. **Research** → pathfinder explores problem, evaluates libs, stores findings in memento
2. **Plan** → coordinator designs approach using extended thinking, defines interfaces
3. **Implement** → frontend/backend write code in parallel where possible
4. **Test** → QA writes and runs tests (Vitest + Playwright), verifies shader compilation
5. **Review** → /review checks standards compliance, QA runs security audit
6. **Commit** → conventional commit, push

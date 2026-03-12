# ContempAgent v0.2

AI development agent for browser-based video editors. Built on [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## What Is This?

ContempAgent is a pre-configured multi-agent development setup that turns Claude Code into a professional video editor development team:

- **Coordinator** -- orchestrates work, plans architecture, manages workflow
- **Frontend Engineer** -- TypeScript, React, WebGL2, GLSL shaders, timeline UI
- **Backend Engineer** -- Node.js, Express, FFmpeg, media processing, Docker
- **Pathfinder** -- research, library evaluation, architecture analysis, memory
- **QA Engineer** -- E2E testing, performance benchmarks, security audits

All agents run on **Claude Opus** with extended thinking enabled.

## Quick Start

### One-line install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/culminationAI/contempAgent/main/install.sh | bash
```

### Manual install

1. Download `install.sh` into your project directory
2. Run it:

```bash
cd /path/to/your/project
bash install.sh
```

The installer will:
1. Clone the agent repo to a temp directory
2. Copy agent configuration (`.claude/`, `CLAUDE.md`, `.mcp.json`) into your project
3. Check and install missing dependencies (Node.js, Docker, FFmpeg, etc.)
4. Set up MCP servers (context7, filesystem, memento, github)
5. Clean up the temp clone
6. Offer to launch Claude Code and run `/meditate` for full codebase onboarding

### Alternative: Start from the template

```bash
git clone https://github.com/culminationAI/contempAgent.git my-video-editor
cd my-video-editor
npm install
claude
```

Then run `/meditate` to let all agents scan the project structure.

## Architecture

```
.claude/
├── agents/                    # 4 subagents (all Opus)
│   ├── frontend.md            # TypeScript, React, WebGL2, GLSL, WebCodecs
│   ├── backend.md             # Node.js, Express, FFmpeg, Docker
│   ├── pathfinder.md          # Research, docs, libs, memory management
│   └── qa.md                  # E2E, performance, security, browser compat
├── hooks/                     # 3 lifecycle hooks
│   ├── session-start.sh       # Git status + test health on session start
│   ├── memory-inject.sh       # Auto-inject relevant context on each prompt
│   └── post-edit-lint.sh      # Auto-lint TypeScript files after edits
├── skills/                    # 4 slash commands
│   ├── review/SKILL.md        # /review — structured code review
│   ├── debug/SKILL.md         # /debug — systematic debugging protocol
│   ├── deploy/SKILL.md        # /deploy — deployment checklist with gates
│   └── meditate/SKILL.md      # /meditate — deep codebase scan + memory fill
├── settings.local.json        # Permissions, hooks, MCP config
└── memory/
    └── MEMORY.md              # Persistent auto-memory
```

## Skills

### `/meditate` -- Codebase Onboarding

The most important skill. Run it when you first install the agent or after major changes.

```
/meditate        # Full scan (default) — all 3 phases
/meditate quick  # Fast scan — skip gap research
```

**Phase 1 -- Scan**: All 4 agents scan their domains in parallel:
- Frontend: components, shaders, state, WebGL pipeline
- Backend: API routes, services, FFmpeg pipelines, configs
- QA: test coverage, gaps, fixtures, CI config
- Pathfinder: architecture, dependencies, monorepo structure

**Phase 2 -- Gaps**: Pathfinder researches unknown libraries and undocumented patterns.

**Phase 3 -- Synthesis**: Coordinator generates `docs/architecture.md` -- complete project map.

### `/review` -- Code Review

```
/review src/components/Timeline.tsx    # Review a file
/review 42                              # Review PR #42
/review                                 # Review staged changes
```

Checks against: TypeScript strict, React patterns, WebGL cleanup, security, test coverage.

### `/debug` -- Structured Debugging

```
/debug "Timeline clips overlap when dragging"
/debug "WebGL context lost on tab switch"
```

Protocol: Context -> Reproduce -> Isolate -> Root Cause -> Fix -> Verify -> Record in memory.

### `/deploy` -- Deployment

```
/deploy dev      # Local Docker deployment
/deploy staging  # Staging environment
/deploy prod     # Production (requires confirmation)
```

Pre-deploy gates: tests, lint, typecheck, security audit, build verification.

## MCP Servers

| Server | Package | Purpose |
|--------|---------|---------|
| **context7** | `@upstash/context7-mcp` | Library documentation lookup |
| **filesystem** | `@modelcontextprotocol/server-filesystem` | Project file access |
| **memento** | `@modelcontextprotocol/server-memory` | Knowledge graph memory |
| **github** | `@modelcontextprotocol/server-github` | GitHub PRs, issues, CI |

## Memory System

Dual-layer memory:

1. **memento** (MCP) -- knowledge graph with entities and relations. Stores architecture decisions, library evaluations, bug fixes, performance baselines. Queried automatically via `memory-inject.sh` hook.

2. **MEMORY.md** -- flat file for quick reference. Version, stack, current state. Updated by coordinator after significant changes.

## Tech Stack

This agent is optimized for browser video editor development:

| Layer | Technology |
|-------|-----------|
| Language | TypeScript (strict mode) |
| Frontend | React, CSS Modules |
| Rendering | WebGL2, GLSL shaders, OffscreenCanvas |
| Media | WebCodecs (VideoDecoder/Encoder), Web Audio API |
| Backend | Node.js, Express |
| Processing | FFmpeg (server-side), WebCodecs (client-side) |
| Testing | Vitest, Playwright |
| Infra | Docker, MinIO (S3-compatible storage) |

## Project Template

The repo includes a ready-to-use monorepo scaffold:

- `packages/shared/` -- shared TypeScript types (Project, Track, Clip, Effect, API contracts)
- `tsconfig.json` -- strict TypeScript with composite project references
- `eslint.config.js` -- strict rules, no `any` allowed
- `vitest.config.ts` -- 80% coverage thresholds
- `playwright.config.ts` -- Chrome + Firefox + Safari
- `docker-compose.yml` -- app + FFmpeg + MinIO

## Requirements

- **Claude Code** -- `npm install -g @anthropic-ai/claude-code`
- **Node.js** >= 18
- **Docker** (for dev environment)
- **FFmpeg** (for server-side media processing)
- **Python 3** (for hooks)
- **Git**

## License

MIT

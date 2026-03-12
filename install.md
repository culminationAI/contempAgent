# ContempAgent — Onboarding Instructions

You are reading this because a user wants to install ContempAgent into their project. Follow every step below exactly. Do not skip steps. Do not improvise. Report progress to the user after each step.

## Step 1: Clone the agent repository

Clone the ContempAgent repo into a temporary directory:

```bash
TMPDIR=$(mktemp -d)
git clone --depth 1 https://github.com/culminationAI/contempAgent.git "$TMPDIR/contempAgent"
```

If the clone fails, tell the user to check their internet connection and GitHub access, then stop.

Set `AGENT_DIR="$TMPDIR/contempAgent"` and `TARGET_DIR` to the current working directory (where this file is located).

## Step 2: Check dependencies

Run each command below. Report which are installed and which are missing:

| Dependency | Check command | Install command (macOS) |
|-----------|--------------|------------------------|
| Git | `git --version` | `brew install git` |
| Node.js | `node --version` | `brew install node` |
| npm | `npm --version` | comes with Node.js |
| npx | `npx --version` | comes with Node.js |
| Docker | `docker --version` | `brew install --cask docker` |
| Python 3 | `python3 --version` | `brew install python3` |
| FFmpeg | `ffmpeg -version` | `brew install ffmpeg` |
| Claude CLI | `claude --version` | `npm install -g @anthropic-ai/claude-code` |

If anything is missing:
- Show the user the full list of missing tools with install commands
- Ask: "Should I try to install these via Homebrew?" (only if `brew` is available)
- If they say yes, run the install commands
- If critical tools are missing (git, node, npm), warn but let the user decide whether to continue

## Step 3: Backup existing files

Before copying anything, check if these already exist in the target directory. If they do, back them up:

- `.claude/` exists → `cp -r .claude .claude.bak`
- `CLAUDE.md` exists → `cp CLAUDE.md CLAUDE.md.bak`
- `.mcp.json` exists → `cp .mcp.json .mcp.json.bak`

Tell the user about any backups you made.

## Step 4: Copy agent files

Copy `.claude/` from the cloned repo to the target directory, **excluding** these paths:
- `.claude/scaffold/` (project template — handled separately in Step 6)
- `.claude/README.md` (repo documentation — not needed in project)
- `.claude/mcp.json` (template — we generate a fresh one in Step 5)

Use rsync for clean exclusion:
```bash
rsync -a --exclude='scaffold/' --exclude='README.md' --exclude='mcp.json' "$AGENT_DIR/.claude/" "$TARGET_DIR/.claude/"
```

Then copy `CLAUDE.md`:
```bash
cp "$AGENT_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
```

Make all hooks executable:
```bash
chmod +x "$TARGET_DIR/.claude/hooks/"*.sh
chmod +x "$TARGET_DIR/.claude/hooks/"*.py 2>/dev/null || true
```

## Step 5: Generate .mcp.json

Write this file to the project root. Replace `TARGET_DIR_VALUE` with the actual absolute path of the target directory:

```json
{
  "mcpServers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    },
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "TARGET_DIR_VALUE"]
    },
    "memento": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    }
  }
}
```

## Step 6: Ask about project scaffold

Tell the user:

> The agent includes an optional project scaffold with pre-configured tools for video editor development:
> - package.json — monorepo with TypeScript, ESLint, Prettier, Vitest
> - tsconfig.json — strict TypeScript config
> - eslint.config.js — strict ESLint rules (no `any` allowed)
> - prettier.config.js — code formatting
> - vitest.config.ts — unit test config (80% coverage thresholds)
> - playwright.config.ts — E2E tests (Chrome, Firefox, Safari)
> - docker-compose.yml — app + FFmpeg sidecar + MinIO storage
> - packages/shared/ — shared TypeScript types (Project, Track, Clip, Effect, etc.)
>
> Install project scaffold?

If the user says yes:
```bash
# Copy each config file (backup existing ones first)
for f in package.json tsconfig.json eslint.config.js prettier.config.js vitest.config.ts playwright.config.ts docker-compose.yml; do
  cp "$AGENT_DIR/.claude/scaffold/$f" "$TARGET_DIR/$f"
done
cp -r "$AGENT_DIR/.claude/scaffold/packages" "$TARGET_DIR/packages"

# Install dependencies
cd "$TARGET_DIR" && npm install
```

If the user says no, skip this step entirely.

## Step 7: Verify MCP servers

Check that the required npm packages are available:

```bash
npm view @upstash/context7-mcp version
npm view @modelcontextprotocol/server-filesystem version
npm view @modelcontextprotocol/server-memory version
npm view @modelcontextprotocol/server-github version
```

Report the results. If any fail, warn that they may still work at runtime via npx.

## Step 8: Clean up

1. Remove the temporary clone: `rm -rf "$TMPDIR"`
2. Delete this instruction file from the project: `rm install.md`

## Step 9: Report and offer /meditate

Tell the user:

> **Onboarding complete.** Installed:
> - 4 agents: frontend, backend, pathfinder, qa (all Opus)
> - 3 hooks: session-start, memory-inject, post-edit-lint
> - 4 skills: /review, /debug, /deploy, /meditate
> - 4 MCP servers: context7, filesystem, memento, github
>
> Run `/meditate` to let all agents scan the codebase and fill memory. This is recommended after first install.

Then ask: "Would you like me to run /meditate now?"

---

## What gets installed

After onboarding, the project will have:

```
CLAUDE.md              ← coordinator config (the only visible file added)
.mcp.json              ← MCP server config (hidden dotfile)
.claude/
├── agents/
│   ├── frontend.md    ← TypeScript, React, WebGL2, GLSL, canvas, timeline
│   ├── backend.md     ← Node.js, API, FFmpeg, media processing, Docker
│   ├── pathfinder.md  ← Research, docs, libs, architecture, memory
│   └── qa.md          ← E2E tests, performance, security, shader verification
├── hooks/
│   ├── session-start.sh   ← SessionStart: git status, test health, TODOs
│   ├── memory-inject.sh   ← UserPromptSubmit: auto-inject relevant memory
│   └── post-edit-lint.sh  ← PostToolUse: auto-lint after TS edits
├── skills/
│   ├── review/SKILL.md    ← /review: structured code review
│   ├── debug/SKILL.md     ← /debug: systematic debugging protocol
│   ├── deploy/SKILL.md    ← /deploy: deployment checklist with gates
│   └── meditate/SKILL.md  ← /meditate: deep codebase scan + memory fill
├── settings.local.json    ← permissions, hooks, MCP config
└── memory/
    └── MEMORY.md          ← persistent auto-memory
```

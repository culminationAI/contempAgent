# ContempAgent — Onboarding

Read this file completely, then execute steps 1–7 in order. Report progress after each step.

## Step 1: Download

```bash
git clone --depth 1 https://github.com/culminationAI/contempAgent.git /tmp/contempAgent
```

If clone fails — ask user to check internet/GitHub access, stop.

## Step 2: Install agent

Copy agent files into the current project. **Exclude** `scaffold/`, `README.md`, and `mcp.json` from `.claude/` — they are repo-only files.

```bash
rsync -a --exclude='scaffold/' --exclude='README.md' --exclude='mcp.json' /tmp/contempAgent/.claude/ .claude/
cp /tmp/contempAgent/CLAUDE.md ./CLAUDE.md
chmod +x .claude/hooks/*.sh
chmod +x .claude/hooks/*.py 2>/dev/null || true
```

If `.claude/` or `CLAUDE.md` already exist — back them up first (`.claude.bak/`, `CLAUDE.md.bak`).

## Step 3: Generate .mcp.json

Write `.mcp.json` to project root. Replace `__PROJECT_DIR__` with the **absolute path** of the current working directory (`pwd`):

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
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "__PROJECT_DIR__"]
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

If `.mcp.json` already exists — back it up first.

## Step 4: Check dependencies

Check each tool. Report installed vs missing:

| Tool | Check | Install (macOS) |
|------|-------|-----------------|
| Node.js | `node --version` | `brew install node` |
| npm | `npm --version` | (comes with Node) |
| Docker | `docker --version` | `brew install --cask docker` |
| Python 3 | `python3 --version` | `brew install python3` |
| FFmpeg | `ffmpeg -version` | `brew install ffmpeg` |

If anything missing — show the list, offer to install via Homebrew (if available). Let user decide.

## Step 5: Scaffold (optional)

Ask the user:

> The agent includes a project scaffold: package.json, tsconfig, ESLint, Prettier, Vitest, Playwright, Docker, shared TypeScript types. Install it?

If yes:

```bash
for f in package.json tsconfig.json eslint.config.js prettier.config.js vitest.config.ts playwright.config.ts docker-compose.yml; do
  cp "/tmp/contempAgent/.claude/scaffold/$f" "./$f"
done
cp -r /tmp/contempAgent/.claude/scaffold/packages ./packages
npm install
```

Back up any existing files first. If no — skip entirely.

## Step 6: Clean up

```bash
rm -rf /tmp/contempAgent
rm install.md
```

## Step 7: Done

Tell the user:

> Onboarding complete. Installed: 4 agents (frontend, backend, pathfinder, qa), 3 hooks, 4 skills (/review, /debug, /deploy, /meditate), 4 MCP servers.

Ask: **Run /meditate now?** (recommended — scans the codebase and fills agent memory)

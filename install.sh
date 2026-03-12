#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# ContempAgent v0.3 — Standalone Onboarding Installer
# Place this file in your project directory and run it.
# It clones the agent repo, installs files, and cleans up.
# ─────────────────────────────────────────────────────────

REPO_URL="https://github.com/culminationAI/contempAgent.git"
TARGET_DIR="$(pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()   { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
fail()  { echo -e "${RED}✗${NC} $1"; }
info()  { echo -e "${BLUE}→${NC} $1"; }
header(){ echo -e "\n${BOLD}${CYAN}$1${NC}\n"; }

header "ContempAgent v0.3 — Standalone Installer"

# ─── Step 1: Check git (hard dependency for clone) ──────

if ! command -v git &>/dev/null; then
  fail "Git is required to clone the agent repository."
  echo "    Install: brew install git  (or https://git-scm.com)"
  exit 1
fi

# ─── Step 2: Clone agent repo to temp directory ─────────

header "Fetching Agent Repository"

TMPDIR_CLONE="$(mktemp -d)"
cleanup() {
  if [ -d "$TMPDIR_CLONE" ]; then
    rm -rf "$TMPDIR_CLONE"
  fi
}
trap cleanup EXIT

info "Cloning $REPO_URL ..."
if git clone --depth 1 "$REPO_URL" "$TMPDIR_CLONE/contempAgent" 2>&1 | tail -3; then
  log "Repository cloned successfully"
else
  fail "Failed to clone repository. Check your internet connection and access."
  exit 1
fi

AGENT_DIR="$TMPDIR_CLONE/contempAgent"

# ─── Step 3: Validate target directory ──────────────────

info "Target project: ${BOLD}$TARGET_DIR${NC}"

if [ ! -d "$TARGET_DIR" ]; then
  fail "Directory does not exist: $TARGET_DIR"
  exit 1
fi

# ─── Step 4: Check dependencies ─────────────────────────

header "Checking Dependencies"

MISSING=()

check_cmd() {
  local cmd="$1"
  local name="${2:-$1}"
  local install_hint="$3"
  if command -v "$cmd" &>/dev/null; then
    local version
    version=$("$cmd" --version 2>&1 | head -1) || version="installed"
    log "$name — $version"
  else
    fail "$name — not found"
    echo "    Install: $install_hint"
    MISSING+=("$cmd")
  fi
}

check_cmd "node"    "Node.js"    "brew install node  (or https://nodejs.org)"
check_cmd "npm"     "npm"        "comes with Node.js"
check_cmd "npx"     "npx"        "comes with Node.js"
check_cmd "docker"  "Docker"     "brew install --cask docker (or https://docker.com)"
check_cmd "python3" "Python 3"   "brew install python3"

# FFmpeg — check separately (version flag differs)
if command -v ffmpeg &>/dev/null; then
  ffmpeg_ver=$(ffmpeg -version 2>&1 | head -1)
  log "FFmpeg — $ffmpeg_ver"
else
  fail "FFmpeg — not found"
  echo "    Install: brew install ffmpeg"
  MISSING+=("ffmpeg")
fi

# Claude CLI
if command -v claude &>/dev/null; then
  log "Claude CLI — installed"
else
  fail "Claude CLI — not found"
  echo "    Install: npm install -g @anthropic-ai/claude-code"
  MISSING+=("claude")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  warn "${#MISSING[@]} missing dependencies: ${MISSING[*]}"

  # Offer brew install for macOS
  if command -v brew &>/dev/null; then
    echo ""
    read -p "  Install missing dependencies via Homebrew? [y/N] " install_confirm
    if [[ "$install_confirm" =~ ^[Yy]$ ]]; then
      for dep in "${MISSING[@]}"; do
        case "$dep" in
          node|npm|npx) brew install node ;;
          docker)       brew install --cask docker ;;
          python3)      brew install python3 ;;
          ffmpeg)       brew install ffmpeg ;;
          claude)       npm install -g @anthropic-ai/claude-code ;;
        esac
      done
      echo ""
      log "Dependencies installed. Re-run this script to verify."
    fi
  else
    echo ""
    info "Install the missing tools above, then re-run this script."
  fi

  read -p "  Continue anyway? [y/N] " continue_confirm
  [[ "$continue_confirm" =~ ^[Yy]$ ]] || exit 1
fi

# ─── Step 5: Install agent files ────────────────────────

header "Installing Agent Files"

# Copy .claude/ directory (excluding scaffold/ and repo-only files)
if [ -d "$AGENT_DIR/.claude" ]; then
  if [ -d "$TARGET_DIR/.claude" ]; then
    warn ".claude/ already exists in target. Backing up to .claude.bak/"
    rm -rf "$TARGET_DIR/.claude.bak"
    cp -r "$TARGET_DIR/.claude" "$TARGET_DIR/.claude.bak"
  fi

  # Copy .claude/ but exclude scaffold/ and repo-only files
  rsync -a \
    --exclude='scaffold/' \
    --exclude='README.md' \
    --exclude='mcp.json' \
    "$AGENT_DIR/.claude/" "$TARGET_DIR/.claude/"
  log "Copied .claude/ (agents, hooks, skills, memory, settings)"
else
  fail "No .claude/ directory found in cloned repo"
  echo "    The repository appears incomplete."
  exit 1
fi

# Copy CLAUDE.md
if [ -f "$AGENT_DIR/CLAUDE.md" ]; then
  if [ -f "$TARGET_DIR/CLAUDE.md" ]; then
    warn "CLAUDE.md already exists. Backing up to CLAUDE.md.bak"
    cp "$TARGET_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md.bak"
  fi
  cp "$AGENT_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
  log "Copied CLAUDE.md (coordinator config)"
else
  warn "No CLAUDE.md found in cloned repo — skipping"
fi

# Generate .mcp.json with correct filesystem path
if [ -f "$TARGET_DIR/.mcp.json" ]; then
  warn ".mcp.json already exists. Backing up to .mcp.json.bak"
  cp "$TARGET_DIR/.mcp.json" "$TARGET_DIR/.mcp.json.bak"
fi

cat > "$TARGET_DIR/.mcp.json" <<EOF
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
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "$TARGET_DIR"]
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
EOF
log "Generated .mcp.json (filesystem path: $TARGET_DIR)"

# Make hooks executable
if ls "$TARGET_DIR/.claude/hooks/"*.sh &>/dev/null 2>&1; then
  chmod +x "$TARGET_DIR/.claude/hooks/"*.sh
  log "Made hook shell scripts executable"
fi
if ls "$TARGET_DIR/.claude/hooks/"*.py &>/dev/null 2>&1; then
  chmod +x "$TARGET_DIR/.claude/hooks/"*.py
  log "Made hook Python scripts executable"
fi

# ─── Step 6: Scaffold (optional) ─────────────────────────

header "Project Scaffold"

echo "The agent includes a project scaffold with:"
echo "  . package.json — monorepo with TypeScript, ESLint, Prettier, Vitest"
echo "  . tsconfig.json — strict TypeScript config"
echo "  . eslint.config.js — strict ESLint rules (no 'any' allowed)"
echo "  . prettier.config.js — code formatting"
echo "  . vitest.config.ts — unit test config (80% coverage thresholds)"
echo "  . playwright.config.ts — E2E test config (Chrome, Firefox, Safari)"
echo "  . docker-compose.yml — app + FFmpeg + MinIO"
echo "  . packages/shared/ — shared TypeScript types"
echo ""

read -p "Install project scaffold (package.json, TypeScript, ESLint, Prettier, Vitest, Playwright, Docker)? [y/N] " scaffold_confirm
if [[ "$scaffold_confirm" =~ ^[Yy]$ ]]; then
  SCAFFOLD_DIR="$AGENT_DIR/.claude/scaffold"

  if [ -d "$SCAFFOLD_DIR" ]; then
    # Copy scaffold files to target root
    for f in package.json tsconfig.json eslint.config.js prettier.config.js vitest.config.ts playwright.config.ts docker-compose.yml; do
      if [ -f "$SCAFFOLD_DIR/$f" ]; then
        if [ -f "$TARGET_DIR/$f" ]; then
          warn "$f already exists — backing up to $f.bak"
          cp "$TARGET_DIR/$f" "$TARGET_DIR/$f.bak"
        fi
        cp "$SCAFFOLD_DIR/$f" "$TARGET_DIR/$f"
      fi
    done

    # Copy packages/ directory
    if [ -d "$SCAFFOLD_DIR/packages" ]; then
      if [ -d "$TARGET_DIR/packages" ]; then
        warn "packages/ already exists — backing up to packages.bak/"
        rm -rf "$TARGET_DIR/packages.bak"
        cp -r "$TARGET_DIR/packages" "$TARGET_DIR/packages.bak"
      fi
      cp -r "$SCAFFOLD_DIR/packages" "$TARGET_DIR/packages"
    fi

    log "Scaffold installed"

    # Install npm dependencies
    if [ -f "$TARGET_DIR/package.json" ]; then
      info "Installing npm dependencies..."
      (cd "$TARGET_DIR" && npm install 2>&1 | tail -5)
      log "npm install complete"
    fi
  else
    warn "Scaffold directory not found in repo — skipping"
  fi
else
  info "Skipping scaffold. You can set up your own project structure."
fi

# ─── Step 7: Verify MCP servers ─────────────────────────

header "Verifying MCP Servers"

verify_mcp() {
  local name="$1"
  local pkg="$2"
  if npm view "$pkg" version &>/dev/null 2>&1; then
    local ver
    ver=$(npm view "$pkg" version 2>/dev/null)
    log "$name — $pkg@$ver available"
  else
    warn "$name — could not verify $pkg (may work at runtime)"
  fi
}

verify_mcp "context7"   "@upstash/context7-mcp"
verify_mcp "filesystem" "@modelcontextprotocol/server-filesystem"
verify_mcp "memento"    "@modelcontextprotocol/server-memory"
verify_mcp "github"     "@modelcontextprotocol/server-github"

# ─── Step 8: Self-delete installer ───────────────────────

rm -f "$TARGET_DIR/install.sh"
log "Removed install.sh (no longer needed)"

# ─── Step 9: Summary & next steps ───────────────────────

header "Installation Complete"

echo -e "${BOLD}Installed:${NC}"
echo "  . 4 agents:  frontend, backend, pathfinder, qa (all Opus)"
echo "  . 3 hooks:   session-start, memory-inject, post-edit-lint"
echo "  . 4 skills:  /review, /debug, /deploy, /meditate"
echo "  . 4 MCP:     context7, filesystem, memento, github"
echo ""

echo -e "${BOLD}Next steps:${NC}"
echo "  1. cd $TARGET_DIR"
echo "  2. claude                    # Start Claude Code"
echo "  3. /meditate                 # Deep scan: all agents analyze your codebase"
echo ""

# Offer to start Claude Code
read -p "Launch Claude Code now and run /meditate? [Y/n] " meditate_confirm
if [[ ! "$meditate_confirm" =~ ^[Nn]$ ]]; then
  cd "$TARGET_DIR"
  echo ""
  info "Starting Claude Code..."
  info "Once loaded, type: /meditate"
  echo ""
  exec claude
fi

echo ""
log "Done. Happy building!"

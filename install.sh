#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────
# ContempAgent v0.2 — Onboarding Installer
# Installs the AI development agent into your project
# ─────────────────────────────────────────────────────────

AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

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

header "ContempAgent v0.2 — Onboarding Installer"

# ─── Step 1: Validate target directory ────────────────────

info "Target project: ${BOLD}$TARGET_DIR${NC}"

if [ "$AGENT_DIR" = "$TARGET_DIR" ]; then
  warn "You're running install.sh from inside the agent directory."
  echo "  Usage: ./install.sh /path/to/your/project"
  echo "  Or:    cd /path/to/your/project && /path/to/contempAgent/install.sh"
  echo ""
  read -p "Continue installing into this directory? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
fi

if [ ! -d "$TARGET_DIR" ]; then
  fail "Directory does not exist: $TARGET_DIR"
  exit 1
fi

# Validate it looks like a project directory
if [ ! -f "$TARGET_DIR/package.json" ] && [ ! -d "$TARGET_DIR/src" ]; then
  warn "No package.json or src/ found in $TARGET_DIR"
  echo "  This doesn't look like a project directory."
  read -p "  Continue anyway? [y/N] " project_confirm
  [[ "$project_confirm" =~ ^[Yy]$ ]] || exit 1
fi

# ─── Step 2: Check dependencies ──────────────────────────

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
check_cmd "git"     "Git"        "brew install git   (or https://git-scm.com)"
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
          git)          brew install git ;;
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

# ─── Step 3: Install agent files ─────────────────────────

header "Installing Agent Files"

# Copy .claude/ directory
if [ -d "$AGENT_DIR/.claude" ]; then
  if [ -d "$TARGET_DIR/.claude" ]; then
    warn ".claude/ already exists in target. Backing up to .claude.bak/"
    rm -rf "$TARGET_DIR/.claude.bak"
    cp -r "$TARGET_DIR/.claude" "$TARGET_DIR/.claude.bak"
  fi

  cp -r "$AGENT_DIR/.claude" "$TARGET_DIR/.claude"
  log "Copied .claude/ (agents, hooks, skills, memory, settings)"
else
  fail "No .claude/ directory found in $AGENT_DIR"
  echo "    The agent source directory appears incomplete."
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
  warn "No CLAUDE.md found in $AGENT_DIR — skipping"
fi

# Copy .mcp.json and update filesystem path
if [ -f "$AGENT_DIR/.mcp.json" ]; then
  if [ -f "$TARGET_DIR/.mcp.json" ]; then
    warn ".mcp.json already exists. Backing up to .mcp.json.bak"
    cp "$TARGET_DIR/.mcp.json" "$TARGET_DIR/.mcp.json.bak"
  fi

  # Update the filesystem server path to point to target directory
  sed "s|$AGENT_DIR|$TARGET_DIR|g" "$AGENT_DIR/.mcp.json" > "$TARGET_DIR/.mcp.json"
  log "Copied .mcp.json (MCP servers — filesystem path updated)"
else
  warn "No .mcp.json found in $AGENT_DIR — skipping"
fi

# Make hooks executable
if ls "$TARGET_DIR/.claude/hooks/"*.sh &>/dev/null 2>&1; then
  chmod +x "$TARGET_DIR/.claude/hooks/"*.sh
  log "Made hook scripts executable"
fi
if ls "$TARGET_DIR/.claude/hooks/"*.py &>/dev/null 2>&1; then
  chmod +x "$TARGET_DIR/.claude/hooks/"*.py
  log "Made hook Python scripts executable"
fi

# ─── Step 4: Install project dependencies ─────────────────

header "Project Setup"

if [ -f "$TARGET_DIR/package.json" ]; then
  info "Found package.json — installing dependencies..."
  (cd "$TARGET_DIR" && npm install 2>&1 | tail -5)
  log "npm install complete"
else
  warn "No package.json found. Skipping npm install."
  echo "    Run 'npm init' when ready to set up your project."
fi

# ─── Step 5: Verify MCP servers ──────────────────────────

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

# ─── Step 6: Summary & next steps ────────────────────────

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

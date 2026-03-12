#!/bin/bash
# SessionStart hook — project status context injection
# Runs at session start, provides git state + test health + TODOs

set -euo pipefail
cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0

context=""

# Git status
if git rev-parse --is-inside-work-tree &>/dev/null; then
  branch=$(git branch --show-current 2>/dev/null || echo "detached")
  status=$(git status --short 2>/dev/null | head -20)
  recent=$(git log --oneline -5 2>/dev/null || echo "no commits")
  context+="Branch: $branch\n"
  [ -n "$status" ] && context+="Changes:\n$status\n" || context+="Working tree clean.\n"
  context+="Recent commits:\n$recent\n"
fi

# TODOs in source
search_dirs=()
[ -d "src" ] && search_dirs+=("src/")
[ -d "apps" ] && search_dirs+=("apps/")
[ -d "packages" ] && search_dirs+=("packages/")
if [ ${#search_dirs[@]} -gt 0 ]; then
  todos=$(grep -rn "TODO\|FIXME\|HACK" "${search_dirs[@]}" --include="*.ts" --include="*.tsx" --include="*.glsl" 2>/dev/null | head -10) || true
  [ -n "$todos" ] && context+="\nOpen TODOs:\n$todos\n"
fi

# Test health (quick check, 30s timeout)
if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
  test_result=$(timeout 30 npx vitest run --reporter=dot 2>&1 | tail -3) || test_result="Tests not configured or failed to run"
  context+="\nTest status:\n$test_result\n"
fi

# Output as hook JSON
if [ -n "$context" ]; then
  json_context=$(echo -e "$context" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || echo "\"$context\"")
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":$json_context}}"
fi

exit 0

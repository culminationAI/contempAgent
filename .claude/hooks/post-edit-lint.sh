#!/bin/bash
# PostToolUse hook — auto-lint after file edits
# Matcher: Write|Edit — runs when TypeScript/TSX files are modified

set -euo pipefail
cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0

# Parse input to get the edited file path
input=$(cat)
file_path=$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

[ -z "$file_path" ] && exit 0

# Only lint TypeScript files
case "$file_path" in
  *.ts|*.tsx)
    if command -v npx &>/dev/null && [ -f "node_modules/.bin/eslint" ]; then
      lint_output=$(npx eslint --fix "$file_path" 2>&1) || true
      errors=$(echo "$lint_output" | grep -c "error" 2>/dev/null || echo "0")
      if [ "$errors" -gt 0 ]; then
        json_msg=$(echo "$lint_output" | head -10 | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null)
        echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\"Lint warnings in $file_path:\\n\"$json_msg\"}}"
      fi
    fi
    ;;
esac

exit 0

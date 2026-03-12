#!/bin/bash
# UserPromptSubmit hook — auto-inject memory context before thinking
# Reads user message, searches project memory files for relevant context.
# Since hooks cannot call MCP tools directly, this greps local .md files
# as a lightweight stand-in for memento knowledge graph queries.

set -euo pipefail
cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0

# Read hook input from stdin
input=$(cat)

# Extract user message using python3 for reliable JSON parsing.
# Claude Code hook payload uses "prompt" field.
user_message=$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    msg = data.get('prompt', '') or data.get('user_message', '') or data.get('message', '') or ''
    print(msg[:500])
except Exception:
    print('')
" 2>/dev/null)

[ -z "$user_message" ] && exit 0

# Extract key terms: remove stop words, keep meaningful words + identifiers.
# All processing in a single python3 invocation to avoid double-read issues.
terms=$(echo "$user_message" | python3 -c "
import sys, re

msg = sys.stdin.read()
msg_lower = msg.lower()

# Common stop words (English)
stops = {
    'the','a','an','is','are','was','were','be','been','being','have','has','had',
    'do','does','did','will','would','could','should','may','might','can','shall',
    'i','me','my','we','our','you','your','he','she','it','they','them','this','that',
    'what','how','why','when','where','which','who','and','or','but','not','no','if',
    'to','for','with','from','in','on','at','by','of','up','out','into','about',
    'make','use','add','get','set','run','fix','need','want','like','please','just',
    'let','also','all','some','any','new','now','here','there','then','than','very',
    'only','more','most','much','many','each','every','other','such','own','same'
}

# Extract words (lowercased, min 3 chars, not stop words)
words = re.findall(r'[a-zA-Z]{3,}', msg_lower)
meaningful = [w for w in words if w not in stops]

# Extract identifiers: CamelCase, snake_case, kebab-case, UPPER_CASE
identifiers = re.findall(r'[A-Z][a-z]+(?:[A-Z][a-z]+)+|[a-z]+(?:_[a-z]+)+|[a-z]+(?:-[a-z]+)+|[A-Z_]{3,}', msg)
ident_lower = [i.lower() for i in identifiers]

# Deduplicate, preserving order, max 12 terms
seen = set()
all_terms = []
for t in meaningful + ident_lower:
    if t not in seen:
        seen.add(t)
        all_terms.append(t)
    if len(all_terms) >= 12:
        break

print(' '.join(all_terms))
" 2>/dev/null)

[ -z "$terms" ] && exit 0

# Collect context from project memory files.
# Use python3 for all aggregation to avoid shell quoting issues.
context=$(python3 -c "
import os, sys, re, json

project_dir = os.environ.get('CLAUDE_PROJECT_DIR', '.')
terms = sys.argv[1].split()
results = []
seen_lines = set()

def search_file(filepath, label, max_matches=3):
    \"\"\"Search a file for terms, return matching lines with context.\"\"\"
    if not os.path.isfile(filepath):
        return
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
    except Exception:
        return

    for term in terms:
        pattern = re.compile(re.escape(term), re.IGNORECASE)
        matches_found = 0
        for i, line in enumerate(lines):
            if pattern.search(line):
                stripped = line.strip()
                if not stripped or stripped in seen_lines:
                    continue
                seen_lines.add(stripped)
                # Include surrounding heading for context
                heading = ''
                for j in range(i, -1, -1):
                    if lines[j].startswith('#'):
                        heading = lines[j].strip().lstrip('#').strip()
                        break
                prefix = f'[{label}' + (f'/{heading}' if heading else '') + f'] '
                results.append(prefix + stripped[:180])
                matches_found += 1
                if matches_found >= max_matches:
                    break

# 1. Search MEMORY.md (primary memory file)
memory_paths = [
    os.path.join(project_dir, '.claude', 'memory', 'MEMORY.md'),
    os.path.join(project_dir, 'MEMORY.md'),
]
for mp in memory_paths:
    search_file(mp, 'MEM')

# 2. Search architecture doc (created by /meditate or manual)
arch_paths = [
    os.path.join(project_dir, 'docs', 'architecture.md'),
    os.path.join(project_dir, '.claude', 'docs', 'architecture.md'),
]
for ap in arch_paths:
    search_file(ap, 'ARCH')

# 3. Search all .md files in docs/ directory (shallow + one level deep)
docs_dir = os.path.join(project_dir, 'docs')
if os.path.isdir(docs_dir):
    md_files = []
    for root, dirs, files in os.walk(docs_dir):
        # Limit depth to 2 levels to avoid scanning too deep
        depth = root.replace(docs_dir, '').count(os.sep)
        if depth > 1:
            continue
        for f in files:
            if f.endswith('.md'):
                md_files.append(os.path.join(root, f))
    # Cap number of files to search (performance guard)
    for md_file in md_files[:20]:
        label = os.path.basename(md_file).replace('.md', '').upper()[:10]
        search_file(md_file, label)

# 4. Also check CLAUDE.md for architectural references
claude_md = os.path.join(project_dir, 'CLAUDE.md')
search_file(claude_md, 'PROJ', max_matches=2)

# Deduplicate and trim to budget (~2000 chars, ~500 tokens)
if not results:
    sys.exit(0)

output = '\n'.join(results[:25])
if len(output) > 2000:
    output = output[:2000] + '...'

print(output)
" "$terms" 2>/dev/null)

# Only output if we found relevant context
if [ -n "$context" ]; then
    # Build valid JSON output using python3 for safe escaping
    echo "$context" | python3 -c "
import sys, json
ctx = sys.stdin.read().strip()
if ctx:
    output = {
        'hookSpecificOutput': {
            'hookEventName': 'UserPromptSubmit',
            'additionalContext': 'Memory context (auto-retrieved):\n' + ctx
        }
    }
    print(json.dumps(output))
" 2>/dev/null
fi

exit 0

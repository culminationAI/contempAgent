---
name: review
description: "Code review — structured quality check against project standards"
user-invocable: true
argument-hint: "<file-path|PR-number>"
---

# /review

Structured code review against ContempAgent code standards.

## Mode Detection

Parse `$ARGUMENTS`:
- If number → PR review via `gh pr diff $number`
- If file path → single file review
- If empty → review all staged changes (`git diff --cached`)

## Protocol

### 1. Gather
- Read the target code (file, PR diff, or staged changes)
- Identify which agent domain it belongs to (frontend/backend/shared)

### 2. Check Standards
Run through this checklist for every changed file:

**TypeScript**:
- [ ] `strict: true` compliance — no `any`, no unsafe casts
- [ ] Explicit return types on exported functions
- [ ] No implicit `undefined` returns
- [ ] Discriminated unions over type assertions

**React** (if applicable):
- [ ] Functional components only, proper hook usage
- [ ] useMemo/useCallback where needed (render-heavy components)
- [ ] Error boundaries for async operations
- [ ] Proper cleanup in useEffect

**WebGL/GLSL** (if applicable):
- [ ] Resources cleaned up on unmount (buffers, textures, programs, FBOs)
- [ ] Shader compiles without warnings
- [ ] No hardcoded precision — use appropriate qualifiers
- [ ] Texture units properly managed

**Backend** (if applicable):
- [ ] Input validated with zod schemas
- [ ] FFmpeg commands use array args (no shell interpolation)
- [ ] Streams for media processing (no full-file memory loads)
- [ ] Proper HTTP status codes and error types

**Security**:
- [ ] No secrets in code
- [ ] External input validated before use
- [ ] No eval, no dynamic requires
- [ ] Parameterized queries/commands

**Testing**:
- [ ] New logic has unit tests
- [ ] New user flows have E2E tests
- [ ] Test names describe behavior, not implementation

### 3. Output

Write review summary:
- **Pass** / **Needs Changes** verdict
- List of issues (file:line — description — severity)
- Suggestions for improvement (optional, non-blocking)

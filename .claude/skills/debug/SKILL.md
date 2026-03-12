---
name: debug
description: "Structured debugging — reproduce, isolate, fix, verify"
user-invocable: true
argument-hint: "<error-description|stack-trace>"
---

# /debug

Structured debugging protocol. Systematic root cause analysis.

## Mode Detection

Parse `$ARGUMENTS`:
- If stack trace detected → start from Isolate (stack trace gives location)
- If error description → start from Reproduce
- If empty → ask user to describe the bug

## Protocol

### 1. Context
- Search memento for similar past bugs (`bug:*` entities)
- Read recent git log for potentially related changes
- Check test status — is anything already failing?

### 2. Reproduce
- Identify minimal reproduction steps
- Confirm the bug is reproducible (not environment-specific)
- Document: expected behavior vs actual behavior

### 3. Isolate
- Trace from error location through call stack
- Identify the exact line/function where behavior diverges
- Binary search if needed: comment out sections to narrow scope

### 4. Root Cause
- Identify WHY the bug exists, not just WHERE
- Categories: logic error, race condition, type mismatch, missing validation, state corruption, API contract violation, browser incompatibility

### 5. Fix
- Delegate to appropriate agent (frontend/backend) for implementation
- Fix must address root cause, not symptoms
- No bandaid fixes unless explicitly temporary (mark with `// FIXME:`)

### 6. Verify
- Delegate to QA agent:
  - Run existing tests — confirm nothing broke
  - Write regression test for this specific bug
  - If shader/WebGL bug: test across browsers

### 7. Record
- Store in memento as `bug:<short-id>` entity with:
  - Symptom, root cause, fix applied, regression test location
  - Relations: `AFFECTS` component, `FIXED_BY` commit

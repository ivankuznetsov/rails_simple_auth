# Improve Error Handling in bin/test_generator

---
status: pending
priority: p2
issue_id: "003"
tags: [code-review, bash, ci]
dependencies: []
---

## Problem Statement

The `bin/test_generator` script uses `set -e` but has `2>/dev/null || true` patterns that silently ignore failures:

```bash
cp "$GEM_DIR/test/generator_test_files/pages/"*.rb test/support/pages/ 2>/dev/null || true
cp "$GEM_DIR/test/generator_test_files/system/"*.rb test/system/ 2>/dev/null || true
npx playwright install chromium 2>/dev/null || echo "Playwright browser installation skipped"
```

If these files don't exist, tests will fail later with confusing errors.

## Findings

### From Kieran Rails Reviewer
- If page objects fail to copy, system tests will error with "uninitialized constant"
- If Playwright fails to install, browser tests will fail mysteriously

## Proposed Solutions

### Option A: Add Explicit Checks (Recommended)
```bash
if [ ! -d "$GEM_DIR/test/generator_test_files/pages" ]; then
  echo "ERROR: Page object templates not found at $GEM_DIR/test/generator_test_files/pages"
  exit 1
fi
```

- **Pros**: Fail fast with clear error messages
- **Cons**: More verbose
- **Effort**: Small
- **Risk**: None

### Option B: Remove `|| true` Patterns
Let failures surface immediately via `set -e`.

- **Pros**: Simplest change
- **Cons**: Error messages less clear
- **Effort**: Minimal
- **Risk**: Low

## Recommended Action

Remove `|| true` patterns and let the script fail naturally. Optionally add explicit directory checks.

## Technical Details

**Affected Files:**
- `bin/test_generator:178-181, 218`

## Acceptance Criteria

- [ ] Remove silent error suppression
- [ ] Script fails clearly when templates missing
- [ ] Test generator still works in normal case

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-20 | Created from code review | Silent failures hide real issues |

## Resources

- PR #3: https://github.com/ivankuznetsov/rails_simple_auth/pull/3

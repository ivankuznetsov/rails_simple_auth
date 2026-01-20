# Add Playwright Browser Cache to CI

---
status: pending
priority: p3
issue_id: "007"
tags: [code-review, ci, performance]
dependencies: []
---

## Problem Statement

The `generator-test` job downloads Playwright browsers (~200MB) on every CI run, adding 60-90 seconds to build time.

## Findings

### From Performance Oracle
- `npx playwright install --with-deps chromium` takes 60-90 seconds
- Browser downloads could be cached between runs

### From Architecture Strategist
- Caching would speed up CI runs significantly

## Proposed Solutions

### Option A: Add Browser Caching (Recommended)
```yaml
- name: Cache Playwright browsers
  uses: actions/cache@v4
  with:
    path: ~/.cache/ms-playwright
    key: playwright-chromium-${{ runner.os }}

- name: Install Playwright
  run: npx playwright install --with-deps chromium
```

- **Pros**: Saves 60-90s per run
- **Cons**: Cache invalidation complexity
- **Effort**: Small
- **Risk**: Low

## Recommended Action

Add Playwright browser caching to CI workflow.

## Technical Details

**Affected Files:**
- `.github/workflows/ci.yml`

## Acceptance Criteria

- [ ] Add cache action for Playwright browsers
- [ ] Verify cache hits on subsequent runs
- [ ] Measure time savings

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-20 | Created from code review | CI optimization opportunity |

## Resources

- PR #3: https://github.com/ivankuznetsov/rails_simple_auth/pull/3

# Add CI Artifacts on Failure

---
status: pending
priority: p2
issue_id: "004"
tags: [code-review, ci, debugging]
dependencies: []
---

## Problem Statement

The `generator-test` job in CI doesn't collect screenshots or logs on failure. When E2E tests fail in CI, there's no visibility into what happened.

## Findings

### From Kieran Rails Reviewer
- When E2E tests fail in CI, you'll have no visibility into what happened
- Screenshots and logs are essential for debugging remote failures

## Proposed Solutions

### Option A: Add Artifact Upload (Recommended)
```yaml
- name: Upload test artifacts on failure
  if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: generator-test-artifacts
    path: |
      /tmp/rails_simple_auth_test_app/tmp/screenshots/
      /tmp/rails_simple_auth_test_app/log/test.log
```

- **Pros**: Essential for debugging CI failures
- **Cons**: Slightly longer CI on failures
- **Effort**: Small
- **Risk**: None

## Recommended Action

Add artifact upload step to CI workflow.

## Technical Details

**Affected Files:**
- `.github/workflows/ci.yml`

## Acceptance Criteria

- [ ] Add artifact upload on failure
- [ ] Verify screenshots captured by Playwright
- [ ] Verify test logs included

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-20 | Created from code review | CI observability is critical |

## Resources

- PR #3: https://github.com/ivankuznetsov/rails_simple_auth/pull/3

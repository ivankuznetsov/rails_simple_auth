# Verify Session Model Lambda Removal

---
status: pending
priority: p1
issue_id: "001"
tags: [code-review, rails, architecture, security]
dependencies: []
---

## Problem Statement

The Session model's `belongs_to :user` association was changed from using a lambda for deferred class resolution to direct evaluation:

**Before:**
```ruby
belongs_to :user, class_name: -> { RailsSimpleAuth.configuration.user_class_name }
```

**After:**
```ruby
belongs_to :user, class_name: RailsSimpleAuth.configuration.user_class_name
```

This changes when `user_class_name` is evaluated - from runtime (on each association access) to load time (when the model is first accessed).

## Findings

### From Security Sentinel
- Risk Level: MEDIUM
- The lambda was intentionally used to defer class resolution until runtime
- If configuration isn't fully initialized when Session loads, this could cause errors

### From Kieran Rails Reviewer
- Marked as CRITICAL
- Could break autoloading in development mode
- Original lambda pattern was intentional for deferred class resolution

### From Architecture Strategist
- Moving to `app/models/` with Rails engine autoloading may eliminate the need for deferred resolution
- The change aligns with how other Rails engines (Devise, ActiveStorage) work

### From DHH Reviewer
- The removal is correct - Rails engines with `app/models/` get proper autoloading
- This is a legitimate bug fix

## Proposed Solutions

### Option A: Keep Current Change (Verify Works)
- **Pros**: Cleaner code, follows Rails engine conventions
- **Cons**: May have edge cases in initialization order
- **Effort**: Small - just needs verification testing
- **Risk**: Low if tests pass

### Option B: Restore Lambda
- **Pros**: Preserves original behavior, safe fallback
- **Cons**: May be unnecessary with new file location
- **Effort**: Small
- **Risk**: None

### Option C: Add Test Coverage for Edge Cases
- **Pros**: Validates behavior works correctly
- **Cons**: More test code
- **Effort**: Medium
- **Risk**: None

## Recommended Action

Test with various configuration timing scenarios:
1. Configure custom user class name AFTER model loads
2. Configure in initializer (normal case)
3. Test in development with code reloading

If all tests pass, the current change is acceptable.

## Technical Details

**Affected Files:**
- `app/models/rails_simple_auth/session.rb:7`

**Components:**
- Session model
- User association
- Configuration system

## Acceptance Criteria

- [ ] Verify existing gem tests pass (135 tests)
- [ ] Test custom user_class_name configuration
- [ ] Test development mode reloading
- [ ] Confirm no initialization order issues

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-20 | Created from code review | Multiple reviewers flagged this - needs verification |

## Resources

- PR #3: https://github.com/ivankuznetsov/rails_simple_auth/pull/3
- File: app/models/rails_simple_auth/session.rb

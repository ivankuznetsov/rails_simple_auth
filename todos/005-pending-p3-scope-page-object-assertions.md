# Scope Page Object Assertions to Elements

---
status: pending
priority: p3
issue_id: "005"
tags: [code-review, testing, quality]
dependencies: []
---

## Problem Statement

Page Object predicates use loose text matching that could match unrelated content:

```ruby
def has_unconfirmed_error?
  has_text?('confirm') || has_text?('Confirm')
end

def has_password_too_short_error?
  has_text?('at least') || has_text?('must be at least')
end
```

These match ANY text on the page containing these substrings.

## Findings

### From Kieran Rails Reviewer
- If the page has unrelated content with "at least", this passes incorrectly
- Should scope to error elements

### From Code Simplicity Reviewer
- Multiple `||` fallbacks suggest uncertainty about the implementation
- Message format is known and consistent

## Proposed Solutions

### Option A: Scope to Error Elements (Recommended)
```ruby
def has_password_too_short_error?
  has_selector?('.rsa-error, .field_with_errors', text: /at least/i, wait: 5)
end
```

- **Pros**: More precise matching
- **Cons**: Requires knowing CSS classes
- **Effort**: Small
- **Risk**: Low

### Option B: Match Exact Messages
Use the exact error message text from the gem's implementation.

- **Pros**: Very precise
- **Cons**: Brittle if messages change
- **Effort**: Small
- **Risk**: Low

## Recommended Action

Scope assertions to error-related CSS selectors.

## Technical Details

**Affected Files:**
- `test/generator_test_files/pages/sign_in_page.rb`
- `test/generator_test_files/pages/sign_up_page.rb`
- `test/generator_test_files/pages/magic_link_page.rb`
- `test/generator_test_files/pages/password_reset_page.rb`

## Acceptance Criteria

- [ ] Update predicates to use scoped selectors
- [ ] Tests still pass
- [ ] No false positives from unrelated text

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-20 | Created from code review | Precise selectors prevent flaky tests |

## Resources

- PR #3: https://github.com/ivankuznetsov/rails_simple_auth/pull/3

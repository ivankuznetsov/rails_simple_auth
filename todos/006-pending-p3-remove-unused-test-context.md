# Remove Unused test_context from Page Objects

---
status: pending
priority: p3
issue_id: "006"
tags: [code-review, testing, cleanup, yagni]
dependencies: []
---

## Problem Statement

Every Page Object stores `test_context` but none actually use it:

```ruby
class BasePage
  def initialize(test_context)
    @test_context = test_context
  end

  private
  attr_reader :test_context
end
```

The `test_context` is passed to every page constructor but never referenced in any page method.

## Findings

### From Kieran Rails Reviewer
- test_context is stored but never used in any page object
- If intended for future use, add a comment; otherwise, remove it

### From Code Simplicity Reviewer
- YAGNI violation - passed everywhere, used nowhere
- Likely intent: Anticipated needing test context for assertions
- Reality: Capybara::DSL provides everything needed

## Proposed Solutions

### Option A: Remove Entirely (Recommended)
```ruby
class BasePage
  include Capybara::DSL
  include Capybara::Minitest::Assertions
end
```

- **Pros**: Cleaner, follows YAGNI
- **Cons**: None
- **Effort**: Small
- **Risk**: None

### Option B: Keep and Document
Add comment explaining intended future use.

- **Pros**: Preserves flexibility
- **Cons**: Keeps dead code
- **Effort**: Minimal
- **Risk**: None

## Recommended Action

Remove `test_context` from BasePage and all page constructors.

## Technical Details

**Affected Files:**
- `test/generator_test_files/pages/base_page.rb`
- All 8 page object files (constructor changes)
- All 4 system test files (setup methods)

## Acceptance Criteria

- [ ] Remove test_context from BasePage
- [ ] Update page constructors
- [ ] Update test setup methods
- [ ] Tests still pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-01-20 | Created from code review | YAGNI - remove unused code |

## Resources

- PR #3: https://github.com/ivankuznetsov/rails_simple_auth/pull/3
